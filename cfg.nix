rec {
  auth = {
    domain = "auth.irlqt.net";
  };
  headscale = rec {
    domain = "irlqt.net";
    login_server = "https://connect.${domain}";
  };
  tailscale = {
    interface = "irlqt-net";
  };
  wireguard = {
    interface = "amy-net";
    subnet = "10.128.0.0";
    cidr = "9";
    port = "16842";
    pka = 25;
    ders = 15;
    derrs = 30;
  };
  dns = {
    domain = "dns.irlqt.net";
    # DNS servers I control, over various interfaces
    personal = [
      machines.lighthouse.ip.v4.tailnet
      machines.archive.ip.v4.tailnet
      machines.archive.ip.v4.wg
      machines.lighthouse.ip.v4.wg
    ];
    # Quad9 - to use as upstream nameservers
    quad9 = {
      v4 = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
      v6 = [
        "2620:fe::fe#dns.quad9.net"
        "2620:fe::9#dns.quad9.net"
      ];
    };

    # Machines which act as nameservers
    nameservers = [ "lighthouse" "archive" ];
  };
  machines =
    let
      # Generates a peer which has no endpoint and can only route to itself
      cfg_sub = name: cfg_peer name null [ "${machines."${name}".ip.v4.wg}/32" ];

      cfg_peer = name: net: allowedIPs: {
        inherit name allowedIPs;
        publicKey = machines."${name}".wg.publicKey;
        endpoint = if (net != null) then "${machines.${name}.ip.v4.${net}}:${wireguard.port}" else net;
        persistentKeepalive = wireguard.pka;
        dynamicEndpointRefreshSeconds = wireguard.ders;
        dynamicEndpointRefreshRestartSeconds = wireguard.derrs;
      };
    in
    {
      tavern = {
        ip = {
          v4 = {
            www = "157.90.167.33";
            wg = "10.128.0.3";
            tailnet = "100.64.0.7";
          };
          v6 = {
            www = "2a01:4f8:1c1a:71f9::/64";
          };
        };
        ts = {
          routingFeatures = "both";
        };
        wg = {
          endpoint = true;
          cidr = "32";
          publicKey = "rwY4sfhDSGyoFtEbolDTFqYTswcqU5UE2P3w8E9oZRk=";
          peers = [
            (cfg_sub "archive")
            (cfg_peer "lighthouse" "www" [ "${machines.lighthouse.ip.v4.wg}/32" ])
            (cfg_sub "nyaa")
            (cfg_sub "spark")
            (cfg_sub "thirdlobe")
          ];
        };
        git = "tailnet";
        fail2ban = true;
      };
      # Wireguard
      lighthouse = {
        ip = {
          v4 = {
            www = "135.181.109.173";
            wg = "10.128.0.1";
            tailnet = "100.64.0.1";
          };
          v6 = {
            www = "2a01:4f9:c013:a37d::/64";
          };
        };

        ts = {
          routingFeatures = "both";
        };

        wg = {
          endpoint = true;
          cidr = "24";
          publicKey = "CZc/OcuvBGUGDSll32yIidvPZr4WWRpKhs/a/ccPuWA=";
          peers = [
            (cfg_sub "archive")
            (cfg_peer "tavern" "www" [ "${machines.tavern.ip.v4.wg}/32" ])
            (cfg_sub "nyaa")
            (cfg_sub "spark")
            (cfg_sub "thirdlobe")
          ];

        };

        git = "wg";
        fail2ban = true;
      };
      # Home Server
      archive = {
        ip = {
          v4 = {
            www = "136.27.49.66";
            wg = "10.128.0.2";
            tailnet = "100.64.0.2";
            local = "192.168.1.6";
          };
        };

        ts = {
          routingFeatures = "both";
        };

        wg = {
          endpoint = true;
          publicKey = "SvnDMnuK8ZN+pED7rjhqhQUMq46cui/LrYurhfvHi2U=";
          peers = [
            (cfg_peer
              "nyaa"
              "local"
              [ "${machines.nyaa.ip.v4.wg}/32" ])
            (cfg_peer
              "tavern"
              "www"
              [ "${machines.tavern.ip.v4.wg}/32" ])
            (cfg_peer
              "lighthouse"
              "www"
              [ "10.128.0.0/31" "10.128.0.2/32" "10.128.0.5/32" "10.128.0.6/31" "10.128.0.8/29" "10.128.0.16/28" "10.128.0.32/27" "10.128.0.64/26" "10.128.0.128/25" ])
          ];
        };

        git = "tailnet";
        fail2ban = true;
      };
      # Apple M1 Ashai-Linux Lappy
      spark = {
        ip = {
          v4 = {
            wg = "10.128.0.5";
            tailnet = "100.64.0.8";
            local = "192.168.1.5";
          };
        };

        ts = {
          routingFeatures = "client";
        };

        wg = {
          publicKey = "paUrZfB470WVojQBL10kpL7+xUWZy6ByeTQzZ/qzv2A=";
          peers = [
            (cfg_peer
              "tavern"
              "www"
              [ "${machines.tavern.ip.v4.wg}/32" ])
            (cfg_peer
              "lighthouse"
              "www"
              # 10.128.0.0\24 except for the tavern
              [ "10.128.0.0/31" "10.128.0.2/32" "10.128.0.4/30" "10.128.0.8/29" "10.128.0.16/28" "10.128.0.32/27" "10.128.0.64/26" "10.128.0.128/25" ])
          ];
        };

        git = "tailnet";
        fail2ban = false;
      };
      # Amy's Cell Phone (not managed by this flake)
      thirdlobe = {
        ip = {
          v4 = {
            wg = "10.128.0.6";
            tailnet = "100.64.0.4";
            local = "192.168.1.10";
          };
        };
        ts = {
          routingFeatures = "client";
        };
        wg = {
          publicKey = "ma+LA7hdq9ayI26Ev0w0MyNFmSUNfBbsDU7+3/85Tis=";
          peers = [
            (cfg_peer
              "tavern"
              "www"
              [ "${machines.tavern.ip.v4.wg}/32" ])
            (cfg_peer
              "lighthouse"
              "www"
              # 10.128.0.0\24 except for the tavern
              [ "10.128.0.0/31" "10.128.0.2/32" "10.128.0.4/30" "10.128.0.8/29" "10.128.0.16/28" "10.128.0.32/27" "10.128.0.64/26" "10.128.0.128/25" ])
          ];
        };
      };
      # Home Desktop
      nyaa = {
        ip = {
          v4 = {
            wg = "10.128.0.4";
            tailnet = "100.64.0.3";
            local = "192.168.1.6";
          };
        };
        ts = {
          routingFeatures = "client";
        };
        wg = {
          publicKey = "tHzr/Ej6G0qSX5mpn7U48ucdwk9TVuHZyxrDRfID50c=";
          endpoint = true;
          peers = [
            (cfg_peer
              "archive"
              "local"
              [ "${machines.archive.ip.v4.wg}/32" ])
            (cfg_peer
              "tavern"
              "www"
              [ "${machines.tavern.ip.v4.wg}/32" ])
            (cfg_peer
              "lighthouse"
              "www"
              # 10.128.0.0/24 except for tavern and archive
              [ "10.128.0.0/31" "10.128.0.4/30" "10.128.0.8/29" "10.128.0.16/28" "10.128.0.32/27" "10.128.0.64/26" "10.128.0.128/25" ])
          ];
        };

        git = "tailnet";
        fail2ban = false;
      };
    };

}
