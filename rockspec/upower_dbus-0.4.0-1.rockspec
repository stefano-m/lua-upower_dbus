package = "upower_dbus"
version = "0.4.0-1"
source = {
   url = "git://github.com/stefano-m/lua-upower_dbus",
   tag = "v0.4.0"
}
description = {
   summary = "Get power information with UPower and DBus",
   detailed = "Get power information with UPower and DBus",
   homepage = "git+https://github.com/stefano-m/lua-upower_dbus",
   license = "Apache v2.0"
}
supported_platforms = {
   "linux"
}
dependencies = {
   "lua >= 5.1",
   "dbus_proxy",
   "enum"
}
build = {
   type = "builtin",
   modules = {
      upower_dbus = "src/upower_dbus/init.lua"
   },
   copy_directories = {
      "docs"
   }
}
