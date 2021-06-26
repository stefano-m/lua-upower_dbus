{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    dbusProxyFlake = {
      url = "github:stefano-m/lua-dbus_proxy/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    enumFlake = {
      url = "github:stefano-m/lua-enum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dbusProxyFlake, enumFlake }:
    let
      flakePkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          self.overlay
          enumFlake.overlay
          dbusProxyFlake.overlay
        ];
      };

      currentVersion = builtins.readFile ./VERSION;

      buildPackage = luaPackages: with luaPackages;
        buildLuaPackage rec {
          name = "${pname}-${version}";
          pname = "upower_dbus";
          version = "${currentVersion}-${self.shortRev or "dev"}";

          src = ./.;

          propagatedBuildInputs = [
            dbus_proxy
            enum
          ];

          buildInputs = [
            busted
            luacov
            ldoc
            luacheck
            flakePkgs.upower
            flakePkgs.dbus_tools
          ];

          buildPhase = ":";

          installPhase = ''
            mkdir -p "$out/share/lua/${lua.luaversion}"
            cp -r src/${pname} "$out/share/lua/${lua.luaversion}/"
          '';

          doCheck = true;
          checkPhase = ''
            luacheck src
            LUA_PATH="$LUA_PATH;./src/?.lua;./src/?/init.lua"
            export LUA_PATH
            lua -v
            lua -l "lgi"
            lua -l "enum"
            lua -l "dbus_proxy"
            # lua -l "upower_dbus" # fails because it can't find upower
          '';

        };

    in
    {

      packages.x86_64-linux = {
        lua_upower_dbus = buildPackage flakePkgs.luaPackages;
        lua52_upower_dbus = buildPackage flakePkgs.lua52Packages;
        lua53_upower_dbus = buildPackage flakePkgs.lua53Packages;
        luajit_upower_dbus = buildPackage flakePkgs.luajitPackages;
      };

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.lua_upower_dbus;

      devShell.x86_64-linux = flakePkgs.mkShell {
        LUA_PATH = "./src/?.lua;./src/?/init.lua";
        buildInputs = (with self.defaultPackage.x86_64-linux; buildInputs ++ propagatedBuildInputs) ++ (with flakePkgs; [
          nixpkgs-fmt
          luarocks
        ]);
      };

      overlay = final: prev: with self.packages.x86_64-linux; {
        # TODO: combine with, maybe with lib.extends?
        # enumFlake.overlay
        # dbusProxyFlake.overlay
        luaPackages = prev.luaPackages // {
          upower_dbus = lua_upower_dbus;
        };

        lua52Packages = prev.lua52Packages // {
          upower_dbus = lua52_upower_dbus;
        };

        lua53Packages = prev.lua53Packages // {
          upower_dbus = lua53_upower_dbus;
        };

        luajitPackages = prev.luajitPackages // {
          upower_dbus = luajit_upower_dbus;
        };

      };

    };

}
