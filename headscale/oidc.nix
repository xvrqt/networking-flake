{ cfg, lib, config, ... }:
let
  # Only configure OIDC authentication if enabled
  cfgCheck = config.networking.headscale.enable && config.networking.headscale.useAuthServer;
in
{
  config = lib.mkIf cfgCheck {
    # Decrypts & Deploys the Authentik master secret
    age.secrets.oidcHeadscaleSecret = {
      # The secret file that will be decrypted
      file = ./secrets + ("/" + "oidc.key");
      # Folder to decrypt into (config.age.secretDir/'path')
      name = "authentik/headscale.key";

      # File Permissions
      mode = "400";
      owner = "headscale";

      # Symlink from the secretDir to the 'path'
      # Doesn't matter since both are in the same partition
      symlink = true;
    };

    services = {
      headscale = {
        settings = {
          # Optionally enable OIDC auth if we're running an auth server
          oidc = {
            issuer = "https://${cfg.auth.domain}/application/o/irlqt-net/";
            client_id = "KE9QwH2eHKLpFRTw93TbU24wZ2TpDdYLWPYJ1IQD";
            client_secret_path = config.age.secrets.oidcHeadscaleSecret.path;

            # Breaks if enabled
            pkce = {
              enabled = false;
            };
          };
        };
      };
    };
  };
}
