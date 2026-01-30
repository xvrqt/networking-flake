{ cfg, lib, name, config, ... }:
let
  # If the reverse proxy is setup, and a DNS server is setup and the user wants
  # an HTTPS Reverse Proxy
  reverse_proxy_present = config.services?websites && config.services.websites?enable;
  httpProxyCfgCheck = config.networking.dns.server.enable;
  cfgCheck = config.networking.dns.server.enable && reverse_proxy_present && httpProxyCfgCheck;

  # The port the local DNS server is listening on
  httpPort = config.networking.dns.server.httpProxy.port;

  machine = cfg.machines.${name};
in
{
  # Reverse proxy so people outside the irlqt-net can use the DNS without
  # leaking their requests
  nginx.virtualHosts."${cfg.dns.domain}" = lib.mkIf cfgCheck {
    forceSSL = true;
    acmeRoot = null;
    enableACME = true;

    # Only allow internal people to use this endpoint
    # TODO update this based on what networks this machine is connected to
    # Also if it allows clear net open resolver etc.
    listenAddresses = [ "10.128.0.1" "100.64.0.1" ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${(builtins.toString httpPort)}";
      proxyWebsockets = false;
      recommendedProxySettings = true;
    };
  };
}
