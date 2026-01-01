{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.nix-cache-proxy;
  upstreamArgs = lib.concatMapStringsSep " " (u: "--upstream ${u}") cfg.upstreams;
in
{
  options.services.nix-cache-proxy = {
    enable = lib.mkEnableOption "proxy for Nix binary cache requests";
    package = lib.mkOption {
      description = "Package for Nix Cache Proxy";
      type = lib.types.package;
      default = pkgs.nix-cache-proxy;
    };
    listenAddress = lib.mkOption {
      description = "Listen address";
      type = lib.types.str;
      default = "127.0.0.1:8080";
      example = ''
        127.0.0.1:8080
        [::1]:8080
        unix:/run/nix-cache-proxy/nix-cache-proxy.sock
      '';
    };
    setNixSubstituter = lib.mkOption {
      description = "Set Nix daemon's substituter to Nix Cache Proxy. Only supports IPv4/IPv6 listener.";
      type = lib.types.bool;
      default = true;
    };
    upstreams = lib.mkOption {
      description = "Upstream cache URLs";
      type = lib.types.listOf lib.types.str;
      default = [
        "https://cache.nixos.org"
      ];
    };
    timeoutSecs = lib.mkOption {
      description = "Request timeout in seconds";
      type = lib.types.int;
      default = 5;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nix-cache-proxy = {
      description = "Nix Cache Proxy";
      after = [ "network.target" ];
      requires = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${lib.getExe cfg.package} --bind ${cfg.listenAddress} ${upstreamArgs} --timeout-secs ${toString cfg.timeoutSecs}";

        User = "nix-cache-proxy";
        Group = "nix-cache-proxy";

        # Hardening
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [
          "@system-service"
          "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @swap"
        ];
      };
    };

    nix.settings = lib.mkIf cfg.setNixSubstituter {
      substituters = lib.mkForce [ "http://${cfg.listenAddress}" ];
    };

    users.users.nix-cache-proxy = {
      group = "nix-cache-proxy";
      isSystemUser = true;
    };
    users.groups.nix-cache-proxy = { };
  };
}
