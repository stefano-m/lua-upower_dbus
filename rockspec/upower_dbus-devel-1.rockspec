package = "upower_dbus"
 version = "devel-1"
 source = {
    url = "git://github.com/stefano-m/lua-upower_dbus",
    tag = "master"
 }
 description = {
    summary = "Get power information with UPower and DBus",
    detailed = "Get power information with UPower and DBus",
    homepage = "https://github.com/stefano-m/lua-upower_dbus",
    license = "Apache v2.0"
 }
 dependencies = {
    "lua >= 5.1",
    "dbus_proxy"
 }
 supported_platforms = { "linux" }
 build = {
    type = "builtin",
    modules = { upower_dbus = "src/upower_dbus/init.lua" },
    copy_directories = { "docs" }
 }
