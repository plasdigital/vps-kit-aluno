#!/usr/bin/env bash
#
# Roda um comando pontual no ambiente do Chatwoot — migração, console, rake,
# criar usuário. É o equivalente ao `docker compose run --rm rails …` que a
# documentação do Chatwoot usa; o Swarm não tem esse comando, por isso existe
# este script.
#
#   bash /opt/infra/chatwoot-rails.sh bundle exec rails db:chatwoot_prepare
#   bash /opt/infra/chatwoot-rails.sh bundle exec rails c        # console
#
# Sobe um container avulso na rede interna da stack (por isso ela é
# attachable), com as mesmas variáveis dos serviços, e some ao terminar.
#
# ⚠️ O que roda aqui fala com o banco de PRODUÇÃO, que guarda
# conversa de cliente final — dado pessoal (veja docs/dados-sensiveis.md).
# Nada de SELECT em conversa para "dar uma olhada".

set -euo pipefail
cd "$(dirname "$0")"

SEGREDOS=/opt/infra/chatwoot/chatwoot.env

if [[ $# -eq 0 ]]; then
  echo "uso: $0 <comando>   (ex: bundle exec rails db:chatwoot_prepare)" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source ./vps.env
# shellcheck source=/dev/null
source "$SEGREDOS"
set +a

# Repassa para dentro do container qualquer variável CW_* do ambiente de quem
# chamou. É assim que o chatwoot-criar-usuario.sh entrega e-mail, nome e senha
# sem que nenhum desses valores apareça na linha de comando (que qualquer
# usuário da máquina lê com `ps`).
EXTRA=()
while read -r nome; do
  [[ -n "$nome" ]] && EXTRA+=(-e "$nome")
done < <(env | sed -n 's/^\(CW_[A-Z0-9_]*\)=.*/\1/p')

# -i para o console do Rails funcionar; sem -t porque o script também roda
# por SSH não interativo, onde alocar TTY falha.
docker run --rm -i \
  "${EXTRA[@]}" \
  --network chatwoot_interna \
  -e RAILS_ENV=production \
  -e NODE_ENV=production \
  -e INSTALLATION_ENV=docker \
  -e RAILS_LOG_TO_STDOUT=true \
  -e SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  -e FRONTEND_URL="https://$CHATWOOT_HOST" \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DATABASE=chatwoot_production \
  -e POSTGRES_USERNAME=chatwoot \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e REDIS_URL=redis://redis:6379 \
  -e REDIS_PASSWORD="$REDIS_PASSWORD" \
  "chatwoot/chatwoot:$CHATWOOT_VERSAO" \
  "$@"
