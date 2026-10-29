#!/bin/bash
FLAG_FILE="$HOME/.config/howdy-sudo-disabled"

if [ -f "$FLAG_FILE" ]; then
    rm -f "$FLAG_FILE"
    notify-send -a "Facial Sudo" -i security-high "Reconocimiento Facial Sudo" "🟢 ACTIVADO: Ahora Howdy responderá al usar sudo."
else
    touch "$FLAG_FILE"
    notify-send -a "Facial Sudo" -i security-low "Reconocimiento Facial Sudo" "🔴 DESACTIVADO: Sudo solicitará tu contraseña tradicional."
fi
