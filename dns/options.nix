{ cfg, lib, name, config, ... }:
let
  # Check if we even have a reverse proxy with auto HTTPS certificate config available.
  # Enable DNS over HTTPS proxy if possible
  reverse_proxy_present = config.services?websites && config.services.websites?enable;
  httpProxyCfgCheck = reverse_proxy_present && config.networking.dns.server.enable;
in
{
  options = {
    networking = {
      dns = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use custom DNS config from this flake";
        };

        server = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = (name == "lighthouse" || name == "archive");
            description = "Run a local DNS server.";
          };

          settings = {
            httpProxy = {
              enable = lib.mkOption {
                enable = lib.types.bool;
                default = httpProxyCfgCheck;
                description = "Runs a reverse proxy at \"dns.irlqt.net\" which allows for encrypted DNS requests over HTTPS.\n This is sort of pointless because we never run open resolvers anyways, and all traffic to the DNS would be over an encrypted interface anyways.";
              };
              port = lib.mkOption {
                enable = lib.types.int;
                default = 5300;
                description = "The port the local DNS is expecting HTTP traffic on.\ne.g. 127.0.0.1:5300";
              };
            };
          };
        };
      };
    };
  };
}
