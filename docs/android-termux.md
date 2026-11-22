# Android phone and Termux Ubuntu

This is the **Android and Termux-only** setup guide. It covers device
settings, the Termux app, PRoot-Distro Ubuntu, wake locks, and the
Termux:Boot add-on. It does **not** configure any application server.

For T3 Code, the separate canonical runbook is
[judigot/agent-workspace/docs/termux-t3.md](https://github.com/judigot/agent-workspace/blob/main/docs/termux-t3.md).

## 1. Configure the Android phone

1. Open **Settings > Apps > Termux > Battery**.
2. Select **Unrestricted** (the exact label and menu vary by phone).
3. If available, permit Termux to run in the background and enable its
   notifications.

These settings may reduce background interruptions. They **do not** make
Android incapable of stopping an app, and they are not an uptime guarantee.
A wake lock may cause significantly greater battery consumption.

## 2. Install or enter Ubuntu through Termux

Install Termux from a trusted distribution source. Follow the existing
`judigot/user` environment bootstrap for the initial installation:

```sh
. <(curl -fsSL "https://raw.githubusercontent.com/judigot/user/main/load-devrc.sh?cachebustkey=$(date +%s)")
termuxubuntu
termuxloginubuntu
```

The `termuxubuntu` alias updates packages, installs `proot-distro`, and
installs Ubuntu. **Run it only for initial installation.** If Ubuntu already
exists, do not reinstall or reset it.

For ordinary use, open **Termux** and run:

```sh
termux-wake-lock && proot-distro login ubuntu
```

This acquires an Android wake lock and opens an existing Ubuntu container.
When finished with background work, return to the Termux host shell and run
`termux-wake-unlock` if you no longer need the lock.

To confirm installed distributions and active PRoot sessions from Termux:

```sh
proot-distro list
proot-distro ps
```

A normal interactive Ubuntu login is separate from an explicitly detached
PRoot session. Closing a terminal does not guarantee that processes started
inside that login will remain alive.

## 3. Optional Termux:Boot

To execute **approved** scripts after the Android phone starts, use the
official [Termux:Boot](https://github.com/termux/termux-boot) add-on.

1. Install Termux:Boot from a source signed compatibly with the already
   installed Termux app. Do not uninstall a working Termux installation
   just to change signing sources.
2. Launch **Termux:Boot once** from its app icon to authorize boot operation.
3. Review its Android battery/background/autostart permissions.
4. Place any application-specific startup scripts in
   `~/.termux/boot/` inside Termux, make them executable, and verify
   their results after reboot.

Termux:Boot automatically runs executable files in that directory in sorted
order. It does not restart a failed process continuously; a reboot, forced
stop, aggressive battery control, or low memory can still interrupt the
processes it starts.

The actual app/server startup instructions and boot script for T3 are kept
**only** in [the T3 runbook](https://github.com/judigot/agent-workspace/blob/main/docs/termux-t3.md#start-it-after-a-phone-reboot-optional).
Avoid adding application-specific configuration to this phone guide.

## Safety and recovery

- Keep Termux, Termux:Boot, and PRoot-Distro updated intentionally. Review
  release compatibility before changing a stable installation.
- `proot-distro remove` and `proot-distro reset` can destroy local data.
  Never use them as a routine recovery step.
- PRoot-Distro supports detached sessions in current releases. Check
  `proot-distro login --help` for `--detach` on your installed version.
- Android "Unrestricted" and `termux-wake-lock` reduce sleeping risk but
  cannot guarantee 24-hour availability. Test with the screen off and after
  reboot before relying on the phone as a workstation.
- Keep project code and important decisions committed to GitHub. A phone
  failure must not be the only copy of work.

## Upstream references

- [Termux](https://termux.dev/)
- [PRoot-Distro](https://github.com/termux/proot-distro)
- [Termux:Boot](https://github.com/termux/termux-boot)
