{ cfg, lib, name, config, ... }:
let
  # List of domains to return NOLOOKUP
  blocks = import ./blocks.nix;
  # Custom DNS entires (domain key, IP a ddr value)
  entries = (import ./entries.nix { inherit cfg name; });

  # If this machine should also act as a DNS server
  is_nameserver = config.networking.dns.server.enable;

  # Setup for this machine
  machines = cfg.machines;
  this_machine = machines.${name};
in
{
  config = lib.mkIf is_nameserver {

    # TODO test if irlqt net is even running
    systemd.services.blocky = {
      after = [ "tailscaled.service" "network-online.target" ];
      requires = [ "tailscaled.service" ];
    };

    services = {
      # Ensure we're not running resolved by default
      resolved.enable = lib.mkForce false;

      # Setup Blocky as our local DNS
      blocky = {
        enable = true;

        settings = {
          # TODO make this bind to interfaces dynamically
          ports = {
            # Which interfaces to bind to and ports to listen on 
            dns = [ "${this_machine.ip.v4.tailnet}:53" "${this_machine.ip.v4.wg}:53" "127.0.0.1:53" "[::1]:53" ];
            tls = 853;
            # We can use this in conjunction with our NGINX reverse proxy
            http = config.networking.dns.server.settings.httpProxy.port;
            https = 4453;
          };

          # Upstreams have this already, if we try to do it too it may cause
          # resolution failures
          # dnssec = false;

          caching = {
            minTime = "5m";
            maxTime = "60m";
            # Queries which are requested more than 5 times will have their
            # cached value renewed before it expires.
            prefetching = true;
            prefetchExpires = "2h";
            prefetchThreshold = 5;
          };

          # Where to look up records if you don't have them
          upstreams = {
            groups.default = [
              "https://dns.adguard-dns.com/dns-query"
              # "tls://dns.adguard-dns.com"
              # "https://freedns.controld.com/p0"
              # "tls://p0.freedns.controld.com"
              "https://doh.mullvad.net/dns-query"
              # "tls://doh.mullvad.net"
              # "tls://dns.quad9.net:853"
            ];

            # Make two queries and use whichever returns first
            # Consider queries to have failed after 3s
            timeout = "3s";
            strategy = "parallel_best";
            init.strategy = "fast";
          };

          # Used to lookup and resolve domain names used in the upstreams list
          bootstrapDns = [
            "tcp+udp:9.9.9.9:53"
          ];

          # Custom DNS entries
          # customDNS.mapping = entries;
          customDNS.mapping = entries;

          # List of lists of domains to return NOLOOKUP when requested
          blocking = {
            denylists = with blocks;
              { inherit ads suspicious malicious tracking; };
            # Block everything for everyone by default
            clientGroupsBlock = {
              default = [ "ads" "suspicious" "malicious" "tracking" ];
            };
          };
        };
      };
    };
  };
}
