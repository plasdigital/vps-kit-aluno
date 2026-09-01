#!/usr/bin/env bash
#
# Padrão de VPS — sobe (ou atualiza) as stacks da camada base.
# Roda NA VPS, a partir da pasta /opt/infra.
#
#   bash /opt/infra/deploy.sh
#
# É idempotente: rodar de novo aplica o que mudou e não mexe no resto. Para
# atualizar uma versão, edite vps.env e rode outra vez.

set -euo pipefail
cd "$(dirname "$0")"

# set -a exporta tudo que o arquivo definir — é assim que o docker stack
# deploy enxerga as variáveis ${...} usadas nos YAML.
set -a
# shellcheck source=/dev/null
source ./vps.env
set +a

echo "→ rede interna: $REDE_INTERNA"
echo "→ portainer:    https://$PORTAINER_HOST"
echo

# a config dinâmica do Traefik é bind-mount: precisa existir num caminho fixo
install -d /opt/infra/traefik/dynamic
cp -f traefik-dynamic/*.yml /opt/infra/traefik/dynamic/

echo "→ subindo traefik"
docker stack deploy --prune --resolve-image always -c stacks/traefik.yml traefik

echo "→ subindo portainer"
docker stack deploy --prune --resolve-image always -c stacks/portainer.yml portainer

echo
echo "→ serviços:"
docker service ls
