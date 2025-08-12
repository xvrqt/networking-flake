{
  inputs = {
    # Used to set up Wireguard keys
    secrets.url = "git+https://git.irlqt.net/crow/secrets-flake";
  };
  outputs =
    { secrets, ... }:
    let
      names = [ "lighthouse" "archive" "spark" "nyaa" "third-lobe" ];
      cfg = import ./cfg.nix;

      # Keeping things DRY
      configureMachine = { lib, pkgs, name, config, ... }:
        {
          imports = [
            # Needs the secrets module to function since we will be deploying
            # Wireguard private keys on each machine
            secrets.nixosModules.default
            # Sets up the reverse proxy for hosts that need it
            # (if needs_proxy then websites.nixosModules.minimal else null)

            # General network settings that should be in effect across all devices
            (import ./general.nix { inherit cfg pkgs name; })
            # Configure the Wireguard interface
            (import ./wireguard { inherit cfg lib name config; })
            # Configure the Tailnet
            (import ./tailscale { inherit lib cfg name; })
            # Configure the Headscale coordination server on Lighthouse
            (import ./headscale { inherit cfg lib name config; })
            # Sets nameservers, and sets up DNS servers for certain machines
            (import ./dns { inherit cfg lib pkgs name; })
            # Use Fail2Ban to help reduce malicious traffic
            (import ./fail2ban)
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
