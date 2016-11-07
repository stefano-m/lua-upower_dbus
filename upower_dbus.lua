--[[
  Copyright 2016 Stefano Mazzucco

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

  @license Apache License, version 2.0
  @author Stefano Mazzucco <stefano AT curso DOT re>
  @copyright 2016 Stefano Mazzucco
]]

local ldbus = require("ldbus_api")

local upower = {}
upower.enums = {}

--- Call a DBus method.
local function call(opts, method, args)
  args = args or {}
  if type(method) ~= "string" then
    error("method type must be a string, got " .. type(method), 2)
  end
  local t = {method = method, args = args}
  for k, v in pairs(opts) do
    t[k] = v
  end
  local status, data = pcall(ldbus.api.call, t)
  if status then
    if data then
      return ldbus.api.get_value(data[1])
    end
  else
    local msg = string.format("Error calling %s:\n%s", method, data)
    error(msg, 2)
  end
end

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

local function update_all_properties(obj)
  local opts = {}
  for k, v in pairs(obj.dbus) do
    opts[k] = v
  end
  opts.interface = "org.freedesktop.DBus.Properties"
  local properties = call(opts, "GetAll", {
                            {sig = ldbus.basic_types.string,
                             value = obj.dbus.interface}})
  for k, v in pairs(properties) do
    obj[k] = v
  end
end

upower.Device = {}

local function update_mapping(obj, name, mapping)
  local value = obj[name]
  if type(value) == "number" then
    -- The enumeration index from UPower starts with 0
    obj[name] = mapping[value + 1]
  end
end


--- Update the device mappings.
-- Unless you are sure that the properties of the Device
-- have changed, you may want to use `update_properties`
-- or `refresh` instead.
-- @see upower.Device:update_properties
-- @see upower.Device:refresh
function upower.Device:update_mappings()
  update_mapping(
    self,
    "Type",
    upower.enums.DeviceTypes)
  update_mapping(
    self,
    "State",
    upower.enums.BatteryStates)
  update_mapping(
    self,
    "Technology",
    upower.enums.BatteryTechnologies)
  update_mapping(
    self,
    "WarningLevel",
    upower.enums.BatteryWarningLevels)
end

--- Update the Device properties by calling DBus
function upower.Device:update_properties()
  update_all_properties(self)
  self:update_mappings()
end

--- Refresh the Device status (and update its properties)
-- Interrogate the Device calling the DBus method "Refresh"
function upower.Device:refresh()
  call(self.dbus, "Refresh")
  self:update_properties()
end

--- Create a new Device
-- @param path The DBus object path for the device.
-- If unspecified the string `"/invalid"` will be used.
function upower.Device:new(path)
  local device = {
    dbus = {
      bus = "system",
      dest = "org.freedesktop.UPower",
      interface = "org.freedesktop.UPower.Device"}
  }
  setmetatable(device, self)
  self.__index = self

  device.dbus.path = path or "/invalid"
  device:update_properties()

  return device
end

upower.Manager = {
  dbus = {
    bus = "system",
    dest = "org.freedesktop.UPower",
    path = "/org/freedesktop/UPower",
    interface = "org.freedesktop.UPower"}
}


--- Update the UPower Devices
-- Call the DBus method `EnumerateDevices` and update
-- `self.devices`
function upower.Manager:update_devices()
  local devices = call(self.dbus, "EnumerateDevices")
  for i, path in ipairs(devices) do
    devices[i] = upower.Device:new(path)
  end
  self.devices = devices
end

--- Update the Manager's properties
function upower.Manager:update_properties()
    update_all_properties(self)
end

--- Initialize the Manager singleton
function upower.Manager:init()
  self:update_properties()
  self:update_devices()
end

return upower
