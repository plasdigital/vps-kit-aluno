#!/usr/bin/env bash
#
# Backup diário do Chatwoot: banco + anexos. Instalado pelo deploy-chatwoot.sh
# como cron das 03:30; também roda na mão:
#
#   bash /opt/infra/backup-chatwoot.sh
#
# ⚠️ Contém conversa de cliente final — dado pessoal, e dependendo do seu ramo,
# dado SENSÍVEL (veja docs/dados-sensiveis.md). Por isso o umask 077 e a pasta
# 700: nada aqui pode nascer
# legível para outro usuário da máquina.
#
# São DUAS metades, e faltar uma quebra a restauração:
#   1. o banco (texto das mensagens)  -> pg_dump, 7 gerações
#   2. os anexos (foto de receita, áudio, PDF) -> volume chatwoot_storage
# O Active Storage guarda no banco só o ponteiro para o arquivo. Restaurar só o
# dump devolve conversa com anexo quebrado. Ter as duas metades do MESMO
# instante é o que faz o backup prestar — por isso o carimbo de tempo é um só.
#
# Isto cobre erro de operação (migração ruim, alguém apagar caixa de entrada
# sem querer). NÃO cobre perder a máquina: tudo mora na própria VPS. Essa
# camada é o backup automático da Hostinger, que se liga no hPanel.

set -euo pipefail
umask 077

DESTINO=/opt/infra/backups/chatwoot
RETENCAO_DIAS=7
VOLUME_ANEXOS=chatwoot_storage
SEGREDOS=/opt/infra/chatwoot/chatwoot.env

if [[ ! -f "$SEGREDOS" ]]; then
  echo "$(date -Is) ERRO: $SEGREDOS não existe" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$SEGREDOS"
set +a

install -d -m 700 "$DESTINO"

CONTAINER=$(docker ps -q -f name=chatwoot_postgres | head -1)
if [[ -z "$CONTAINER" ]]; then
  echo "$(date -Is) ERRO: container chatwoot_postgres não está rodando" >&2
  exit 1
fi

CARIMBO=$(date +%Y%m%d-%H%M)
ARQUIVO="$DESTINO/chatwoot-$CARIMBO.sql.gz"

# --clean --if-exists deixa o dump restaurável por cima de um banco existente.
# pipefail garante que uma falha do pg_dump não vire um .gz vazio "de sucesso".
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER" \
  pg_dump -U chatwoot -d chatwoot_production --clean --if-exists \
  | gzip -9 > "$ARQUIVO"

TAMANHO=$(stat -c%s "$ARQUIVO")
if (( TAMANHO < 1024 )); then
  echo "$(date -Is) ERRO: dump suspeito, só $TAMANHO bytes — mantido para inspeção: $ARQUIVO" >&2
  exit 1
fi

# --- anexos ---------------------------------------------------------------
# Espelho que só acumula: rsync SEM --delete, de propósito.
#
# Blob do Active Storage é imutável (nunca reescrito, só criado ou apagado),
# então guardar 7 cópias diárias dos mesmos arquivos seria multiplicar o disco
# por 7 sem ganhar nada. O que o espelho precisa cobrir é exclusão indevida —
# e é justamente isso que o --delete estragaria, propagando a perda no dia
# seguinte. Um arquivo apagado no Chatwoot continua aqui. É a política de
# retenção infinita aplicada também à mídia (veja docs/retencao-e-backup.md).
ORIGEM_ANEXOS=$(docker volume inspect -f '{{.Mountpoint}}' "$VOLUME_ANEXOS" 2>/dev/null || true)
if [[ -z "$ORIGEM_ANEXOS" || ! -d "$ORIGEM_ANEXOS" ]]; then
  echo "$(date -Is) ERRO: volume $VOLUME_ANEXOS não encontrado — banco salvo, anexos NÃO" >&2
  exit 1
fi

install -d -m 700 "$DESTINO/anexos"
# --chmod não é enfeite: com -a puro o rsync copia as permissões da origem
# (755/644) e sobrescreve até o modo da pasta de destino. A pasta-mãe é 700,
# mas anexo de conversa de cliente não fica legível na máquina nem um nível
# abaixo — é foto de documento, comprovante, receita: o que o cliente mandou.
rsync -a --chmod=D700,F600 "$ORIGEM_ANEXOS/" "$DESTINO/anexos/"

ANEXOS_TAM=$(du -sh "$DESTINO/anexos" | cut -f1)
ANEXOS_QTD=$(find "$DESTINO/anexos" -type f | wc -l)

# só apaga dump velho depois de confirmar que o de hoje presta.
# Os anexos não entram nesta linha: eles não têm gerações para expirar.
find "$DESTINO" -maxdepth 1 -name 'chatwoot-*.sql.gz' -mtime +"$RETENCAO_DIAS" -delete

echo "$(date -Is) ok banco=$ARQUIVO ($TAMANHO bytes) anexos=$ANEXOS_QTD arquivos ($ANEXOS_TAM)"
