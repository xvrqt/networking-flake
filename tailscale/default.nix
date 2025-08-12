{ lib, cfg, name, ... }:
let
  # Grab the specific machine we're configuring
  machine = cfg.machines."${name}";

in
{
  services = {
    # All machines are part of the tailnet
    tailscale = {
      enable = true;
      openFirewall = true;
      interfaceName = cfg.tailscale.interface;
      useRoutingFeatures = machine.ts.routingFeatures;
    };
  };
}
