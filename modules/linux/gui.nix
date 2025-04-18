{ pkgs, config, lib, ... }:
with lib;

{
	imports = [
		./firefox.nix
		# ./chromium.nix
	];

	# Importing this module should automatically turn this option on
	config.gui.enable = mkForce true;

	config = {
		# This is required to use the lldb-vscode DAP to debug on Linux, and I
		# tend to need to do that on any system that is a "desktop" so that is
		# why I put this here.
		boot.kernel.sysctl."kernel.yama.ptrace_scope" = mkForce 0;

		environment.systemPackages = with pkgs; [
			# XDG Portals
			xdg-desktop-portal
			xdg-desktop-portal-wlr
			xdg-desktop-portal-gtk
			xdg-utils

			kitty

			pavucontrol
			pamixer
			freerdp
			tigervnc
			remmina
			sway-contrib.grimshot
		];

		programs.dconf.enable	= true;
		services.dbus.enable	= true;
		programs.light.enable	= true;

		fonts.packages = with pkgs; [
			nerdfonts
			noto-fonts
			noto-fonts-cjk
			noto-fonts-emoji
			liberation_ttf
			fira-code
			fira-code-symbols
			mplus-outline-fonts.githubRelease
			proggyfonts
			terminus_font

			monaspace
			sparklines
		];
		
		fonts.fontconfig.defaultFonts = {
			serif		= [ "Noto Serif" ];
			sansSerif	= [ "Monaspace Neon Light" "Noto Sans" ];
		};

		# This is needed for swaylock to work properly
		security.pam.services.swaylock = {};
		security.pam.loginLimits = [
			{ domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
		];

		# XDG Desktop Portal
		# TODO Find a way to do this through home-manager, since these options
		# will not be right for other window managers
		xdg.portal = {
			enable				= true;
			wlr.enable			= true;

			xdgOpenUsePortal	= false;

			config.common = {
				default			= [ "wlr" "gtk" ];
			};
		};

		boot.extraModulePackages = with config.boot.kernelPackages; [
			v4l2loopback
		];

		boot.extraModprobeConfig = "options v4l2loopback devices=1 video_nr=1 card_label=\"Virtual Cam\" exclusive_caps=1";
		security.polkit.enable = true;
	};

  services = {
      excludePackages = [ pkgs.xterm ];
    };

    gnome = {
      gnome-browser-connector.enable = false;
      gnome-initial-setup.enable = false;
      gnome-online-accounts.enable = false;
      gnome-remote-desktop.enable = false;
      rygel.enable = false;
    };

    udev.packages = [ pkgs.gnome-settings-daemon ];
  };

  programs.gnome-disks.enable = true;

  environment = {
    #sessionVariables.QT_QPA_PLATFORM = "wayland";

    systemPackages = [ pkgs.dconf-editor pkgs.networkmanager-openconnect ] ++ [
      pkgs.firefox # pkgs.epiphany
      pkgs.ghostty # pkgs.gnome-console
      pkgs.mission-center # pkgs.gnome-system-monitor

      pkgs.baobab
      pkgs.gnome-calculator
      pkgs.gnome-shell-extensions
      pkgs.loupe
      pkgs.snapshot
    ];

    gnome.excludePackages = [
      pkgs.adwaita-icon-theme
      pkgs.epiphany
      pkgs.evince
      pkgs.file-roller
      pkgs.geary
      pkgs.gnome-backgrounds
      pkgs.gnome-calendar
      pkgs.gnome-characters
      pkgs.gnome-clocks
      pkgs.gnome-connections
      pkgs.gnome-console
      pkgs.gnome-contacts
      pkgs.gnome-font-viewer
      pkgs.gnome-logs
      pkgs.gnome-maps
      pkgs.gnome-music
      pkgs.gnome-system-monitor
      pkgs.gnome-text-editor
      pkgs.gnome-themes-extra
      pkgs.gnome-tour
      pkgs.gnome-user-docs
      pkgs.gnome-weather
      pkgs.nautilus
      pkgs.orca
      pkgs.simple-scan
      pkgs.sushi
      pkgs.totem
      pkgs.yelp

      pkgs.baobab
      pkgs.gnome-calculator
      pkgs.gnome-shell-extensions
      pkgs.loupe
      pkgs.snapshot
    ];
  };
}

