#!/usr/bin/env bash
#
# Backup diário do n8n: banco (workflows, execuções, credenciais cifradas) +
# pasta .n8n (config local, cache de nodes community). Instalado pelo
# deploy-n8n.sh como cron das 03:45; também roda na mão:
#
#   bash /opt/infra/backup-n8n.sh
#
# ⚠️ O dump contém credenciais de integração CIFRADAS (a chave que decifra é
# a N8N_ENCRYPTION_KEY, que não está no dump — fica só em n8n.env). Mesmo
# assim, umask 077 e pasta 700: por padrão, nada aqui nasce legível para
# outro usuário da máquina.
#
# Cobre erro de operação (workflow apagado sem querer, migração ruim). NÃO
# cobre perder a máquina: tudo mora na própria VPS. Essa camada é o backup
# automático da Hostinger, que se liga no hPanel (ver TODO.md).

set -euo pipefail
umask 077

DESTINO=/opt/infra/backups/n8n
RETENCAO_DIAS=7
VOLUME_DADOS=n8n_n8n_data

install -d -m 700 "$DESTINO"

CONTAINER=$(docker ps -q -f name=n8n_postgres | head -1)
if [[ -z "$CONTAINER" ]]; then
  echo "$(date -Is) ERRO: container n8n_postgres não está rodando" >&2
  exit 1
fi

CARIMBO=$(date +%Y%m%d-%H%M)
ARQUIVO="$DESTINO/n8n-$CARIMBO.sql.gz"

# --clean --if-exists deixa o dump restaurável por cima de um banco existente.
# pipefail garante que uma falha do pg_dump não vire um .gz vazio "de sucesso".
docker exec "$CONTAINER" pg_dump -U n8n -d n8n --clean --if-exists \
  | gzip -9 > "$ARQUIVO"

TAMANHO=$(stat -c%s "$ARQUIVO")
if (( TAMANHO < 1024 )); then
  echo "$(date -Is) ERRO: dump suspeito, só $TAMANHO bytes — mantido para inspeção: $ARQUIVO" >&2
  exit 1
fi

# --- pasta .n8n -------------------------------------------------------------
# Espelho que só acumula: rsync SEM --delete, mesma lógica do backup dos
# anexos do Chatwoot — exclusão indevida não deve se propagar para o backup
# do dia seguinte.
ORIGEM_DADOS=$(docker volume inspect -f '{{.Mountpoint}}' "$VOLUME_DADOS" 2>/dev/null || true)
if [[ -z "$ORIGEM_DADOS" || ! -d "$ORIGEM_DADOS" ]]; then
  echo "$(date -Is) ERRO: volume $VOLUME_DADOS não encontrado — banco salvo, .n8n NÃO" >&2
  exit 1
fi

install -d -m 700 "$DESTINO/dados"
rsync -a --chmod=D700,F600 "$ORIGEM_DADOS/" "$DESTINO/dados/"

# só apaga dump velho depois de confirmar que o de hoje presta.
find "$DESTINO" -maxdepth 1 -name 'n8n-*.sql.gz' -mtime +"$RETENCAO_DIAS" -delete

echo "$(date -Is) ok banco=$ARQUIVO ($TAMANHO bytes)"
