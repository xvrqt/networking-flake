# Not imported, used by Agenix to encrypt secrets
let
  # Import our keys from our secrets-flake
  publicKeys = (builtins.getFlake "git+https://git.irlqt.net/crow/secrets-flake").publicKeys;
in
{
  # Archive's Wireguard private key, only accessible to itself
  "secrets/archive.wg.key".publicKeys = [ publicKeys.machines.archive ];
  # Spark's Wireguard private key, only accessible to itself
  "secrets/spark.wg.key".publicKeys = [ publicKeys.machines.spark ];
  # Nyaa's Wireguard private key, only accessible to itself
  "secrets/nyaa.wg.key".publicKeys = [ publicKeys.machines.nyaa ];
  # The Lighthouse's Wireguard private key, only accessible to itself
  "secrets/lighthouse.wg.key".publicKeys = [ publicKeys.machines.lighthouse ];
}
