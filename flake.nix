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

      flakePkgs = import nixpkgs { overlays = [ self.overlay ]; inherit system; };
      system = "x86_64-linux";
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

      packages.${system} = {
        lua_upower_dbus = buildPackage flakePkgs.luaPackages;
        lua52_upower_dbus = buildPackage flakePkgs.lua52Packages;
        lua53_upower_dbus = buildPackage flakePkgs.lua53Packages;
      };

      defaultPackage.${system} = self.packages.${system}.lua_upower_dbus;

      devShell.${system} = flakePkgs.mkShell {
        LUA_PATH = "./src/?.lua;./src/?/init.lua";
        buildInputs = (with self.defaultPackage.${system};
          buildInputs ++ propagatedBuildInputs) ++ (with flakePkgs;
          [ nixpkgs-fmt luarocks ]);
      };

      overlay = final: prev:
        let
          thisOverlay = this: previous: with self.packages.${system}; {
            luaPackages = previous.luaPackages // { upower_dbus = lua_upower_dbus; };
            lua52Packages = previous.lua52Packages // { upower_dbus = lua52_upower_dbus; };
            lua53Packages = previous.lua53Packages // { upower_dbus = lua53_upower_dbus; };
            luajitPackages = previous.luajitPackages // { upower_dbus = luajit_upower_dbus; };
          };
        in
        # expose the other lua overlays together with this one.
        (nixpkgs.lib.composeManyExtensions [ thisOverlay enumFlake.overlay dbusProxyFlake.overlay ]) final prev;

    };

}
