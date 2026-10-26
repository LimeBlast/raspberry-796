#!/bin/sh
# Restart Floor796 kiosk (used by labwc autostart, cron and kiosk-mqtt.sh)
[ -e $HOME/kiosk-off ] && exit 0  # stopped by Home Assistant (kiosk-mqtt.sh)
export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/$(id -u) XCURSOR_THEME=blank XCURSOR_SIZE=24
pkill -f /usr/lib/chromium/chromium && sleep 3
exec chromium --kiosk --ozone-platform=wayland --window-size=800,480 --force-device-scale-factor=1 \
  --password-store=basic --noerrdialogs --disable-infobars --no-first-run --hide-scrollbars \
  --disable-pinch --disable-session-crashed-bubble \
  --disable-features=WebAssemblyTrapHandler \
  "https://floor796.com/#wandering"
