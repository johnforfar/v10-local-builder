{ lib, ... }:

{
  # V10 Skill Set for NixOS Hardware & Environment
  skills.v10-hardware = {
    description = "Core skills for V10 Studio: Hardware drivers, MicroVM orchestration, and system-level NixOS configuration.";
    
    actions = {
      enable-usb = {
        description = "Inject USB device rules into the target NixOS configuration.";
        params = {
          vendorId = "String: hex vendor id";
          productId = "String: hex product id";
        };
        template = ''
          services.udev.extraRules = "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"''${vendorId}\", ATTR{idProduct}==\"''${productId}\", MODE=\"0666\"";
        '';
      };

      setup-vfkit-vm = {
        description = "Configure microvm.nix to use the vfkit hypervisor for macOS M1 local preview.";
        template = ''
          microvm.hypervisor = "vfkit";
          microvm.shares = [{
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/store";
          }];
        '';
      };

      configure-x11-wayland = {
        description = "Enable desktop environment for hardware app preview.";
        template = ''
          services.xserver.enable = true;
          services.xserver.displayManager.gdm.enable = true;
          services.xserver.desktopManager.gnome.enable = true;
        '';
      };

      setup-web-preview = {
        description = "Configure the MicroVM for headless browser-based preview via noVNC.";
        template = ''
          # Headless Wayland (Cage is a minimal kiosk compositor)
          services.cage.enable = true;
          services.cage.user = "admin";
          
          # VNC Server (WayVNC for Wayland)
          systemd.services.wayvnc = {
            description = "VNC Server for Web Preview";
            after = [ "display-manager.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "''${pkgs.wayvnc}/bin/wayvnc 0.0.0.0";
              Restart = "always";
            };
          };
          
          networking.firewall.allowedTCPPorts = [ 5900 ];
        '';
      };
    };
  };
}
