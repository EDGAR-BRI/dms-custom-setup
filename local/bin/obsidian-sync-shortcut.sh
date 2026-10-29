#!/bin/bash
# Atajo Mod+Shift+S: sincroniza Obsidian con Google Drive solo si Obsidian está abierto.
# Muestra una notificación con el resultado.

notify-send -a "Obsidian" -i obsidian "Sync" "Sincronizando con Google Drive..."

STATUS=$(/home/edgar/.local/bin/obsidian-drive-sync.sh)

case "$STATUS" in
  SYNC_OK)
    notify-send -a "Obsidian" -i obsidian "Sync" "Vault sincronizado con Google Drive"
    ;;
  SKIPPED)
    notify-send -a "Obsidian" -i obsidian "Sync" "Obsidian cerrado, no se sincronizó"
    ;;
  *)
    notify-send -a "Obsidian" -i obsidian -u critical "Sync" "Error al sincronizar — revisa el log"
    ;;
esac