{
  description = "ytm-rs flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (
      system: let
        pkgs = import nixpkgs {inherit system;};

        # Libraries the prebuilt binary links against (see `ldd ./ytm-rs`) plus the
        # tray appindicator, which is loaded at run time and so invisible to ldd.
        runtimeLibs = with pkgs; [
          webkitgtk_4_1
          libsoup_3
          gtk3
          gdk-pixbuf
          cairo
          pango
          atk
          harfbuzz
          glib
          dbus
          openssl
          alsa-lib
          libayatana-appindicator
          stdenv.cc.cc.lib
        ];

        ytm-rs = pkgs.stdenv.mkDerivation {
          pname = "ytm-rs";
          version = "0.3.4";

          src = pkgs.fetchzip {
            url = "https://github.com/grapedjuice/ytm-rs/releases/download/v0.3.4/ytm-rs-portable-0.3.4-linux-x86_64.tar.gz";
            hash = "sha256-AjKrNDZUcA1dCxh4zKOi1kRxT+E/ZEft24H5MTtHbig=";
          };

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            wrapGAppsHook3
            copyDesktopItems
          ];

          buildInputs = runtimeLibs;

          # Prebuilt ELF: nothing to compile.
          dontConfigure = true;
          dontBuild = true;
          dontStrip = true;

          installPhase = ''
            runHook preInstall

            install -Dm755 ytm-rs $out/bin/ytm-rs
            install -Dm644 ytm-rs.png $out/share/icons/hicolor/256x256/apps/ytm-rs.png

            runHook postInstall
          '';

          # Point the menu entry at the store path so it works without `ytm-rs` on PATH.
          # Runs after the copyDesktopItems hook has installed the file.
          postFixup = ''
            substituteInPlace $out/share/applications/ytm-rs.desktop \
              --replace-fail "Exec=ytm-rs" "Exec=$out/bin/ytm-rs"
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "ytm-rs";
              exec = "ytm-rs %U";
              icon = "ytm-rs";
              desktopName = "YT Music";
              genericName = "Music Player";
              comment = "Native YouTube Music client";
              categories = [
                "AudioVideo"
                "Audio"
                "Player"
              ];
              keywords = [
                "youtube"
                "music"
                "player"
              ];
              startupWMClass = "ytm-rs";
              terminal = false;
            })
          ];

          meta = with pkgs.lib; {
            description = "Native YouTube Music client";
            homepage = "https://github.com/grapedjuice/ytm-rs";
            license = licenses.gpl3Only;
            platforms = ["x86_64-linux"];
            mainProgram = "ytm-rs";
          };
        };

        app = {
          type = "app";
          program = "${ytm-rs}/bin/ytm-rs";
          meta = {
            inherit
              (ytm-rs.meta)
              description
              homepage
              license
              platforms
              mainProgram
              ;
          };
        };
      in {
        packages.default = ytm-rs;
        packages.ytm-rs = ytm-rs;

        apps.default = app;
        apps.ytm-rs = app;

        devShells.default = pkgs.mkShell {
          buildInputs = runtimeLibs ++ (with pkgs; [gdb]);
        };

        formatter = pkgs.nixfmt;
      }
    );
}
