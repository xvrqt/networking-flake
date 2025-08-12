rec {
  headscale = {
    domain = "irlqt.net";
  };
  tailscale = {
    interface = "irlqt-net";
  };
  wireguard = {
    interface = "amy-net";
  };
  dns = {
    # DNS servers I control, over various interfaces
    personal = [
      machines.lighthouse.ip.v4.tailnet
      machines.archive.ip.v4.tailnet
      machines.archive.ip.v4.wg
      machines.lighthouse.ip.v4.wg
      machines.lighthouse.ip.v4.www
      machines.archive.ip.v4.www
    ];
    # Quad9 - to use as upstream nameservers
    quad9 = {
      ip = {
        v4 = [ "9.9.9.9" "149.112.112.112" ];
        v6 = [ "2620:fe::fe" "2620:fe::9" ];
      };
      https = [ "https://dns.quad9.net/dns-query" ];
      tls = [ "tcp-tls:dns.quad9.net" ];
    };

    # Machines which act as nameservers
    nameservers = [ "lighthouse" "archive" ];
  };
  machines = {
    # Wireguard
    lighthouse = {
      ip = {
        v4 = {
          www = "135.181.109.173";
          wg = "10.128.0.1";
          tailnet = "100.64.0.8";
        };
      };

      ts = {
        routingFeatures = "both";
      };

      wg = {
        endpoint = "lighthouse.machines.xvrqt.com";
        publicKey = "CZc/OcuvBGUGDSll32yIidvPZr4WWRpKhs/a/ccPuWA=";
      };

      git = "wg";
    };
    # Home Server
    archive = {
      ip = {
        v4 = {
          www = "136.27.49.66";
          wg = "10.128.0.2";
          tailnet = "100.64.0.3";
          local = "192.168.1.6";
        };
      };

      ts = {
        routingFeatures = "both";
      };

      wg = {
        endpoint = "archive.machines.xvrqt.com";
        publicKey = "SvnDMnuK8ZN+pED7rjhqhQUMq46cui/LrYurhfvHi2U=";
      };

      git = "tailnet";
    };
    # Apple M1 Ashai-Linux Lappy
    spark = {
      ip = {
        v4 = {
          wg = "10.128.0.3";
          tailnet = "100.64.0.2";
          local = "192.168.1.5";
        };
      };

      ts = {
        routingFeatures = "client";
      };

      wg = {
        publicKey = "paUrZfB470WVojQBL10kpL7+xUWZy6ByeTQzZ/qzv2A=";
      };

      git = "tailnet";
    };
    # Amy's Cell Phone (not managed by this flake)
    third-lobe = {
      ip = {
        v4 = {
          wg = "10.128.0.4";
          tailnet = "100.64.0.4";
          local = "192.168.1.10";
        };
      };
      ts = {
        routingFeatures = "client";
      };
      wg = {
        publicKey = "ma+LA7hdq9ayI26Ev0w0MyNFmSUNfBbsDU7+3/85Tis=";
      };
    };
    # Home Desktop
    nyaa = {
      ip = {
        v4 = {
          wg = "10.128.0.5";
          tailnet = "100.64.0.1";
          local = "192.168.1.4";
        };
      };
      ts = {
        routingFeatures = "client";
      };
      wg = {
        publicKey = "tHzr/Ej6G0qSX5mpn7U48ucdwk9TVuHZyxrDRfID50c=";
      };

      git = "tailnet";
    };
  };

}
