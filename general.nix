{ cfg, pkgs, name, ... }: {
  # Networking
  networking = {
    # Give the machine a proper name
    hostName = name;
    firewall = {
      enable = true;
      # Allow SSH Traffic
      allowedTCPPorts = [ 22 80 443 16842 ];
      allowedUDPPorts = [ 22 80 443 16842 ];
      trustedInterfaces = [ cfg.tailscale.interface cfg.wireguard.interface ];
    };
  };

  # Useful networking tools
  environment.systemPackages = [
    pkgs.nmap
    pkgs.trippy
    pkgs.ethtool
    pkgs.nettools
    pkgs.iproute2
    pkgs.traceroute
  ];
}
