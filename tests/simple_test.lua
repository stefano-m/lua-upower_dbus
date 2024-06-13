local string = string

print("Test STARTED")
print("Attempting to require upower_dbus")
local ok, value = pcall(require, "upower_dbus")

local expected_error = "Gio.DBusConnection expected, got nil"

if not ok then
    assert(
        string.match(value, expected_error),
        "Expected '" .. expected_error .. "' in error '" .. value .. "'"
    )

    print("Got expected error: " .. value)
    print("Test PASSED")
end
