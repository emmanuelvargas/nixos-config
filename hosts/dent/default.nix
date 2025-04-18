{ inputs, overlays, linuxOverlays, ... }:

let
	lib		= inputs.nixpkgs.lib;z
	system	= "x86_64-linux";
	# pkgs	= inputs.nixpkgs.legacyPackages.${system};
in
lib.nixosSystem {
	modules = [
		{
			nixpkgs.overlays = overlays ++ linuxOverlays ++ [
				# Patch DWL to enable adaptive sync
				(final: prev: {
					dwl-unwrapped = inputs.dwl-minego-customized.packages.${system}.dwl-unwrapped.overrideAttrs(old: {
						patches = [ ./dwl.patch ];
					});
				})
			];

			nix.registry.nixpkgs.flake			= inputs.nixpkgs;
			nix.nixPath							= [ "nixpkgs=${inputs.nixpkgs}" ];

			# Make a copy of the sources used to build the current running
			# system so it can be accessed as `/run/current-system/flake`
			system.extraSystemBuilderCmds = "ln -s ${../../.} $out/flake";

			# Enable networking, with DHCP and a bridge device
			networking.hostName						= "dent";
			networking.useDHCP						= false;

			# Setup a bridge to be used with libvirt
			networking.interfaces.enp42s0.useDHCP	= false;
			networking.interfaces.br0.useDHCP		= true;
			networking.bridges.br0.interfaces		= [ "enp42s0" ];

			boot.loader.efi.canTouchEfiVariables	= true;
			boot.kernelParams						= [ "video=DP-1:2560x1440@144" ];
			boot.tmp.useTmpfs						= true;

			# Rosetta for Linux
			boot.binfmt.emulatedSystems				= [ "aarch64-linux" ];

			imports = [
				../../users/m/linux.nix

				../../modules/common.nix
				../../modules/tailscale.nix
				../../modules/linux/common.nix
				../../modules/linux/gui.nix
				../../modules/linux/chromium.nix
				../../modules/linux/dwl.nix
				../../modules/linux/printer.nix
				../../modules/linux/8bitdo.nix
				../../modules/linux/interception-tools.nix
				../../modules/linux/libvirt.nix
				../../modules/linux/amdgpu.nix
				../../modules/linux/steam.nix
				../../modules/linux/builders.nix
				../../modules/linux/luks-ssh.nix
				../../modules/linux/syncthing.nix
				../../modules/services/glances.nix

				./hardware-configuration.nix
				inputs.home-manager.nixosModules.home-manager
			];

			# Make steam-gamescope handle my 4k display better
			programs.steam.gamescopeSession.args	= [ "-W" "3840" "-H" "2160" "-f" ];

			# Remote builders and binary cache
			builders.enable							= true;
			builders.cache							= true;
			builders.zaphod							= true;

			# Enable remote LUKS unlocking
			luks-ssh = {
				enable								= true;
				modules								= [ "r8169" ];
			};

			age.secrets = {
				chromium-sync-oauth = {
					file							= ../../secrets/chromium-sync-oauth.age;
					owner							= "root";
					group							= "users";
					mode							= "440";
				};
				mosquitto = {
					file							= ../../secrets/mosquitto.age;
					owner							= "root";
					group							= "users";
					mode							= "440";
				};
			};
		}

		inputs.agenix.nixosModules.default
	];
}
