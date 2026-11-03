#!/bin/sh
# Suspend the machine after a long idle period.
#
# Driver: swayidle, from ~/.config/niri/startup.kdl. It is the last stage of a
# ladder whose earlier stages are already configured there:
#
#   300s   lock the screen
#   600s   power off the monitors (DPMS)
#   900s   idle-suspend.sh --battery-only   -> suspend only on battery
#   1800s  idle-suspend.sh                  -> suspend on AC as well
#
# So: 15 minutes idle on battery, 30 minutes on AC. Nothing is ever suspended
# with the screen unlocked -- swayidle's before-sleep hook runs lock.sh first,
# and swayidle holds a `delay` inhibitor so that hook completes before systemd
# actually enters sleep.
#
# /sys/class/power_supply/ADP0/online is the AC adapter on the ASUS FX608JMR.
# If it disappears (desktop, USB-C-only charging), on_ac() returns false and
# the 900s timeout degrades to "suspend on any power source" -- the safer
# failure mode for a laptop that might be running on battery.
set -u

AC_ONLINE=/sys/class/power_supply/ADP0/online

say() {
  if command -v systemd-cat >/dev/null 2>&1; then
    printf '%s\n' "$*" | systemd-cat -t idle-suspend
  fi
}

on_ac() {
  [ -r "$AC_ONLINE" ] && [ "$(cat "$AC_ONLINE")" = "1" ]
}

if [ "${1:-}" = "--battery-only" ] && on_ac; then
  say "15m idle on AC power - staying awake until the 30m timeout"
  exit 0
fi

say "idle limit reached (AC online=$([ -r "$AC_ONLINE" ] && cat "$AC_ONLINE" || echo unknown)) - suspending"
exec systemctl suspend
