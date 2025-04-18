{ pkgs, lib, inputs, ... }:
with lib;

{
	options = {
		me = mkOption {
			description		= "Details about my default user";

			default = {
				user		= "manu";
				fullName	= "Emmanuel Vargas";
				email		= "manu@crapules.com";
			};
		};

		# This option exists so that my homebrew config can tell if the gui
		# module was enabled. It should NOT be enabled directly in a host's
		# config though.
		#
		# Instead, it should be on by default for Darwin since that always has
		# a gui enabled, and it should be turned on for Linux by importing
		# `modules/linux/gui.nix` which will set this option.
		gui.enable = lib.mkEnableOption {
			description		= "GUI";
			default			= if pkgs.stdenv.isDarwin then true else false;
		};
	};

	options.authorizedKeys.keys = mkOption {
		description	= ''
            A list of trusted ssh keys that should be used trusted by the
            default user (m) and a handful of other things such as remote
            LUKS unlocking, and remote nix builders.
            '';

		default = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEG9sbnm7GF7LQ/csbk729YUlu89TSY2mLDmla/tgKGc emmanuel.vargas@gmail.com"
		];
	};

	imports = [
		./zsh.nix
	];

	config = {
		time.timeZone = lib.mkDefault "Europe/Paris";

		# Enable the nix command and flakes
		nix.settings.experimental-features = [ "nix-command" "flakes" "repl-flake" ];

		# Allow unfree packages
		nixpkgs.config.allowUnfree = true;

		environment.shellAliases = {
			vi				= "nvim";
			t				= "todo.sh";
			todo			= "todo.sh";
		};

		environment.variables = {
			KEYTIMEOUT		= "1";
			VISUAL			= "nvim";
			EDITOR			= "nvim";
			SUDO_EDITOR		= "nvim";
			LC_CTYPE		= "C";
		};

		# List packages installed in system profile. To search, run:
		# $ nix search wget
		environment.systemPackages = with pkgs; [
			neovim

			agenix
			home-manager
			nvd

			pciutils
			lsof
			file

			gnumake
			dtach
			direnv

			curl
			httpie
			stow
			man-pages
			man-pages-posix
			kitty.terminfo

			nix-output-monitor
			asciinema

			(pkgs.writeShellScriptBin "todo.sh" ''
				export TODOTXT_CFG_FILE=${writeText "config" ""}
                export TODO_DIR="$HOME/notes/"
                export TODO_FILE="$TODO_DIR/todo.txt"
                export DONE_FILE="$TODO_DIR/done.txt"
                export REPORT_FILE="$TODO_DIR/report.txt"
                exec ${pkgs.todo-txt-cli}/bin/todo.sh $@
                '')

			(pkgs.writeShellScriptBin "," ''
				package=$1
				shift

				nix run nixpkgs#$package -- $@
				'')


			(pkgs.writeScriptBin "nixos-repl" ''
                #!/usr/bin/env ${pkgs.expect}/bin/expect
                set timeout 120
                spawn -noecho nix --extra-experimental-features repl-flake repl nixpkgs
                expect "nix-repl> " {
                send ":a builtins\n"
                send "pkgs = legacyPackages.${system}\n"
                interact
                }
                '')

		];

		home-manager = {
			useGlobalPkgs		= true;
			useUserPackages		= true;

			extraSpecialArgs	= { inherit inputs; };
		};

		system.activationScripts.diff = {
			supportsDryActivation = true;
			text = ''
                ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
                /run/current-system "$systemConfig"
                '';
		};
	};
}
