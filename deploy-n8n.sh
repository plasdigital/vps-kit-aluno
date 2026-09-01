#!/usr/bin/env bash
#
# Sobe (ou atualiza) o n8n. Roda NA VPS:
#
#   bash /opt/infra/deploy-n8n.sh
#
# Separado do deploy.sh de propósito: aquele é a camada base, igual em toda
# VPS. Este é uma aplicação em cima dela. Assim a base continua reaproveitável
# para a próxima ferramenta que você instalar.
#
# É idempotente: rodar de novo aplica só o que mudou.

set -euo pipefail
cd "$(dirname "$0")"

SEGREDOS=/opt/infra/n8n/n8n.env

if [[ ! -f "$SEGREDOS" ]]; then
  cat >&2 <<FIM
ERRO: $SEGREDOS não existe.

É o arquivo com as senhas (não versionado, chmod 600). Para criar:

  install -d -m 700 /opt/infra/n8n
  umask 077
  cat > $SEGREDOS <<'EOF'
  POSTGRES_PASSWORD=...
  REDIS_PASSWORD=...
  N8N_ENCRYPTION_KEY=...
  EOF

Gerar valores: openssl rand -hex 32 (senhas), openssl rand -hex 16 (encryption key).
Modelo: n8n.env.exemplo. Guarde uma cópia no seu gerenciador de senhas.
FIM
  exit 1
fi

# set -a exporta tudo que os arquivos definirem — é assim que o
# docker stack deploy enxerga as variáveis ${...} usadas no YAML.
set -a
# shellcheck source=/dev/null
source ./vps.env
# shellcheck source=/dev/null
source "$SEGREDOS"
set +a

# Falhar aqui é muito melhor do que subir uma stack com senha vazia e
# descobrir depois, com o banco já inicializado sem senha.
for obrigatoria in POSTGRES_PASSWORD REDIS_PASSWORD N8N_ENCRYPTION_KEY N8N_HOST N8N_WEBHOOK_HOST REDE_INTERNA; do
  if [[ -z "${!obrigatoria:-}" ]]; then
    echo "ERRO: $obrigatoria está vazia (veja vps.env e $SEGREDOS)" >&2
    exit 1
  fi
done

echo "→ editor:   https://$N8N_HOST"
echo "→ webhook:  https://$N8N_WEBHOOK_HOST"
echo "→ versão:   $N8N_VERSAO"
echo "→ rede:     $REDE_INTERNA"
echo

docker stack deploy --prune --resolve-image always -c stacks/n8n.yml n8n

# Backup diário do banco. Instalado aqui para não depender de alguém lembrar:
# a partir do momento em que existe n8n, existe workflow e credencial a perder.
CRON=/etc/cron.d/n8n-backup
if [[ ! -f "$CRON" ]]; then
  printf '45 3 * * * root /opt/infra/backup-n8n.sh >> /var/log/n8n-backup.log 2>&1\n' > "$CRON"
  chmod 644 "$CRON"
  echo "→ cron de backup instalado em $CRON (03:45, diário)"
fi

echo
echo "→ serviços:"
docker service ls --filter name=n8n
