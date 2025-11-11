# Get information about your power devices using [UPower](https://upower.freedesktop.org/) and DBus.

## Requirements

In addition to the requirements specified in the rockspec file, you need UPower
and DBus (usually both are present in modern GNU/Linux systems) as well as
[GObject Introspection](https://gi.readthedocs.io/en/latest/).

Note that your user may need specific permissions to access the UPower DBus
interface.

## Installation

### Luarocks

This module can be installed with [Luarocks](http://luarocks.org/) by running

    luarocks install upower_dbus

Use the `--local` option in `luarocks` if you don't want or can't install it system-wide.

### NixOS

If you are on NixOS, you can install this package from the [flake](./flake.nix).

Note that the older method of using
[nix-stefano-m-overlays](https://github.com/stefano-m/nix-stefano-m-nix-overlays)
is currently unmaintained.


## Example

This module exposes the following

* `upower.Manager` singleton, containing its own properties and the `devices` array.
* `upower.enums` table containing the UPower enumerations as arrays of strings.
* `upower.create_device` factory to create `Device` objects, although it's
  advised to use the Manager's `devices` property rather then building them by
  hand.
* `upower.display_device` representing the status to show in a desktop
  environment.

```lua
GLib = require("lgi").GLib
ctx = GLib.MainLoop():get_context()
upower = require("upower_dbus")
-- What version of UPower is in use?
upower.Manager.DaemonVersion
-- Are we using a battery?
upower.Manager.OnBattery -- true or false
-- Enumerate the Device Types known by UPower
for _, v in ipairs(upower.enums.DeviceType) do print(v) end
-- Say that the first device is a battery
battery = upower.Manager.devices[1]
print(battery.Percentage) -- may print 100.0
-- Update the devices in case something changed
ctx:iteration()
-- The battery discharged a bit
battery.Percentage -- may print 99.0
battery.WarningLevel -- CamelCase, may print 4.0
battery.warninglevel -- lower case, may print Critical
```
