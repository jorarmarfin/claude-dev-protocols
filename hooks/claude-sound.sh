#!/bin/bash
# Uso: claude-sound.sh [on|off|toggle|status]  (sin argumento = toggle)
f="$HOME/.claude/mute"
case "${1:-toggle}" in
  on)     rm -f "$f" ;;
  off)    touch "$f" ;;
  toggle) [ -f "$f" ] && rm -f "$f" || touch "$f" ;;
  status) ;;
esac
if [ -f "$f" ]; then s="SILENCIO (solo aviso visual)"; else s="SONIDO activado"; fi
echo "Claude: $s"
command -v notify-send >/dev/null && [ "${1:-toggle}" != status ] && notify-send -a "Claude Code" "Claude Code" "$s"
