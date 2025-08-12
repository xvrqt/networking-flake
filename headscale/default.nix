{ cfg, lib, name, config, ... }:
let
  dns = cfg.dns;
  machines = cfg.machines;
  # The machine this is running on
  machine = machines.${name};

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

  # Only enable this for the Lighthouse
  cfgCheck = (name == "lighthouse");
  # Only enable the reverse proxy if it's available
  reverse_proxy_present = config.services?websites && config.services.websites?enable;
in
if cfgCheck then {
  # Run a Headscale coordination server for all other nodes
  services = {
    headscale = {
      enable = true;
      inherit port address;

      settings = {
        # Where new clients can sign up
        server_url = "https://${gateway_subdomain}";

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
          # Use this machine as the DNS server (Blocky is also running here)
          # Use it over the Tailnet so that the DNS traffic is encrypted
          nameservers.global = dns.personal;
        };
      };
    };
    # Reverse Proxy
    nginx = lib.mkIf reverse_proxy_present {
      virtualHosts."${gateway_subdomain}" = {
        # Listen on the clear net, tailnet and wireguard interfaces
        listenAddresses = [
          machine.ip.v4.wg
          machine.ip.v4.www
        ];

        # HTTPS only
        forceSSL = true;
        acmeRoot = null;
        enableACME = true;

        # Pass back to the Headscale service
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.headscale.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    };
  };

  networking = {
    # Open ports to allow connection to the coordination server
    firewall = {
      allowedTCPPorts = [ config.services.headscale.port ];
      allowedUDPPorts = [ config.services.headscale.port ];
    };
  };

  # We can use the Headscale CLI tool to run commands
  environment.systemPackages = [ config.services.headscale.package ];
}
else { }
