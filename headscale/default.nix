{ cfg, lib, name, utils, config, ... }:
let
  # If headscale should be installed
  cfgCheck = config.networking.headscale.enable;

  # Where to serve from, and which addresses to accept
  port = 8080;
  address = "0.0.0.0";

  # Basedomain
  domain = cfg.headscale.domain;
  # Where new clients can register
  gateway_subdomain = "gateway.${domain}";
  # MagicDNS will assign every machine a URL using this scheme
  # It cannot overlap with the gateway
  machines_subdomain = "machines.${domain}";

in
{
  imports = [
    # Options to enable/disable running a headscale server
    (import ./options.nix { inherit cfg lib name config; })
    # OIDC integration settings
    (import ./oidc.nix { inherit cfg lib config; })
    # Reverse proxy integration
    (import ./proxy.nix { inherit cfg lib name config gateway_subdomain; })
  ];

  config = lib.mkIf cfgCheck {
    # Open ports to allow connection to the coordination server
    networking = {
      firewall = {
        allowedTCPPorts = [ config.services.headscale.port ];
        allowedUDPPorts = [ config.services.headscale.port ];
      };
    };

    # Run a Headscale coordination server for all other nodes
    services = {
      headscale = {
        enable = true;
        inherit port address;

        settings = {
          # Where new clients can sign up
          server_url = "http://${gateway_subdomain}";

          # This is what the developers recommend and what they test on
          # PostGres seems heavy for such a simple VPS 
          database.type = "sqlite";

          # Access control of routes and resources
          policy = {
            mode = "file";
            path = ./acl.json;
          };

          dns = {
            # Headscale will automatically assign every machine a domain name
            # using the scheme <name>.<base_domain> and keep it updated
            magic_dns = true;
            base_domain = machines_subdomain;

            # Since this is the base domain all services will be hosted on
            search_domains = [ domain ];
            # Use our personal DNS servers for this network
            nameservers.global = cfg.dns.personal;
          };
        };
      };
    };

    # We can use the Headscale CLI tool to run commands
    environment.systemPackages = [ (utils.optimizeForThisMachine config.services.headscale.package) ];
  };
}
