--[[
  Copyright 2017 - 2025 Stefano Mazzucco

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]]

--[[--
  Get information about your power devices using
  [UPower](https://upower.freedesktop.org/) and DBus.

  Requiring this module will return the UPower Manager singleton.

  Example:

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

  @module upower_dbus

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2017 - 2025 Stefano Mazzucco
]]

local proxy = require("dbus_proxy")
local enum = require("enum")

local upower = {}

--- UPower Enumerations.
-- The `upower.enums` table contains the below [Lua
-- Enumerations](https://luarocks.org/modules/stefano-m/enum).
-- @within Enumerations
upower.enums = {}

--- The type of power source
-- @within Enumerations
-- @table DeviceType
local DeviceType = {
    "Unknown",
    "Line Power",
    "Battery",
    "Ups",
    "Monitor",
    "Mouse",
    "Keyboard",
    "Pda",
    "Phone"
}
upower.enums.DeviceType = enum.new("DeviceType", DeviceType)

--- The state of the battery.
-- This property is only valid if the device is a battery.
-- @within Enumerations
-- @table BatteryState
local BatteryState =   {
  "Unknown",
  "Charging",
  "Discharging",
  "Empty",
  "Fully charged",
  "Pending charge",
  "Pending discharge"
}
upower.enums.BatteryState = enum.new("BatteryState", BatteryState)

--- The technology used by the battery.
-- This property is only valid if the device is a battery.
-- @within Enumerations
-- @table BatteryTechnology
local BatteryTechnology = {
  "Unknown",
  "Lithium ion",
  "Lithium polymer",
  "Lithium iron phosphate",
  "Lead acid",
  "Nickel cadmium",
  "Nickel metal hydride"
}
upower.enums.BatteryTechnology = enum.new("BatteryTechnology", BatteryTechnology)

--- The warning level of the battery.
-- This property is only valid if the device is a battery.
-- @within Enumerations
-- @table BatteryWarningLevel
local BatteryWarningLevel =  {
    "Unknown",
    "None",
    "Discharging", -- (only for UPSes)
    "Low",
    "Critical",
    "Action"
  }
upower.enums.BatteryWarningLevel = enum.new("BatteryWarningLevel", BatteryWarningLevel)

local Mappings = {
  Type =  DeviceType,
  State = BatteryState,
  Technology = BatteryTechnology,
  WarningLevel = BatteryWarningLevel,
}

local MappingsList = {}
do
  local i = 1
  for k, _ in pairs(Mappings) do
    MappingsList[i] = k
    i = i + 1
  end
end

local function update_mapping(obj, key)
  rawset(obj, key:lower(), Mappings[key][obj[key] + 1])
end


--[[-- Create a new [UPower
  Device](https://upower.freedesktop.org/docs/Device.html).

  You can use the EnumerateDevices method on the Manager object to obtain the
  correct device paths. But the objects are also available from the
  `Manager.devices` property.

  The `Type`, `State`, `Technology` and `WarningLevel` uppercase numeric
  properties have a lowercase string equivalent.

  For example:

      device.Type -- numeric e.g. 2.0
      device.type -- string e.g. "Battery"

  @param path The DBus object path for the device.
  @within Device
  @see upower.enums
  @see upower.Manager
]]
function upower.create_device(path)
  local device =  proxy.Proxy:new(
    {
      bus = proxy.Bus.SYSTEM,
      name = "org.freedesktop.UPower",
      interface = "org.freedesktop.UPower.Device",
      path = path
    }
  )

  for _, prop in ipairs(MappingsList)  do
    update_mapping(device, prop)
  end

  device:on_properties_changed(
    function(dvc, changed)
      for _, prop in ipairs(MappingsList) do
        if changed[prop] then
          update_mapping(dvc, prop)
        end
      end
    end
  )

  return device
end

--[[-- The display device.

  The "display device" is a composite device that represents the status icon to
  show in desktop environments. Its path is guaranteed to be
  /org/freedesktop/UPower/devices/DisplayDevice.

]]
upower.display_device = upower.create_device("/org/freedesktop/UPower/devices/DisplayDevice")

--- The UPower Manager that proxies the [UPower DBus
-- interface](https://upower.freedesktop.org/docs/UPower.html).
-- Additionally the `devices` field contains the available Device objects.
-- @see upower.create_device
-- @within Manager
upower.Manager = proxy.Proxy:new(
  {
    bus = proxy.Bus.SYSTEM,
    name = "org.freedesktop.UPower",
    path = "/org/freedesktop/UPower",
    interface = "org.freedesktop.UPower"
  }
)


--- Initialize the Manager singleton
local function init(mgr)
  local devices = mgr:EnumerateDevices()
  for i, path in ipairs(devices) do
    devices[i] = upower.create_device(path)
  end
  mgr.devices = devices
end

init(upower.Manager)

return upower
