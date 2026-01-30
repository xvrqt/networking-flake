{
  inputs = {
    # Used to set up Wireguard keys
    secrets.url = "git+https://git.irlqt.net/crow/secrets-flake";
    # My flake utils
    flake-utils = {
      #      url = "git+https://git.irlqt.net/crow/flake-utils";
      url = "github:xvrqt/flake-utils";
      flake = false;
    };

  };
  outputs =
    { flake-utils, secrets, ... }:
    let
      names = [ "lighthouse" "archive" "spark" "nyaa" "third-lobe" "tavern" ];
      cfg = import ./cfg.nix;

      # Keeping things DRY
      configureMachine = { lib, pkgs, name, config, ... }:
        let
          # Tools! I need my tools!
          utils = (import "${flake-utils}/default.nix" { inherit pkgs; });
        in
        {
          imports = [
            # Needs the secrets module to function since we will be deploying
            # Wireguard private keys on each machine
            secrets.nixosModules.default
            # Sets up the reverse proxy for hosts that need it
            # (if needs_proxy then websites.nixosModules.minimal else null)

            # General network settings that should be in effect across all devices
            (import ./general.nix { inherit cfg lib pkgs name utils config; })
            # Configure the Wireguard interface
            (import ./wireguard { inherit cfg lib name config; })
            # Configure the Tailnet
            (import ./tailscale { inherit lib cfg pkgs name utils config; })
            # Configure the Headscale coordination server on Lighthouse
            (import ./headscale { inherit cfg lib name utils config; })
            # Sets nameservers, and sets up DNS servers for certain machines
            (import ./dns { inherit cfg lib pkgs name utils config; })
            # Use Fail2Ban to help reduce malicious traffic
            (import ./fail2ban { inherit lib cfg name; })
          ];
        };
    in
    {
      # For each 'name' in 'names'
      # Create an attribute set key and, create a value for that key by calling
      # cfg() using that name as a parameter
      # e.g. {
      #   nyaa = { /* NixOS Module Config */ };
      #   spark = { /* NixOS Module Config */ };
      #   ...
      # }
      nixosModules = builtins.listToAttrs (
        map
          (item: {
            name = item;
            value = { pkgs, lib, config, ... }: configureMachine { inherit lib pkgs config; name = item; };
          })
          names
      );

      # Have this as an output so other flakes can configure themselves based
      # on the addresses/names in this file
      config = cfg;
    };
}
