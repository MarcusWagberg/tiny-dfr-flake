{ 
  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/staging-next";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };

  in {
    packages.x86_64-linux.tiny-dfr = pkgs.rustPlatform.buildRustPackage rec {
      pname = "tiny-dfr";
      version = "8a5d413cb1dbe2a25b77a9e7f3cb5b9c88ef3ffb";
      
      src = pkgs.fetchFromGitHub {
        owner = "kekrby";
        repo = "tiny-dfr";
        rev = "${version}";
        hash = "sha256-l4D7aePz/CYpkRorrvsgIYrvSzoZl59OGcFGJqqJftk=";
      };
    
      cargoLock.lockFile = "${src}/Cargo.lock";
    
      nativeBuildInputs = with pkgs; [
        pkg-config
      ];
    
      buildInputs = with pkgs; [
      	udev
      	glib
      	pango
      	cairo
      	gdk-pixbuf
      	libxml2
      	libinput
      ];

      postPatch = ''
        substituteInPlace src/main.rs --replace "/usr/share/tiny-dfr/" "$out/share/tiny-dfr/"
      '';

      postInstall = ''
        mkdir -p $out/etc $out/share
        
        cp -r etc/udev $out/etc/
        cp -r share/tiny-dfr $out/share/
      '';
      
      meta = with pkgs.lib; {
        description = "The most basic dynamic function row daemon possible";
        homepage = "https://github.com/WhatAmISupposedToPutHere/tiny-dfr";
        license = with licenses; [ asl20 bsd3 cc0 isc lgpl21Plus mit mpl20 unicode-dfs-2016 asl20 asl20-llvm mit unlicense ];
        maintainers = [];
      };
    };
    
    packages.x86_64-linux.default = self.packages.x86_64-linux.tiny-dfr;

    module = ({config, pkgs, ...}:{
      config.services.udev.packages = [ self.packages.x86_64-linux.tiny-dfr ];
      config.systemd.services.tiny-dfr = {
      	enable = true;
      	description = "Tiny Apple silicon touch bar daemon";
      	after = [ "systemd-user-sessions.service" "getty@tty1.service" "plymouth-quit.service" "systemd-logind.service" ];
      	bindsTo = [ "dev-tiny_dfr_display.device" "dev-tiny_dfr_backlight.device" ];
      	startLimitIntervalSec = 30;
      	startLimitBurst = 2;
      	script = "${self.packages.x86_64-linux.tiny-dfr}/bin/tiny-dfr";
      	restartTriggers = [ self.packages.x86_64-linux.tiny-dfr ];
      };
      config.environment.etc."tiny-dfr/config.toml" = {
      	source = "${self.packages.x86_64-linux.tiny-dfr}/share/tiny-dfr/config.toml";
      };
    });
    
  };
}
