# Get information about your power devices using [UPower](https://upower.freedesktop.org/) and DBus.

## Requirements

In addition to the requirements specified in the rockspec file,
you need UPower and DBus (usually both are present in modern GNU/Linux systems).
Note that you may need permissions to access the UPower DBus interface.

## Installation

This module can be installed with [Luarocks](http://luarocks.org/) by running

    luarocks install upower_dbus

Use the `--local` option in `luarocks` if you don't want or can't install it system-wide.

## Example

This module exposes the following

* `Manager` singleton, containing its own properties and the `devices` array (after initialization).
* `enums` table containing the UPower enumerations as arrays of strings.
* `Device` constructor, although it's advised to use the Manager to get the devices rather then building them by hand.

```lua
local upower = require("upower_dbus")
upower.Manager:init()
-- What version of UPower is in use?
upower.Manager.DaemonVersion
-- Are we using a battery?
upower.Manager.OnBattery
-- Print all fields of the first device found
for k, v in pairs(upower.Manager.devices[1]) do print(k, v) end
-- Enumerate the Device Types known by UPower
for _, v in ipairs(upower.enums.DeviceTypes) do print(v) end
-- Say that the first device is a battery
battery = upower.Manager.devices[1]
print(battery.Percentage) -- may print 100.0
-- Update the devices in case something changed
upower.Manager:update_devices()
-- The battery discharged a bit
battery.Percentage -- may print 99.0
```
