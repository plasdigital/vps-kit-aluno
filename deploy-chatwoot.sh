#!/usr/bin/env bash
#
# Sobe (ou atualiza) o Chatwoot. Roda NA VPS:
#
#   bash /opt/infra/deploy-chatwoot.sh
#
# Separado do deploy.sh de propósito: aquele é a camada base, igual em toda
# VPS. Este é uma aplicação em cima dela. Assim a base continua reaproveitável
# para a próxima ferramenta que você instalar (n8n, banco, painel).
#
# É idempotente: rodar de novo aplica só o que mudou.

set -euo pipefail
cd "$(dirname "$0")"

SEGREDOS=/opt/infra/chatwoot/chatwoot.env

if [[ ! -f "$SEGREDOS" ]]; then
  cat >&2 <<FIM
ERRO: $SEGREDOS não existe.

É o arquivo com as senhas (não versionado, chmod 600). Para criar:

  install -d -m 700 /opt/infra/chatwoot
  umask 077
  cat > $SEGREDOS <<'EOF'
  POSTGRES_PASSWORD=...
  REDIS_PASSWORD=...
  SECRET_KEY_BASE=...
  EOF

Modelo: infra/chatwoot.env.exemplo. Guarde cópia no .env.local do projeto.
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
for obrigatoria in POSTGRES_PASSWORD REDIS_PASSWORD SECRET_KEY_BASE CHATWOOT_HOST REDE_INTERNA; do
  if [[ -z "${!obrigatoria:-}" ]]; then
    echo "ERRO: $obrigatoria está vazia (veja vps.env e $SEGREDOS)" >&2
    exit 1
  fi
done

echo "→ chatwoot:   https://$CHATWOOT_HOST"
echo "→ versão:     $CHATWOOT_VERSAO"
echo "→ rede:       $REDE_INTERNA"
echo

docker stack deploy --prune --resolve-image always -c stacks/chatwoot.yml chatwoot

# Backup diário do banco. Instalado aqui para não depender de alguém lembrar:
# a partir do momento em que existe Chatwoot, existe o que perder.
CRON=/etc/cron.d/chatwoot-backup
if [[ ! -f "$CRON" ]]; then
  printf '30 3 * * * root /opt/infra/backup-chatwoot.sh >> /var/log/chatwoot-backup.log 2>&1\n' > "$CRON"
  chmod 644 "$CRON"
  echo "→ cron de backup instalado em $CRON (03:30, diário)"
fi

echo
echo "→ serviços:"
docker service ls --filter name=chatwoot
