{ cfg, lib, pkgs, name, ... }:
let
  dns = cfg.dns;
  machines = cfg.machines;
  this_machine = machines.${name};

  # Where to serve DNS requests
  dnsPort = 53;
  httpPort = 5300;

  # Convenience variable to keep things DRY
  allBlockGroups = [ "ads" "suspicious" "tracking" "malicious" ];

  # If this machine should also act as a DNS server
  is_nameserver = builtins.elem name cfg.dns.nameservers;

  # Only allow requests made over secure interfaces
  wg_ip = "${cfg.machines."${name}".ip.v4.wg}:${toString dnsPort}";
  tailnet_ip = "${cfg.machines."${name}".ip.v4.tailnet}:${toString dnsPort}";
  local_ip = "127.0.0.1:${toString dnsPort}";
  blockyDNSPort = [ tailnet_ip wg_ip local_ip ];
in
{
  networking = {
    # All the machines should be using DNS through the Tailnet
    # If they don't for some reason, try these as fallbacks
    nameservers =
      # If you're running a DNS server then just use yourself 
      if is_nameserver then ([ "127.0.0.1" ] ++ dns.quad9.ip.v4 ++ dns.quad9.ip.v6)
      else dns.personal ++ dns.quad9.ip.v4 ++ dns.quad9.ip.v6;

    # Open ports to allow connection to the DNS server
    firewall = lib.mkIf is_nameserver {
      allowedTCPPorts = [ dnsPort ];
      allowedUDPPorts = [ dnsPort ];
    };

    # If we're a nameserver, have resolvConf use Blocky the resolver
    resolvconf = lib.mkIf is_nameserver {
      enable = true;
      useLocalResolver = true;
    };
  };

  # Act as a DNS server
  systemd.services.blocky = lib.mkIf is_nameserver {
    after = [ "tailscaled.service" "network-online.target" ];
    requires = [ "tailscaled.service" ];
  };

  services = lib.mkIf is_nameserver {
    # Reverse proxy so people outside the irlqt-net can use the DNS without
    # leaking their requests
    nginx.virtualHosts."dns.irlqt.net" = {
      forceSSL = true;
      enableACME = true;
      acmeRoot = null;
      # Only allow internal people to use this endpoint
      listenAddresses = [ "10.128.0.1" ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:${(builtins.toString httpPort)}";
        proxyWebsockets = false;
        recommendedProxySettings = true;
      };
    };

    blocky = {
      enable = true;

      settings = {
        # ports.dns = dnsPort;
        ports.dns = [ "${this_machine.ip.v4.tailnet}:53" "${this_machine.ip.v4.wg}:53" "127.0.0.1:53" "[::1]:53" ];
        # ports.dns = "127.0.0.1:53";
        ports.http = httpPort;

        # network.listen = [
        #   "100.64.0.1:53"
        #   "10.128.0.1:53"
        # ];

        caching = {
          minTime = "5m";
          maxTime = "60m";
          prefetching = true;
          prefetchExpires = "2h";
          prefetchThreshold = 5;
        };

        # Where to look up records if you don't have them
        upstreams = {
          groups = {
            # default = dns.quad9.tls ++ dns.quad9.https;
            default = dns.quad9.gay;
          };
          timeout = "3s";
          strategy = "parallel_best";
          init.strategy = "fast";
        };

        # Used to lookup and resolve domain names used in the upstreams list
        # Using Quad1 and Google to distribute risk they all go down
        bootstrapDns = {
          ips = [ "1.1.1.1" "8.8.8.8" ];
          upstream = "https://one.one.one.one/dns-query";
        };

        # This is where you can register domains on the Dorkweb
        customDNS = {
          mapping =
            let
              self = machines."${name}".ip.v4.tailnet;
              tavern = machines.tavern.ip.v4.tailnet;
              archive = machines.archive.ip.v4.tailnet;
              lighthouse = machines.lighthouse.ip.v4.tailnet;
            in
            {
              # DNS over HTTPS service
              # Points the the machine running this DNS service
              "dns.irlqt.net" = self;

              # Services hosted by the Lighthouse (this node)
              "irlqt.net" = machines.tavern.ip.v4.www;
              "mail.irlqt.net" = tavern;
              "email.irlqt.net" = tavern;
              "ldap.irlqt.net" = lighthouse;
              "connect.irlqt.net" = machines.lighthouse.ip.v4.www;

              # Services Hosted by the Archive
              "git.irlqt.net" = archive;
              "irc.irlqt.net" = tavern;
              "immich.irlqt.net" = archive;
              "irlqt.me" = archive;
              "jellyseerr.irlqt.net" = archive;
              "jellyfin.irlqt.net" = archive;
              "nzbget.irlqt.net" = archive;
              "prowlarr.irlqt.net" = archive;
              "radarr.irlqt.net" = archive;
              "lidarr.irlqt.net" = archive;
              "navidrome.irlqt.net" = archive;
              "search.irlqt.net" = archive;
              "sonarr.irlqt.net" = archive;
              "torrents.irlqt.net" = archive;
              "wiki.irlqt.net" = archive;
              "plex.irlqt.net" = archive;
              "slsk.irlqt.net" = archive;
              "auth.irlqt.net" = machines.lighthouse.ip.v4.www;

              "immich.public.irlqt.net" = archive;
              "public.immich.irlqt.net" = archive;
              "public.monero.nodes.archive.irlqt.net" = archive;

              "copyparty.irlqt.net" = archive;
              "social.irlqt.net" = tavern;
            };
        };

        blocking = {
          denylists = {
            ads = [
              "https://adaway.org/hosts.txt"
              "https://v.firebog.net/hosts/AdguardDNS.txt"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://v.firebog.net/hosts/Admiral.txt"
              "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
              "https://v.firebog.net/hosts/Easylist.txt"
              "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
              "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
            ];

            suspicious = [
              "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
              "https://v.firebog.net/hosts/static/w3kbl.txt"
            ];

            tracking = [
              "https://v.firebog.net/hosts/Easyprivacy.txt"
              "https://v.firebog.net/hosts/Prigent-Ads.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
              "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
              "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
            ];

            malicious = [
              "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
              "https://v.firebog.net/hosts/Prigent-Crypto.txt"
              "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
              "https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
              "https://phishing.army/download/phishing_army_blocklist_extended.txt"
              "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
              "https://v.firebog.net/hosts/RPiList-Malware.txt"
              "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
              "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
              "https://urlhaus.abuse.ch/downloads/hostfile/"
              "https://lists.cyberhost.uk/malware.txt"
            ];
          };

          # Block everything for everyone by default
          clientGroupsBlock = {
            default = allBlockGroups;
          };
        };
      };
    };
  };

  # For DNS debugging
  environment.systemPackages = [
    pkgs.dig
    pkgs.dnslookup
  ];
}
