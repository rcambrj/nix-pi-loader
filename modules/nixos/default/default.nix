#
# this file is ~heavily inspired~ shamelessly hoisted from:
# https://github.com/NixOS/nixpkgs/blob/794d005bdd26af909ecbe6e4fc618f14518d4df4/nixos/modules/installer/sd-card/sd-image-aarch64.nix
#
{ config, lib, pkgs, ... }: with lib; let
  cfg = config.boot.pi-loader;
in {
  imports = [
    ../generic-extlinux-compatible
  ];

  options.boot.pi-loader = {
    enable = mkEnableOption ''
      Enable Raspberry Pi config.txt and firmware configuration.

      Recommended additional configuration:

      ```
      # github:NixOS/nixos-hardware
      imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-3 ];
      environment.systemPackages = [ pkgs.libraspberrypi ];
      nixpkgs.hostPlatform = "aarch64-linux";
      ```

      To deploy the files to their location again, run `NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild switch|boot`
    '';
    firmwareDir = mkOption {
      description = "The path where config.txt and all the files get copied to";
      type = types.str;
      default = "/boot";
    };
    configTxt = mkOption {
      type = types.attrs;
      default = {
        pi3 = {
          kernel = "u-boot-rpi3.bin";
        };
        pi02 = {
          kernel = "u-boot-rpi3.bin";
        };
        pi4 = {
          kernel = "u-boot-rpi4.bin";
          enable_gic = 1;
          armstub = "armstub8-gic.bin";

          # Otherwise the resolution will be weird in most cases, compared to
          # what the pi3 firmware does by default.
          disable_overscan = 1;

          # Supported in newer board revisions
          arm_boost = 1;
        };
        cm4 = {
          # Enable host mode on the 2711 built-in XHCI USB controller.
          # This line should be removed if the legacy DWC2 controller is required
          # (e.g. for USB device mode) or if USB support is not required.
          otg_mode = 1;
        };
        all = {
          # Boot in 64-bit mode.
          arm_64bit = 1;

          # U-Boot needs this to work, regardless of whether UART is actually used or not.
          # Look in arch/arm/mach-bcm283x/Kconfig in the U-Boot tree to see if this is still
          # a requirement in the future.
          enable_uart = 1;

          # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
          # when attempting to show low-voltage or overtemperature warnings.
          avoid_warnings = 1;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    boot.loader.generic-extlinux-compatible.enable = false;
    boot.loader.generic-extlinux-compatible-pi-loader.enable = true;
    boot.loader.generic-extlinux-compatible-pi-loader.extraCommandsAfter = let
      atomicCopy = import ./atomic-copy.nix { inherit pkgs; };
      configTxt = (pkgs.formats.ini {}).generate "config.txt" cfg.configTxt;
      setupRaspiBoot = pkgs.writeShellScript "cp-pi-loaders.sh" ''
        # Add generic files
        cd ${pkgs.raspberrypifw}/share/raspberrypi/boot
        ${atomicCopy} bootcode.bin ${cfg.firmwareDir}/bootcode.bin
        ${pkgs.findutils}/bin/find . -type f -name 'fixup*.dat' -exec ${atomicCopy} {} ${cfg.firmwareDir}/{} \;
        ${pkgs.findutils}/bin/find . -type f -name 'start*.elf' -exec ${atomicCopy} {} ${cfg.firmwareDir}/{} \;

        # Add the config
        ${atomicCopy} ${configTxt} ${cfg.firmwareDir}/config.txt

        # Add pi3 specific files
        ${atomicCopy} ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin                            ${cfg.firmwareDir}/u-boot-rpi3.bin
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-2-b.dtb      ${cfg.firmwareDir}/bcm2710-rpi-2-b.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-3-b.dtb      ${cfg.firmwareDir}/bcm2710-rpi-3-b.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-3-b-plus.dtb ${cfg.firmwareDir}/bcm2710-rpi-3-b-plus.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-cm3.dtb      ${cfg.firmwareDir}/bcm2710-rpi-cm3.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-zero-2.dtb   ${cfg.firmwareDir}/bcm2710-rpi-zero-2.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-zero-2-w.dtb ${cfg.firmwareDir}/bcm2710-rpi-zero-2-w.dtb

        # Add pi4 specific files
        ${atomicCopy} ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin                        ${cfg.firmwareDir}/u-boot-rpi4.bin
        ${atomicCopy} ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin                     ${cfg.firmwareDir}/armstub8-gic.bin
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb  ${cfg.firmwareDir}/bcm2711-rpi-4-b.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-400.dtb  ${cfg.firmwareDir}/bcm2711-rpi-400.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4.dtb  ${cfg.firmwareDir}/bcm2711-rpi-cm4.dtb
        ${atomicCopy} ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4s.dtb ${cfg.firmwareDir}/bcm2711-rpi-cm4s.dtb
      '';
    in [ (toString setupRaspiBoot) ];
  };
}