{ cfg, name, ... }:
let
  # Convienence
  machines = cfg.machines;
  self = machines."${name}".ip.v4.tailnet;
  tavern = machines.tavern.ip.v4.tailnet;
  archive = machines.archive.ip.v4.tailnet;
  lighthouse = machines.lighthouse.ip.v4.tailnet;
in
{
  # DNS over HTTPS service
  # Points the the machine running this DNS service
  "dns.irlqt.net" = self;

  #############
  # CLEAR NET #
  #############
  # Services *anyone* can access
  # Authentik Login
  "auth.irlqt.net" = machines.lighthouse.ip.v4.www;
  # Tailscale Coordination Server
  "connect.irlqt.net" = machines.lighthouse.ip.v4.www;
  # Public sharing of Immich photos
  "immich.public.irlqt.net" = machines.archive.ip.v4.www;
  # Sharkey instance
  "irlqt.net" = machines.tavern.ip.v4.www;

  #############
  # IRLQT-NET #
  #############
  # Services only available on the IRLQT-NET
  "copyparty.irlqt.net" = archive;
  "git.irlqt.net" = archive;
  "immich.irlqt.net" = archive;
  "jellyfin.irlqt.net" = archive;
  "jellyseerr.irlqt.net" = archive;
  "lidarr.irlqt.net" = archive;
  "nzbget.irlqt.net" = archive;
  "plex.irlqt.net" = archive;
  "prowlarr.irlqt.net" = archive;
  "public.monero.nodes.archive.irlqt.net" = archive;
  "radarr.irlqt.net" = archive;
  "search.irlqt.net" = archive;
  "sonarr.irlqt.net" = archive;
  "torrents.irlqt.net" = archive;
  "wiki.irlqt.net" = archive;

  "email.irlqt.net" = tavern;
  "mail.irlqt.net" = tavern;

  # Deprecated
  "irc.irlqt.net" = tavern;
  "irlqt.me" = archive;
  "ldap.irlqt.net" = lighthouse;
  "navidrome.irlqt.net" = archive;
  "public.immich.irlqt.net" = archive;
  "slsk.irlqt.net" = archive;
  "social.irlqt.net" = tavern;
}
