#!/bin/sh
# Restart kiosk when screen stays blank (Floor796 wander stuck off-map). Runs forever from labwc autostart.
# Blank = screenshot PNG under 5KB; real scenes are 70KB+, even half off-map
export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/$(id -u)
blank=0
while :; do
  sleep 10
  [ -e $HOME/kiosk-off ] && { blank=0; continue; }  # kiosk stopped on purpose
  grim -s 0.5 /tmp/kiosk-check.png 2>/dev/null || continue
  if [ "$(stat -c %s /tmp/kiosk-check.png)" -lt 5000 ]; then blank=$((blank + 1)); else blank=0; fi
  if [ $blank -ge 3 ]; then
    keep=$HOME/kiosk-blank-$(date +%Y%m%d-%H%M%S).png
    cp /tmp/kiosk-check.png "$keep"  # keep what the screen showed, for diagnosis
    logger -t kiosk-watchdog "blank screen, restarting kiosk (saved $keep)"
    setsid $HOME/kiosk.sh >/dev/null 2>&1 < /dev/null &
    blank=0
    sleep 60  # let the page load before checking again
  fi
done
