{ cfg, lib, name, config, ... }: {
  options = {
    networking = {
      headscale = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = (name == "lighthouse");
          description = "Install headscale on the machine";
        };

        useAuthServer = lib.mkOption {
          type = lib.types.bool;
          default = (config.services.authentik.enable);
          description = "Use OIDC authentication with an authentik server";
        };
      };
    };
  };
}
