#!/usr/bin/env bash
# sysstat.sh cpu|ram — usage % for the tmux status bar (catppuccin cpu/ram
# modules). Replaces tmux-cpu, which forked iostat plus dozens of
# `tmux show-option` calls per refresh (~0.7 core on srv1). Pure bash
# reading /proc: no subprocesses. CPU is the average since the previous
# refresh (state kept per tmux server). Linux only; prints nothing elsewhere.

case "${1:-}" in
  cpu)
    [ -r /proc/stat ] || exit 0
    read -r _ u n s i w x y z _ < /proc/stat
    total=$((u + n + s + i + w + x + y + z))
    idle=$((i + w))
    tmux_id="${TMUX%%,*}"
    state="${XDG_RUNTIME_DIR:-/tmp}/tmux-sysstat-cpu${tmux_id//\//_}"
    prev_total=0 prev_idle=0
    [ -r "$state" ] && read -r prev_total prev_idle < "$state"
    echo "$total $idle" > "$state"
    dt=$((total - prev_total))
    if [ "$prev_total" -eq 0 ] || [ "$dt" -le 0 ]; then
      printf -- '--%%'
    else
      printf '%d%%' $((100 * (dt - (idle - prev_idle)) / dt))
    fi
    ;;
  ram)
    [ -r /proc/meminfo ] || exit 0
    while read -r k v _; do
      case "$k" in
        MemTotal:) t=$v ;;
        MemAvailable:) a=$v ;;
      esac
    done < /proc/meminfo
    printf '%d%%' $((100 * (t - a) / t))
    ;;
  *) echo "usage: $0 cpu|ram" >&2; exit 2 ;;
esac
