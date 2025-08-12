{ pka, port, machines, ... }:
[
  rec {
    name = "lighthouse";
    endpoint = "${machines.${name}.ip.v4.www}:${toString port}";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
  rec {
    name = "nyaa";
    endpoint = "${machines.${name}.ip.v4.local}:${toString port}";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
  rec {
    name = "archive";
    endpoint = "${machines.${name}.ip.v4.www}:${toString port}";
    publicKey = "${machines.${name}.wg.publicKey}";
    allowedIPs = [ "${machines.${name}.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  }
]
