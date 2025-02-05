#
# this file is ~heavily inspired~ shamelessly hoisted from:
# https://github.com/NixOS/nixpkgs/blob/794d005bdd26af909ecbe6e4fc618f14518d4df4/nixos/modules/installer/sd-card/sd-image-aarch64.nix
#
{ config, lib, pkgs, ... }: with lib; let
  cfg = config.boot.pi-loader;

  # used for direct-to-kernel boot only: emulate cleanName()
  # https://github.com/NixOS/nixpkgs/blob/904ecf0b4e055dc465f5ae6574be2af8cc25dec3/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.sh#L47
  kernelStorePath = "${config.system.build.kernel}/${config.system.boot.loader.kernelFile}";
  initrdStorePath = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
  kernelBootPath = "nixos/${builtins.replaceStrings [ "/nix/store/" "/" ] [ "" "-" ] kernelStorePath}";
  initrdBootPath = "nixos/${builtins.replaceStrings [ "/nix/store/" "/" ] [ "" "-" ] initrdStorePath}";
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
    bootMode = mkOption {
      description = "Select whether to boot direct to kernel or use uboot. Direct to kernel will not allow generation selection";
      type = types.enum [ "uboot" "direct" ];
      default = "uboot";
    };
    rootPartition = mkOption {
      description = "Kernel parameter (`root=`) used only for direct to kernel boot to identify the root partition.";
      default = "LABEL=nixos";
    };
    configTxt = mkOption {
      type = types.attrs;
      default = {
        # https://www.raspberrypi.com/documentation/computers/config_txt.html#model-filters
        pi3 = {
          direct = {
            kernel = kernelBootPath;
            ramfsfile = initrdBootPath;
            ramfsaddr = -1;
          };
          uboot = {
            kernel = "u-boot-rpi3.bin";
          };
        }.${cfg.bootMode};
        pi02 = {
          direct = {
            kernel = kernelBootPath;
            ramfsfile = initrdBootPath;
            ramfsaddr = -1;
          };
          uboot = {
            kernel = "u-boot-rpi3.bin";
          };
        }.${cfg.bootMode};
        pi4 = {
            # Otherwise the resolution will be weird in most cases, compared to
            # what the pi3 firmware does by default.
            disable_overscan = 1;

            # Supported in newer board revisions
            arm_boost = 1;
        } // ({
          direct = {
            kernel = kernelBootPath;
            ramfsfile = initrdBootPath;
            ramfsaddr = -1;
          };
          uboot = {
            kernel = "u-boot-rpi4.bin";
            enable_gic = 1;
            armstub = "armstub8-gic.bin";
          };
        }.${cfg.bootMode});
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
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = false;
    boot.loader.generic-extlinux-compatible-pi-loader.enable = true;
    boot.kernelParams = [
      # todo
    ] ++ ({
      direct = [
          "root=${cfg.rootPartition}"
          "rootfstype=ext4"
          "rootwait"
          "init=/nix/var/nix/profiles/system/init"
      ];
      uboot = [];
    }.${cfg.bootMode});
    boot.loader.generic-extlinux-compatible-pi-loader.extraCommandsAfter = let
      atomicCopySafe = import ../atomic-copy-safe { inherit pkgs; };
      atomicCopyClobber = import ../atomic-copy-clobber { inherit pkgs; };
      configTxt = (pkgs.formats.ini {}).generate "config.txt" cfg.configTxt;
      cmdLineTxt = pkgs.writeTextFile {
        name = "cmdline.txt";
        text = ''
          ${lib.strings.concatStringsSep " " config.boot.kernelParams}
        '';
      };
      setupRaspiBoot = pkgs.writeShellScript "cp-pi-loaders.sh" (''
          # Add generic files
          cd ${pkgs.raspberrypifw}/share/raspberrypi/boot
          ${atomicCopySafe} bootcode.bin                                                     ${cfg.firmwareDir}/bootcode.bin
          ${atomicCopySafe} overlays                                                         ${cfg.firmwareDir}/overlays
          ${pkgs.findutils}/bin/find . -type f -name 'fixup*.dat' -exec ${atomicCopySafe} {} ${cfg.firmwareDir}/{} \;
          ${pkgs.findutils}/bin/find . -type f -name 'start*.elf' -exec ${atomicCopySafe} {} ${cfg.firmwareDir}/{} \;
          ${pkgs.findutils}/bin/find . -type f -name '*.dtb'      -exec ${atomicCopySafe} {} ${cfg.firmwareDir}/{} \;

          # Add pi3 specific files
          ${atomicCopySafe} ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin                       ${cfg.firmwareDir}/u-boot-rpi3.bin

          # Add pi4 specific files
          ${atomicCopySafe} ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin                       ${cfg.firmwareDir}/u-boot-rpi4.bin
          ${atomicCopySafe} ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin                    ${cfg.firmwareDir}/armstub8-gic.bin

          # Add config.txt
          ${atomicCopyClobber} ${configTxt}                                                  ${cfg.firmwareDir}/config.txt
        '' + {
          direct = ''
            # Add cmdline.txt
            ${atomicCopyClobber} ${cmdLineTxt}                                                 ${cfg.firmwareDir}/cmdline.txt
          '';
          uboot = "";
        }.${cfg.bootMode}
      );
    in [ (toString setupRaspiBoot) ];
  };
}