#!/bin/sh
# Bridges the screen and the kiosk to Home Assistant over MQTT, as light.<hostname>_screen and
# switch.<hostname>_kiosk (MQTT discovery). HA runs the schedule. Broker and login are in
# ~/.config/mosquitto_pub and mosquitto_sub. Runs as the systemd user service kiosk-mqtt.
export WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/$(id -u)
BL=/sys/class/backlight/10-0045/brightness
OFF=$HOME/kiosk-off  # while this exists, kiosk.sh and the watchdog leave Chromium stopped
N=$(hostname)        # names the device, its entities and its MQTT topics

pub() { mosquitto_pub -r -t "$1" -m "$2"; }

screen() {  # $1 = brightness 1-255, or 0 for off (backlight and display output)
  if [ "$1" -gt 0 ]; then
    wlr-randr --output DSI-1 --on && echo "$1" > $BL && pub $N/screen/brightness "$1" && pub $N/screen/state ON
  else
    echo 0 > $BL; wlr-randr --output DSI-1 --off; pub $N/screen/state OFF
  fi
}

kiosk() {  # $1 = ON or OFF
  if [ "$1" = ON ]; then
    rm -f $OFF
    pgrep -f /usr/lib/chromium/chromium >/dev/null || setsid $HOME/kiosk.sh >/dev/null 2>&1 </dev/null &
  else
    touch $OFF; pkill -f /usr/lib/chromium/chromium
  fi
  pub $N/kiosk/state "$1"
}

dev="\"device\":{\"identifiers\":[\"$N\"],\"name\":\"$N\",\"model\":\"Raspberry Pi 4 Model B\",\"manufacturer\":\"Raspberry Pi\"},\"availability_topic\":\"$N/status\""
pub homeassistant/light/$N/screen/config "{\"name\":\"Screen\",\"unique_id\":\"${N}_screen\",\"icon\":\"mdi:monitor\",\"command_topic\":\"$N/screen/set\",\"state_topic\":\"$N/screen/state\",\"brightness_command_topic\":\"$N/screen/brightness/set\",\"brightness_state_topic\":\"$N/screen/brightness\",$dev}"
pub homeassistant/switch/$N/kiosk/config "{\"name\":\"Kiosk\",\"unique_id\":\"${N}_kiosk\",\"icon\":\"mdi:web\",\"command_topic\":\"$N/kiosk/set\",\"state_topic\":\"$N/kiosk/state\",$dev}"

last=$(cat $BL); [ "$last" -gt 0 ] || last=255  # brightness to use for a plain "on"
if [ "$(cat $BL)" -gt 0 ]; then pub $N/screen/brightness "$last"; pub $N/screen/state ON; else pub $N/screen/state OFF; fi
if [ -e $OFF ]; then pub $N/kiosk/state OFF; else pub $N/kiosk/state ON; fi
# online once mosquitto_sub below has subscribed, or HA's first commands are lost
# ponytail: fixed 2 s wait, fine on a LAN. The service's ExecStopPost and the will publish offline.
(sleep 2; pub $N/status online) &

mosquitto_sub -v -t $N/screen/set -t $N/screen/brightness/set -t $N/kiosk/set \
  --will-topic $N/status --will-payload offline --will-retain |
while read -r topic msg; do
  case $topic in
    $N/screen/set) if [ "$msg" = ON ]; then screen "$last"; else screen 0; fi ;;
    $N/screen/brightness/set) [ "$msg" -gt 0 ] && last=$msg; screen "$msg" ;;
    $N/kiosk/set) kiosk "$msg" ;;
  esac
done
