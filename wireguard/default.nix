{ cfg, lib, name, config, ... }:
let
  # Which point endpoints should keep open for connection
  port = 16842;
  # Persistent Keep Alive timing in seconds
  pka = 25;

  # Grab the specific machine we're configuring
  machines = cfg.machines;
  machine = machines."${name}";

  cfgCheck = config.networking.amy-net.enable;

  # Remove ourselves from our peers
  machine_list = lib.attrsets.mapAttrsToList (name: value: value // { inherit name; }) machines;
  peer_list = builtins.filter (machine: machine.name != name) machine_list;
  # Function which creates a peer entry for each peer machine
  create_peer_attrset = machine: {
    name = machine.name;
    publicKey = "${machine.wg.publicKey}";
    endpoint = lib.mkIf (machine?endpoint) machine.ip.v4.www;
    allowedIPs = [ "${machine.ip.v4.wg}/32" ];
    persistentKeepalive = pka;
  };
  # A list of peer attribute sets
  peers = map create_peer_attrset peer_list;
in
{
  options = {
    networking = {
      amy-net = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Create Wireguard interface 'amy-net' which connects all my machines.";
        };

      };
    };
  };

  config = lib.mkIf cfgCheck {
    # Decrypt & Deploy the WG Key
    age.secrets.wgPrivateKey = {

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

    # If we are publicly available for other machines to connect to use, ensure
    # the Wireguard UDP port is open
    networking.firewall = lib.mkIf (machine.wg?endpoint) {
      allowedUDPPorts = [ port ];
    };

    # Setup the Wireguard Network Interface
    networking.wireguard.interfaces = {
      # Interface names are arbitrary
      "${cfg.wireguard.interface}" = {
        # The machine's IP and the subnet (10.128.0.X/24) which the interface will capture and route traffic
        ips = [ "${machine.ip.v4.wg}/24" ];
        # Key that is used to encrypt traffic
        privateKeyFile = config.age.secrets.wgPrivateKey.path;
        # The port we're listening on if we're an endpoint
        listenPort = lib.mkIf (machine.wg?endpoint) port;
        # A list of peers to connect to, and allow connections to
        inherit peers;
      };
    };
  };
}

