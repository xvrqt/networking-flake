{
  services.fail2ban = {
    enable = true;
    # Ban IP after 5 failures
    maxretry = 5;

    # TODO make this flow from the cfg.nix
    ignoreIP = [
      # Allow List irlqt-net and amy-net
      "10.0.0.0/8"
      "100.64.0.0/10"
      # Allow local traffic
      "172.16.0.0/12"
      "192.168.0.0/16"
      # Upstream DNS
      "9.9.9.9"
    ];

    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      # One week maximum ban time
      maxtime = "168h";
      # Calculate bantime based on all the violations
      overalljails = true;
    };

    # Found at https://dataswamp.org/~solene/2022-10-02-nixos-fail2ban.html
    jails = {
      # max 6 failures in 600 seconds
      "nginx-spam" = ''
        enabled  = true
        filter   = nginx-bruteforce
        logpath = /var/log/nginx/access.log
        backend = auto
        maxretry = 6
        findtime = 600
      '';

      # max 3 failures in 600 seconds
      "postfix-bruteforce" = ''
        enabled = true
        filter = postfix-bruteforce
        findtime = 600
        maxretry = 3
      '';

    };

  };
  environment.etc = {
    "fail2ban/filter.d/nginx-bruteforce.conf".text = ''
      [Definition]
      failregex = ^<HOST>.*GET.*(matrix/server|\.php|admin|wp\-).* HTTP/\d.\d\" 404.*$
    '';

    "fail2ban/filter.d/postfix-bruteforce.conf".text = ''
      [Definition]
      failregex = warning: [\w\.\-]+\[<HOST>\]: SASL LOGIN authentication failed.*$
      journalmatch = _SYSTEMD_UNIT=postfix.service
    '';
  };
}

