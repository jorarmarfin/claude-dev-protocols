#!/bin/bash
# Uso: claude-notify.sh <stop|ask>
# Si existe ~/.claude/mute -> aviso visual (sin audio). Si no -> audio.
case "$1" in
  stop) mp3=/home/lmayta/stop.mp3;       msg="Claude terminó" ;;
  *)    mp3=/home/lmayta/asistencia.mp3; msg="Claude necesita tu atención" ;;
esac
if [ -f "$HOME/.claude/mute" ]; then
  command -v notify-send >/dev/null && notify-send -a "Claude Code" -i dialog-information "Claude Code" "$msg"
else
  ffplay -nodisp -autoexit -loglevel quiet "$mp3" >/dev/null 2>&1
fi
exit 0
