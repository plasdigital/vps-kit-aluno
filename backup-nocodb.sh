#!/usr/bin/env bash
#
# Backup diário do NocoDB: banco (bases, tabelas, views, usuários) + pasta de
# dados (config local, cache, anexo de coluna do tipo attachment quando o
# storage é local — mesma lição do Chatwoot: o Postgres sozinho não é o
# backup inteiro). Instalado pelo deploy-nocodb.sh como cron das 04:00;
# também roda na mão:
#
#   bash /opt/infra/backup-nocodb.sh
#
# Cobre erro de operação (tabela apagada sem querer, migração ruim). NÃO
# cobre perder a máquina: tudo mora na própria VPS. Essa camada é o backup
# automático da Hostinger, que se liga no hPanel (ver TODO.md).

set -euo pipefail
umask 077

DESTINO=/opt/infra/backups/nocodb
RETENCAO_DIAS=7
VOLUME_DADOS=nocodb_nocodb_data

install -d -m 700 "$DESTINO"

CONTAINER=$(docker ps -q -f name=nocodb_postgres | head -1)
if [[ -z "$CONTAINER" ]]; then
  echo "$(date -Is) ERRO: container nocodb_postgres não está rodando" >&2
  exit 1
fi

CARIMBO=$(date +%Y%m%d-%H%M)
ARQUIVO="$DESTINO/nocodb-$CARIMBO.sql.gz"

# --clean --if-exists deixa o dump restaurável por cima de um banco existente.
# pipefail garante que uma falha do pg_dump não vire um .gz vazio "de sucesso".
docker exec "$CONTAINER" pg_dump -U nocodb -d nocodb --clean --if-exists \
  | gzip -9 > "$ARQUIVO"

TAMANHO=$(stat -c%s "$ARQUIVO")
if (( TAMANHO < 1024 )); then
  echo "$(date -Is) ERRO: dump suspeito, só $TAMANHO bytes — mantido para inspeção: $ARQUIVO" >&2
  exit 1
fi

# --- pasta de dados ----------------------------------------------------------
# Espelho que só acumula: rsync SEM --delete, mesma lógica do backup dos
# anexos do Chatwoot — exclusão indevida não deve se propagar para o backup
# do dia seguinte.
ORIGEM_DADOS=$(docker volume inspect -f '{{.Mountpoint}}' "$VOLUME_DADOS" 2>/dev/null || true)
if [[ -z "$ORIGEM_DADOS" || ! -d "$ORIGEM_DADOS" ]]; then
  echo "$(date -Is) ERRO: volume $VOLUME_DADOS não encontrado — banco salvo, dados NÃO" >&2
  exit 1
fi

install -d -m 700 "$DESTINO/dados"
rsync -a --chmod=D700,F600 "$ORIGEM_DADOS/" "$DESTINO/dados/"

# só apaga dump velho depois de confirmar que o de hoje presta.
find "$DESTINO" -maxdepth 1 -name 'nocodb-*.sql.gz' -mtime +"$RETENCAO_DIAS" -delete

echo "$(date -Is) ok banco=$ARQUIVO ($TAMANHO bytes)"
