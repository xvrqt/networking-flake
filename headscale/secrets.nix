# Not imported, used by Agenix to encrypt secrets
let
  # Import our keys from our secrets-flake
  publicKeys = (builtins.getFlake "git+https://git.irlqt.net/crow/secrets-flake").publicKeys.machines;
in
{
  # The master secret for Authentik
  "secrets/oidc.key".publicKeys = [ publicKeys.lighthouse ];
}
