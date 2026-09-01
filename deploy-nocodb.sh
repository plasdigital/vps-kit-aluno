#!/usr/bin/env bash
#
# Sobe (ou atualiza) o NocoDB. Roda NA VPS:
#
#   bash /opt/infra/deploy-nocodb.sh
#
# Separado do deploy.sh de propósito: aquele é a camada base, igual em toda
# VPS. Este é uma aplicação em cima dela. Assim a base continua reaproveitável
# para a próxima ferramenta que você instalar.
#
# É idempotente: rodar de novo aplica só o que mudou.

set -euo pipefail
cd "$(dirname "$0")"

SEGREDOS=/opt/infra/nocodb/nocodb.env

if [[ ! -f "$SEGREDOS" ]]; then
  cat >&2 <<FIM
ERRO: $SEGREDOS não existe.

É o arquivo com as senhas (não versionado, chmod 600). Para criar:

  install -d -m 700 /opt/infra/nocodb
  umask 077
  cat > $SEGREDOS <<'EOF'
  POSTGRES_PASSWORD=...
  NC_AUTH_JWT_SECRET=...
  EOF

Gerar valores: openssl rand -hex 32 (senha), openssl rand -hex 16 (JWT secret).
Modelo: nocodb.env.exemplo. Guarde uma cópia no seu gerenciador de senhas.
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
for obrigatoria in POSTGRES_PASSWORD NC_AUTH_JWT_SECRET NOCO_HOST NOCO_VERSAO NOCO_PG_IMAGEM REDE_INTERNA; do
  if [[ -z "${!obrigatoria:-}" ]]; then
    echo "ERRO: $obrigatoria está vazia (veja vps.env e $SEGREDOS)" >&2
    exit 1
  fi
done

echo "→ nocodb:  https://$NOCO_HOST"
echo "→ versão:  $NOCO_VERSAO"
echo "→ rede:    $REDE_INTERNA"
echo

docker stack deploy --prune --resolve-image always -c stacks/nocodb.yml nocodb

# Backup diário do banco. Instalado aqui para não depender de alguém lembrar:
# a partir do momento em que existe base com dado, existe o que perder.
CRON=/etc/cron.d/nocodb-backup
if [[ ! -f "$CRON" ]]; then
  printf '0 4 * * * root /opt/infra/backup-nocodb.sh >> /var/log/nocodb-backup.log 2>&1\n' > "$CRON"
  chmod 644 "$CRON"
  echo "→ cron de backup instalado em $CRON (04:00, diário)"
fi

echo
echo "→ serviços:"
docker service ls --filter name=nocodb
