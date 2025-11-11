# Not imported, used by Agenix to encrypt secrets
let
  # Import our keys from our secrets-flake
  publicKeys = builtins.attrValues ((builtins.getFlake "/key/fuck/secrets-flake").publicKeys.machines);
  # publicKeys = builtins.attrValues ((builtins.getFlake "git+https://git.irlqt.net/crow/secrets-flake").publicKeys.machines);
in
{
  # All machines can access the pre-auth key which allows them to conect
  "secrets/new-node.key".publicKeys = publicKeys;
}
