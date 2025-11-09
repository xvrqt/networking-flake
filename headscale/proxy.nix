{ cfg, lib, name, config, gateway_subdomain, ... }:
let
  # If we can use areverse proxy to access the headscale service
  reverse_proxy_present = config.services?websites && config.services.websites?enable;
  cfgCheck = config.networking.headscale.enable && reverse_proxy_present;

  machine = cfg.machines.${name};

in
{
  services.nginx.virtualHosts."${gateway_subdomain}" = lib.mkIf cfgCheck {
    # Listen on the clear net, tailnet and wireguard interfaces
    listenAddresses = [
      machine.ip.v4.wg
      machine.ip.v4.www
      machine.ip.v4.tailnet
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
}
