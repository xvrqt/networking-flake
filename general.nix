{ cfg, lib, pkgs, name, utils, config, ... }: {

  options = {
    networking = {
      installTools = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install useful network tools";
      };
    };
  };

  config = {
    # Networking
    networking = {
      # Give the machine a proper name
      hostName = name;
      firewall = {
        enable = true;
        # Allow SSH Traffic
        allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [ 22 ];
        # Allow any traffic on the wireguard and tailnet interfaces
        trustedInterfaces = [ cfg.tailscale.interface cfg.wireguard.interface ];
      };
    };

    # Useful networking tools
    environment.systemPackages = lib.mkIf config.networking.installTools [
      (utils.optimizeForThisMachine pkgs.nmap)
      (utils.optimizeForThisMachine pkgs.trippy)
      (utils.optimizeForThisMachine pkgs.ethtool)
      (utils.optimizeForThisMachine pkgs.nettools)
      (utils.optimizeForThisMachine pkgs.iproute2)
      (utils.optimizeForThisMachine pkgs.traceroute)
    ];
  };
}
