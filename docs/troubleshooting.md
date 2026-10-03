# Troubleshooting

## Trackpad clicks die randomly, cursor still moves (ThinkPad)

**Symptoms:** pointer motion keeps working, but tap-to-click and physical
presses randomly stop registering. No pattern tied to typing or suspend.

**Cause:** the TrackPoint shares the Synaptics port in SMBus/intertouch
mode (`rmi_smbus`). The kernel log fills with PS/2 desync storms on that
shared port:

```
psmouse serio2: TrackPoint at rmi4-00.fn03/serio0/input0 lost synchronization
psmouse serio2: resync failed, issuing reconnect request
psmouse serio2: Failed to enable mouse on rmi4-00.fn03/serio0
```

Each port reset opens a dead window: relative motion recovers, but discrete
click events (taps, button presses) landing inside it are swallowed. Check
with:

```
journalctl -b | grep -E "psmouse|lost synchronization|resync failed"
lsmod | grep rmi_smbus   # confirms intertouch mode is active
```

**Fix:** force classic PS/2 mode with `psmouse.synaptics_intertouch=0`.
This machine boots via UKI (mkinitcpio preset), so the cmdline lives in
`/etc/kernel/cmdline`:

```
echo " psmouse.synaptics_intertouch=0" | sudo tee -a /etc/kernel/cmdline
sudo mkinitcpio -P
```

Then reboot and verify:

```
cat /sys/module/psmouse/parameters/synaptics_intertouch  # expect 0
journalctl -f | grep psmouse   # should stay quiet during use
```

**Trade-off:** PS/2 mode may lose 3-finger gestures (e.g. the 3-finger
workspace swipe). If that matters more, revert: remove the parameter from
`/etc/kernel/cmdline`, rebuild with `sudo mkinitcpio -P`, reboot.

The Hyprland side is already explicit (`hypr/.config/hypr/config/input.lua`
sets `tap_to_click`, `disable_while_typing`, `natural_scroll`), so no
compositor change is needed for this issue.
