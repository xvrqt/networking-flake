{ cfg, lib, pkgs, name, utils, config, ... }:
let
  dns = cfg.dns;

  # If this machine should also act as a DNS server
  is_nameserver = config.networking.dns.server.enable;
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
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
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
