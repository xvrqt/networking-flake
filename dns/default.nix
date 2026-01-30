{ cfg, lib, pkgs, name, utils, config, ... }:
let
  dns = cfg.dns;
  machines = cfg.machines;
  this_machine = machines.${name};

  # Where to serve DNS requests
  dnsPort = 53;
  httpPort = config.networking.dns.server.httpProxy.port;

  # Convenience variable to keep things DRY
  allBlockGroups = [ "ads" "suspicious" "tracking" "malicious" ];

  # If this machine should also act as a DNS server
  is_nameserver = config.networking.dns.server.enable;

  # Only allow requests made over secure interfaces
  wg_ip = "${cfg.machines."${name}".ip.v4.wg}:${toString dnsPort}";
  tailnet_ip = "${cfg.machines."${name}".ip.v4.tailnet}:${toString dnsPort}";
  local_ip = "127.0.0.1:${toString dnsPort}";
  blockyDNSPort = [ tailnet_ip wg_ip local_ip ];
in
{
  imports = [
    # Options to enable/disable running a headscale server
    (import ./options.nix { inherit cfg lib name config; })
    # Local DNS server configuration
    (import ./server { inherit cfg lib name config; })
    # Reverse proxy integration
    (import ./proxy.nix { inherit cfg lib name config; })
  ];

  # Setup which DNS servers to connect to
  config = {
    # For DNS debugging
    environment.systemPackages = map utils.optimizeForThisMachine [
      pkgs.dig
      pkgs.dnslookup
    ];

    networking = {
      # FYI machines using Tailscale will have /etc/resolvconf clobbered by
      # tailscaled, overwriting all these settings. Tailscaled might need DNS
      # setup for it to start, or in the off chance you're not using the irlqt-
      # net interface these are a good fallback.
      nameservers =
        # If you're running a DNS server then just use yourself 
        # TODO only add personal DNS servers based on available interfaces
        if is_nameserver then [ "127.0.0.1" "::1" ]
        else dns.personal ++ dns.quad9.ip.v4 ++ dns.quad9.ip.v6;

      # Open ports to allow connection to the DNS server
      firewall = lib.mkIf is_nameserver {
        allowedTCPPorts = [ dnsPort ];
        allowedUDPPorts = [ dnsPort ];
      };

      # If we're a nameserver, have resolvConf use Blocky the resolver
      # resolvconf = lib.mkIf is_nameserver {
      #   enable = true;
      #   useLocalResolver = true;
      # };
    };

    # Use systemd-resolved to handle system DNS requests
    # Unless we're running our own DNS locally
    services.resolved = lib.mkIf (is_nameserver == false) {
      enable = true;
      dnssec = "true";
      dnsovertls = "true";
      # Prevent fallback to plaintext resolvers
      fallbackDns = [ ];
      # Set global search domain; routes all queries through TLS.
      domains = [ "~." ];
    };

  };
}
