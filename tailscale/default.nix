{ lib, cfg, pkgs, name, utils, config, ... }:
let
  # Grab the specific machine we're configuring
  machine = cfg.machines."${name}";

  # Shorthand to the irlqt-net options
  opt = config.networking.irlqt-net;

  # Setup exit node flags from options
  advertise-exit-node = if opt.advertiseExitNode then [ "--advertise-exit-node" ] else [ ];
  use-exit-node = if opt.exitNode != "" then [ "--exit-node=${opt.exitNode}" ] else [ ];
  extraSetFlags = advertise-exit-node ++ use-exit-node;

  # Check that the interface is even enabled
  cfgCheck = opt.enable;
in
{
  imports = [
    # Options to configure tailscale 
    (import ./options.nix { inherit lib cfg; })
  ];

  config = lib.mkIf cfgCheck {
    assertions = [
      {
        assertion = opt.advertiseExitNode -> opt.exitNode == "";
        message = "advertiseExitNode must be false if exitNode is set";
      }
    ];

    # Decrypts & Deploys the Authentik master secret
    age.secrets.tailscaleNewNodeKey = {
      # The secret file that will be decrypted
      file = ./secrets + ("/" + "new-node.key");
      # Folder to decrypt into (config.age.secretDir/'path')
      name = "tailnet/irlqt-net.key";

      # File Permissions
      mode = "400";
      owner = "root";

      # Symlink from the secretDir to the 'path'
      # Doesn't matter since both are in the same partition
      symlink = true;
    };

    # Configure the tailnet
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        interfaceName = cfg.tailscale.interface;
        useRoutingFeatures = machine.ts.routingFeatures;

        # Recompile for efficiency
        package = (utils.compileTimeHardening pkgs.tailscale);

        # Use a secret key to register as a new node if you haven't already
        authKeyFile = config.age.secrets.tailscaleNewNodeKey.path;
        authKeyParameters.baseURL = cfg.headscale.login_server;

        # Advertise exit node status or use an exit node
        inherit extraSetFlags;
      };
    };
  };
}
