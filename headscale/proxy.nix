{ cfg, lib, name, config, gateway_subdomain, ... }:
let
  # If we can use areverse proxy to access the headscale service
  reverse_proxy_present = config.services?websites && config.services.websites?enable;
  cfgCheck = config.networking.headscale.enable && reverse_proxy_present;

  machine = cfg.machines.${name};

in
{
  # If we are also on the irlqt-net, we need to allow NGINX to bind to IP
  # addresses which may not have been instantiated yet.
  # e.g. tailscale needs to connect to 'gateway.irlqt.net' but can't
  # because NGINX won't start because it can't bind the address to to the
  # irlqt-net
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = lib.mkIf cfgCheck 1;
  boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = lib.mkIf cfgCheck 1;

  services.nginx.virtualHosts."${gateway_subdomain}" = lib.mkIf cfgCheck {
    # Listen on the clear net, tailnet and wireguard interfaces
    listenAddresses = [
      machine.ip.v4.wg
      machine.ip.v4.www
      # machine.ip.v4.tailnet
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
