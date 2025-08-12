{ pka, port, machines, ... }:
[
  rec {
    name = "archive";
    endpoint = "${machines.${name}.ip.v4.www}:${toString port}";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
  rec {
    name = "nyaa";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
  rec {
    name = "spark";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
  rec {
    name = "third-lobe";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
]
