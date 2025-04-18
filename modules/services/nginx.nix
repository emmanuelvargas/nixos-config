{ config, pkgs, lib, ... }:
with lib;

{
	options.services.nginx = {
		hostname = lib.mkOption {
			type = lib.types.str;
		};

		sslCertificate = lib.mkOption {
			type = lib.types.str;
		};

		sslCertificateKey = lib.mkOption {
			type = lib.types.str;
		};
	};

	config = {
		services.nginx = rec {
			# Custom options, to be referenced in other parts of the config
			hostname				= "minego.net";
			sslCertificate			= "/var/lib/acme/${hostname}/fullchain.pem";
			sslCertificateKey		= "/var/lib/acme/${hostname}/key.pem";

			# Standard options
			enable					= true;

			recommendedProxySettings= true;
			recommendedTlsSettings	= true;
			recommendedGzipSettings	= true;

			virtualHosts."${hostname}" = {
				forceSSL			= true;
				default				= true;
				root				= "/var/www/${hostname}";

				locations."/" = {
				};

				locations."/.videos/Movies/" = {
					alias			= "/data/Movies/";
					extraConfig		= "autoindex on;";
				};

				locations."/.videos/TV/" = {
					alias			= "/data/TV/";
					extraConfig		= "autoindex on;";
				};

				serverAliases		= [
					"www.${hostname}"
					"micahgorrell.com"
					"www.micahgorrell.com"
				];

				sslCertificate		= sslCertificate;
				sslCertificateKey	= sslCertificateKey;
			};
		};

		security.acme = {
			acceptTerms			= true;
			defaults = {
				email			= "m@minego.net";
				credentialFiles	= {
					CLOUDFLARE_EMAIL_FILE	= config.age.secrets.hotblack-cloudflare-user.path;
					CLOUDFLARE_API_KEY_FILE	= config.age.secrets.hotblack-cloudflare-key.path;
				};
			};

			certs."${config.services.nginx.hostname}" = {
				domain			= "*.${config.services.nginx.hostname}";
				dnsProvider		= "cloudflare";
				group			= "nginx";
				extraDomainNames= [ "${config.services.nginx.hostname}" ];
			};
		};

		# Open ports
		networking.firewall.allowedTCPPorts = [ 80 443 ];
	};
}

