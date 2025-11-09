{ cfg, lib, ... }: {
  options = {
    networking = {
      irlqt-net = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Connect to the irlqt-net on this machine";
        };

        loginServer = lib.mkOption {
          type = lib.types.str;
          default = cfg.headscale.login_server;
          description = "Login server address to connect to the coordination plane";
        };

        advertiseExitNode = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Adds tag:exit which will allow other nodes to route their traffic to the clear-net through this node.";
        };

        exitNode = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "If this node should use an exit node";
        };

      };
    };
  };
}
