--[[
  Copyright 2017 Stefano Mazzucco

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
      upower.Manager.OnBattery
      -- Enumerate the Device Types known by UPower
      for _, v in ipairs(upower.enums.DeviceTypes) do print(v) end
      -- Say that the first device is a battery
      battery = upower.Manager.devices[1]
      print(battery.Percentage) -- may print 100.0
      -- Update the devices in case something changed
      ctx:iteration()
      -- The battery discharged a bit
      battery.Percentage -- may print 99.0

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2017 Stefano Mazzucco
]]

local proxy = require("dbus_proxy")

local upower = {}
upower.enums = {}

--- @table upower.enums.DeviceTypes
upower.enums.DeviceTypes = {
  "Unknown",
  "Line Power",
  "Battery",
  "Ups",
  "Monitor",
  "Mouse",
  "Keyboard",
  "Pda",
  "Phone"}

--- @table upower.enums.BatteryStates
upower.enums.BatteryStates = {
  "Unknown",
  "Charging",
  "Discharging",
  "Empty",
  "Fully charged",
  "Pending charge",
  "Pending discharge"}

--- @table upower.enums.BatteryTechnologies
upower.enums.BatteryTechnologies = {
  "Unknown",
  "Lithium ion",
  "Lithium polymer",
  "Lithium iron phosphate",
  "Lead acid",
  "Nickel cadmium",
  "Nickel metal hydride"}

--- @table upower.enums.BatteryWarningLevels
upower.enums.BatteryWarningLevels = {
  "Unknown",
  "None",
  "Discharging", -- (only for UPSes)
  "Low",
  "Critical",
  "Action"}

local function update_mapping(obj, name, mapping)
  local value = obj[name]
  obj[name:lower()] = mapping[value + 1]
end


--- Update the device mappings.
-- Unless you are sure that the properties of the Device
-- have changed, you may want to use `update_properties`
-- or `refresh` instead.
-- @see upower.Device:update_properties
-- @see upower.Device:refresh
local function update_mappings(device)
  update_mapping(
    device,
    "Type",
    upower.enums.DeviceTypes)
  update_mapping(
    device,
    "State",
    upower.enums.BatteryStates)
  update_mapping(
    device,
    "Technology",
    upower.enums.BatteryTechnologies)
  update_mapping(
    device,
    "WarningLevel",
    upower.enums.BatteryWarningLevels)
end


--- Create a new Device
-- @param path The DBus object path for the device.
function upower.create_device(path)
  local device =  proxy.Proxy:new(
    {
      bus = proxy.Bus.SYSTEM,
      name = "org.freedesktop.UPower",
      interface = "org.freedesktop.UPower.Device",
      path = path
    }
  )
  device.update_mappings = update_mappings
  device:update_mappings()
  return device
end

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
