{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    dbusProxyFlake = {
      url = "github:stefano-m/lua-dbus_proxy/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    enumFlake = {
      url = "github:stefano-m/lua-enum/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dbusProxyFlake, enumFlake }:
    let

      flakePkgs = import nixpkgs { overlays = [ self.overlays.default ]; inherit system; };
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
            flakePkgs.gobject-introspection
          ];

          buildInputs = [
            busted
            luacov
            ldoc
            luacheck
            flakePkgs.upower
            flakePkgs.dbus
          ];

          buildPhase = ":";

          installPhase = ''
            mkdir -p "$out/share/lua/${lua.luaversion}"
            cp -r src/${pname} "$out/share/lua/${lua.luaversion}/"
          '';

          doCheck = true;

          GI_TYPELIB_PATH = "${flakePkgs.lib.getLib flakePkgs.glib}/lib/girepository-1.0/";
          LUA_PATH = "$LUA_PATH;./src/?.lua;./src/?/init.lua";

          checkPhase = ''
            luacheck src
            lua -v
            lua ${./tests/simple_test.lua}
          '';

        };

    in
    {

      packages.${system} = rec {
        default = lua_upower_dbus;
        lua_upower_dbus = buildPackage flakePkgs.luaPackages;
        lua52_upower_dbus = buildPackage flakePkgs.lua52Packages;
        lua53_upower_dbus = buildPackage flakePkgs.lua53Packages;
      };

      devShells.${system}.default = flakePkgs.mkShell {
        LUA_PATH = "./src/?.lua;./src/?/init.lua";
        buildInputs = (with self.packages.${system}.default;
          buildInputs ++ propagatedBuildInputs) ++ (with flakePkgs;
          [ nixpkgs-fmt luarocks ]);
      };

      overlays.default = final: prev:
        let
          thisOverlay = this: previous: with self.packages.${system}; {
            luaPackages = previous.luaPackages // { upower_dbus = lua_upower_dbus; };
            lua52Packages = previous.lua52Packages // { upower_dbus = lua52_upower_dbus; };
            lua53Packages = previous.lua53Packages // { upower_dbus = lua53_upower_dbus; };
            luajitPackages = previous.luajitPackages // { upower_dbus = luajit_upower_dbus; };
          };
        in
        # expose the other lua overlays together with this one.
        (nixpkgs.lib.composeManyExtensions [ thisOverlay enumFlake.overlays.default dbusProxyFlake.overlays.default ]) final prev;

    };

}
