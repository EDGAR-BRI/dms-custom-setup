#!/bin/bash
# Sincroniza el vault de Obsidian con Google Drive SOLO si Obsidian está abierto.
# Imprime el estado a stdout: SKIPPED | SYNC_OK | SYNC_FAIL
# Uso manual:  obsidian-sync

VAULT="/home/edgar/Documentos/obsidian"
REMOTE="drive:Obsidian"
LOG="/home/edgar/.cache/obsidian-drive-sync.log"

if ! pgrep -f "/usr/lib/obsidian/app.asar" >/dev/null 2>&1; then
  echo "$(date '+%F %T') Obsidian cerrado, no se sincroniza." >> "$LOG"
  echo "SKIPPED"
  exit 0
fi

echo "$(date '+%F %T') Sincronizando..." >> "$LOG"
rclone bisync "$VAULT" "$REMOTE" \
  --create-empty-src-dirs \
  --resilient \
  --conflict-resolve newer \
  >> "$LOG" 2>&1
rc=$?
echo "$(date '+%F %T') Sync terminado (exit $rc)" >> "$LOG"
if [ "$rc" -eq 0 ]; then
  echo "SYNC_OK"
else
  echo "SYNC_FAIL"
fi
exit $rc