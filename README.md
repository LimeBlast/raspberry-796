# raspberry-796

[Floor796](https://floor796.com) wandering by itself, full screen, on a Raspberry Pi 4 and the official 7" touchscreen. Home Assistant can optionally dim it, turn it off, and stop the browser when no one's around.

The background, and why each piece is there, is in the blog post: [Running Floor796 in kiosk mode on a Raspberry Pi](https://maker.rip/2026/10/21/running-floor796-in-kiosk-mode-on-a-raspberry-pi/). This repo holds the files and the steps.

Not affiliated with Floor796. The artwork on the screen is theirs.

## What you need

- Raspberry Pi 4 Model B (2GB is enough)
- Official Raspberry Pi 7" touchscreen (800x480), on the DSI ribbon
- Raspberry Pi OS with the desktop (Debian 13 trixie, labwc), on the network, with SSH
- For the Home Assistant part: an MQTT broker that Home Assistant uses (for example the Mosquitto add-on)

Everything runs as your normal desktop user, not root.

## Files

| File | Goes to | What it does |
|---|---|---|
| `kiosk.sh` | `~/kiosk.sh` | Starts (or restarts) Chromium on Floor796's Wandering mode |
| `make-blank-cursor.sh` | run once | Makes the invisible cursor theme |
| `config/labwc/autostart` | `~/.config/labwc/autostart` | Starts the kiosk at login |
| `config/labwc/environment` | add to `~/.config/labwc/environment` | Uses the invisible cursor |
| `config/labwc/rc.xml` | merge into `~/.config/labwc/rc.xml` | Optional touch |
| `crontab` | `crontab -e` | Restarts the browser every 6 hours |
| `kiosk-mqtt.sh` | `~/kiosk-mqtt.sh` | Optional: the screen and browser in Home Assistant |
| `config/systemd/user/kiosk-mqtt.service` | `~/.config/systemd/user/` | Runs `kiosk-mqtt.sh` |
| `home-assistant/automation.yaml` | Home Assistant | Optional: the schedule |

## Set up the kiosk

1. Log straight into the desktop and never blank the screen:

   ```sh
   sudo raspi-config nonint do_boot_behaviour B4
   sudo raspi-config nonint do_blanking 1
   ```

   If the screen is upside down, open Preferences → Screen Configuration, right-click DSI-1, and set Orientation → Inverted.

2. Copy the files across from this repo:

   ```sh
   git clone https://github.com/LimeBlast/raspberry-796.git && cd raspberry-796
   cp kiosk.sh ~/
   mkdir -p ~/.config/labwc && cp config/labwc/autostart ~/.config/labwc/
   cat config/labwc/environment >> ~/.config/labwc/environment
   sh make-blank-cursor.sh
   (crontab -l 2>/dev/null; cat crontab) | crontab -
   ```

3. Optional touch: put `/boot/firmware/config.txt` back up, replace `display_auto_detect=1` with `dtoverlay=vc4-kms-dsi-7inch`, and add the `<touch>` line from `config/labwc/rc.xml` to `~/.config/labwc/rc.xml`, with the device name from `libinput list-devices`.

4. Reboot. Floor796 appears and starts wandering within about 20 seconds.

The blog post's watchdog isn't needed any more. Wandering used to blank the screen every 30 to 90 minutes, and Floor796 fixed that on 25 October 2026.

## Home Assistant (optional)

`kiosk-mqtt.sh` shows the Pi in Home Assistant through MQTT discovery, as a device named after its hostname with two entities:

- `light.<hostname>_screen`: the backlight, with brightness. Off also turns the display output off.
- `switch.<hostname>_kiosk`: Chromium. Off stops it and creates `~/kiosk-off`, which `kiosk.sh` and cron leave alone until it's on again.

1. Create a broker login for the Pi. In the Mosquitto add-on, add one under `logins`.

2. On the Pi, install the MQTT clients and give them the broker and login (the file is the clients' own default options):

   ```sh
   sudo apt install -y mosquitto-clients
   umask 077
   printf -- '-h <broker address>\n-u <username>\n-P <password>\n' > ~/.config/mosquitto_pub
   cp ~/.config/mosquitto_pub ~/.config/mosquitto_sub
   ```

3. Install and start the service:

   ```sh
   cp kiosk-mqtt.sh ~/
   mkdir -p ~/.config/systemd/user && cp config/systemd/user/kiosk-mqtt.service ~/.config/systemd/user/
   systemctl --user daemon-reload && systemctl --user enable --now kiosk-mqtt
   ```

   The device appears in Home Assistant under Settings → Devices & services → MQTT.

4. Add the schedule from `home-assistant/automation.yaml` to your `automations.yaml`, with your own person and entity names. It runs the kiosk only while you're home, from 06:00 to 22:00: at full brightness while the sun is up, and dimmed before sunrise and after sunset. The rest of the time Chromium is stopped and the screen is off. When it brings the kiosk back, it starts Chromium 15 seconds before turning the screen on, so the page has loaded by then.

Without Home Assistant, the screen stays on at full brightness. The blog post has a cron backlight schedule instead.

## Licence

MIT. The blog post is CC BY 4.0.
