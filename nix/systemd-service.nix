{ config, pkgs, lib, ... }:
let
  cfg = config.services.v10-app-display;
  # In a real scenario, the app would be built from the flake inputs
  # and passed here. For now, we assume a generic package.
  v10-app = pkgs.writeShellScriptBin "v10-app-server" ''
    ${pkgs.python3}/bin/python -m http.server 3005 --directory ${cfg.projectDir}
  '';
in {
  options.services.v10-app-display = {
    enable = lib.mkEnableOption "V10 Native App Display Service";
    projectDir = lib.mkOption {
      type = lib.types.path;
      description = "Path to the vibecoded project directory";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3005;
      description = "Port to serve the app on";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.v10-app-display = {
      description = "V10 Vibecoded App (Method 1: Native)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe v10-app}";
        
        # Method 1 Hardening (As recommended in the hierarchy)
        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        CapabilityBoundingSet = "";
        
        # Restrict network access to localhost if desired, 
        # or leave open if the gateway proxies to it.
        # PrivateNetwork = true; # Only if using a bridge
      };
    };

    # Open firewall if not using a reverse proxy
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
