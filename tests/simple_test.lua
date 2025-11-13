local string = string
local os = os

local PASS = false              -- luacheck: ignore 311

print("Test STARTED")
local ok, value = pcall(require, "upower_dbus")

if not ok then
  -- Running inside the nix builder
  local expected_error = "Gio.DBusConnection expected, got nil"
  assert(
    string.match(value, expected_error),
    "Expected '" .. expected_error .. "' in error '" .. value .. "'"
  )

  print("Got expected error: " .. value)
  PASS = true

else

  local upower = value
  local GLib = require("lgi").GLib
  local ctx = GLib.MainLoop():get_context()

  assert(
    type(upower.Manager.OnBattery) == "boolean",
    "Upoer Manager should have an OnBattery property with boolean type"
  )

  local e_before = upower.display_device.Energy

  print("Running blocking iteration")
  ctx:iteration(true)           -- blocking iteration
  print("Done")

  local e_after = upower.display_device.Energy

  assert(
    e_before <= e_after,
    string.format("Energy before iteration (%s) should be same or lower than after iteration (%s)",
                  e_before,
                  e_after)
  )

  PASS = true
end

local result = PASS and "PASS" or "FAIL"

print("Test result: ".. result)

os.exit(PASS)
