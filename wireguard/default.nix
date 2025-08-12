{ cfg, lib, name, config, ... }:
let
  # Wireguard interface name
  interface = cfg.wireguard.interface;
  # Which point endpoints should keep open for connection
  port = 16842;
  # Persistent Keep Alive timing in seconds
  pka = 25;

  # Grab the specific machine we're configuring
  machines = cfg.machines;
  machine = machines."${name}";

  # Decrypts & Deploys the WG Key
  deploySecret = name: {
    # The secret file that will be decrypted
    file = ./secrets + ("/" + "${name}.wg.key");
    # Folder to decrypt into (config.age.secretDir/'path')
    name = "wg/private.key";

    # File Permissions
    mode = "400";
    owner = "root";

    # Symlink from the secretDir to the 'path'
    # Doesn't matter since both are in the same partition
    symlink = true;
  };
in
{
  # Decrypt & Deploy the WG Key
  age.secrets.wgPrivateKey = deploySecret name;

  # If we are publicly available for other machines to connect to use, ensure
  # the Wireguard UDP port is open
  networking.firewall = lib.mkIf (machine.wg?endpoint) {
    allowedUDPPorts = [ port ];
  };

  # Setup the Wireguard Network Interface
  networking.wireguard.interfaces = {
    # Interface names are arbitrary
    "${interface}" = {
      # The machine's IP and the subnet (10.128.0.X/24) which the interface will capture and route traffic
      ips = [ "${machine.ip.v4.wg}/24" ];
      # Key that is used to encrypt traffic
      privateKeyFile = config.age.secrets.wgPrivateKey.path;
      # The port we're listening on if we're an endpoint
      listenPort = lib.mkIf (machine.wg?endpoint) port;
      # A list of peers to connect to, and allow connections to
      peers = (import (./. + "/${name}.nix") { inherit pka port machines; });
    };
  };
}
