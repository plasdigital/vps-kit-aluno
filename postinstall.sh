#!/usr/bin/env bash
#
# Padrão de VPS — script de pós-instalação
# v1.1 — 11/ago/2026
#
# Roda UMA vez, sozinho, na primeira inicialização da VPS (recurso "post-install
# script" da Hostinger). Entrega a máquina pronta até a camada de runtime:
# sistema afinado, SSH fechado, Docker e Swarm de pé.
#
# O que ele NÃO faz de propósito: firewall (é gerenciado na borda, pelo painel
# da Hostinger) e as aplicações (Traefik/Portainer sobem depois, versionadas em
# stacks/). Desenho e justificativas: docs/por-que-este-padrao.md
#
# Reaproveitável em qualquer VPS: não há nada específico de um cliente aqui dentro.

set -uo pipefail

LOG=/var/log/postinstall.log
exec >>"$LOG" 2>&1

REDE_INTERNA="${REDE_INTERNA:-<TROQUE_PELO_SEU_REDE_INTERNA>}"
SWAP_GB="${SWAP_GB:-4}"
TIMEZONE="${TIMEZONE:-America/Sao_Paulo}"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a          # impede o needrestart de abrir prompt no Ubuntu 24.04

passo() { echo ""; echo "=== $* — $(date -Is) ==="; }

echo "############ Padrão de VPS v1.1 — início $(date -Is) ############"

# ─── 1/7 · sistema base ──────────────────────────────────────────────────────
# NÃO fazemos `apt-get upgrade` completo aqui, e isso é de propósito.
#
# Descoberto na primeira instalação (11/ago/2026): o upgrade atualiza o systemd,
# o systemd reinicia o ssh, e o script morre junto — no meio do dpkg, deixando
# pacotes desconfigurados. O sintoma é uma VPS que parece pronta e não é.
#
# Quem cuida de atualização aqui é o unattended-upgrades (passo 5/7), que roda
# depois, sozinho, e só pega correção de segurança. O upgrade completo é tarefa
# de manutenção, com reboot planejado — não de provisionamento.
passo "1/7 sistema base"
timedatectl set-timezone "$TIMEZONE" || true
apt-get update -y
apt-get install -y ca-certificates curl gnupg jq git htop \
                   fail2ban unattended-upgrades apt-listchanges chrony

# ─── 2/7 · swap ──────────────────────────────────────────────────────────────
# A KVM 2 vem sem swap. Sem ela, um pico de memória faz o kernel matar um
# container em vez de degradar a performance.
passo "2/7 swap de ${SWAP_GB}G"
if swapon --show | grep -q .; then
    echo "[skip] já existe swap ativa"
else
    fallocate -l "${SWAP_GB}G" /swapfile \
        || dd if=/dev/zero of=/swapfile bs=1M count=$((SWAP_GB * 1024))
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
    printf 'vm.swappiness=10\nvm.vfs_cache_pressure=50\n' >/etc/sysctl.d/99-swap.conf
    sysctl --system >/dev/null
    echo "[ok] swap ativa"
fi

# ─── 3/7 · SSH só por chave ──────────────────────────────────────────────────
# Trava de segurança: só desabilita a senha se houver chave instalada. Sem essa
# checagem, uma VPS provisionada sem chave ficaria inacessível para sempre.
#
# O prefixo 01- é obrigatório, não estético: o sshd usa o PRIMEIRO valor que
# encontra para cada diretiva, e os arquivos de sshd_config.d são lidos em ordem
# alfabética. Um 99- perderia para o 50-cloud-init.conf.
passo "3/7 SSH"
if [ -s /root/.ssh/authorized_keys ]; then
    cat >/etc/ssh/sshd_config.d/01-hardening.conf <<'EOF'
# Padrão de VPS — não editar à mão
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
EOF
    # neutraliza diretivas conflitantes deixadas pelo cloud-init
    sed -i -E 's/^[[:space:]]*(PasswordAuthentication|PermitRootLogin)[[:space:]]+yes/# &/I' \
        /etc/ssh/sshd_config.d/*.conf 2>/dev/null || true
    sed -i -E 's/^[[:space:]]*(PasswordAuthentication|PermitRootLogin)[[:space:]]+yes/# &/I' \
        /etc/ssh/sshd_config 2>/dev/null || true

    if sshd -t; then
        systemctl reload ssh || systemctl restart ssh
        echo "[ok] SSH: acesso só por chave"
    else
        rm -f /etc/ssh/sshd_config.d/01-hardening.conf
        echo "[ERRO] sshd_config inválido — hardening revertido, senha mantida"
    fi
else
    echo "[AVISO] /root/.ssh/authorized_keys vazio — senha MANTIDA de propósito."
    echo "        Instale a chave e rode: bash $0"
fi

# ─── 4/7 · fail2ban ──────────────────────────────────────────────────────────
passo "4/7 fail2ban"
cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 3
backend  = systemd

[sshd]
enabled = true
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

# ─── 5/7 · atualização de segurança automática ───────────────────────────────
# Sem reboot automático: derrubar a VPS de um cliente às 6 da manhã sem aviso é
# pior que adiar um kernel. O arquivo /var/run/reboot-required avisa quando
# precisa, e o reboot é feito na manutenção.
passo "5/7 unattended-upgrades"
cat >/etc/apt/apt.conf.d/51-unattended <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades

# ─── 6/7 · Docker CE ─────────────────────────────────────────────────────────
passo "6/7 Docker CE"
if command -v docker >/dev/null 2>&1; then
    echo "[skip] docker já instalado: $(docker --version)"
else
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        >/etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io \
                       docker-buildx-plugin docker-compose-plugin
fi

# Log de container sem teto enche o disco e derruba a VPS inteira. É a causa
# número um de "a VPS parou do nada" em máquina de Docker sem manutenção.
cat >/etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
systemctl enable --now docker
systemctl restart docker
sleep 3

# ─── 7/7 · Swarm + rede overlay ──────────────────────────────────────────────
passo "7/7 Swarm e rede overlay"
IP_PUBLICO=$(ip -4 route get 1.1.1.1 2>/dev/null \
    | awk '{for (i = 1; i <= NF; i++) if ($i == "src") print $(i + 1)}')
echo "IP detectado: ${IP_PUBLICO:-<vazio>}"

if docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "[skip] Swarm já ativo"
else
    docker swarm init --advertise-addr "$IP_PUBLICO"
fi

# --attachable permite que um container avulso entre na rede sem virar serviço:
# vale muito no dia a dia de debug e não custa nada.
if docker network inspect "$REDE_INTERNA" >/dev/null 2>&1; then
    echo "[skip] rede $REDE_INTERNA já existe"
else
    docker network create --driver=overlay --attachable "$REDE_INTERNA"
fi

# Compatibilidade com o instalador do SetupOrion: o menu dele lê estes dois
# campos deste arquivo. Mantido para preservar a saída de emergência — se um dia
# alguém precisar instalar algo pelo menu do Orion, ele funciona.
mkdir -p /root/dados_vps
cat >/root/dados_vps/dados_vps <<EOF
Nome do Servidor: $(hostname)
Rede interna: $REDE_INTERNA
EOF

# ─── selo ────────────────────────────────────────────────────────────────────
cat >/etc/vps-release <<EOF
PADRAO=Padrão de VPS
VERSAO=1.1
APLICADO_EM=$(date -Is)
REDE_INTERNA=$REDE_INTERNA
EOF

echo ""
echo "############ concluído $(date -Is) ############"
docker --version
docker node ls 2>/dev/null
free -h
