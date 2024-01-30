{
  inputs = {
    nixpkgs.url = "nixpkgs/23.11";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils, ... }@inputs: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      our = {
        libgit2 = pkgs.libgit2.overrideAttrs (old: {
          src = builtins.fetchTarball {
            url = "https://github.com/romkatv/libgit2/archive/tag-2ecf33948a4df9ef45a66c68b8ef24a5e60eaac6.tar.gz";
            sha256 = "0b1a3zcrzay59f1axakmnszgv41bwjs7caj2pq6d9140vy7wcv86";
          };
          cmakeFlags = old.cmakeFlags ++ [
            "-DCMAKE_BUILD_TYPE=None"
            "-DZERO_NSEC=ON"
            "-DTHREADSAFE=ON"
            "-DUSE_BUNDLED_ZLIB=ON"
            "-DREGEX_BACKEND=builtin"
            "-DUSE_HTTP_PARSER=builtin"
            "-DUSE_SSH=OFF"
            "-DUSE_HTTPS=OFF"
            "-DBUILD_CLAR=OFF"
            "-DUSE_GSSAPI=OFF"
            "-DUSE_NTLMCLIENT=OFF"
          ];
        });
        gitstatus = pkgs.stdenv.mkDerivation {
          name = "gitstatusd";
          buildInputs = [ pkgs.zsh our.libgit2 ]  ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.libiconv ];
          buildPhase = ''
            zsh -c '
            for f in *.zsh install; do
              zcompile -R -- $f.zwc $f || exit;
            done
            ';

            mkdir usrbin
            APPNAME="$name"         \
            OBJDIR="$TEMP"/gitstatus    \
            make -j "$NIX_BUILD_CORES"
          '';
          installPhase = ''
            mkdir -p $out/usrbin/
            cp usrbin/"$name" "$out"/usrbin/
            cp gitstatus.plugin.* "$out"/
            cp gitstatus.prompt.* "$out"/
          '';
          src = ./.;
          inherit system;
        };
      };
    in {
      defaultPackage = our.gitstatus;
      devShell = pkgs.mkShell {
        inputsFrom = [our.gitstatus];
      };
    }
  );
}
