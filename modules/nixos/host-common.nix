{ config, flake, lib, modulesPath, pkgs, ... }: with lib; {
  imports = [
    "${toString modulesPath}/profiles/base.nix"

    flake.nixosModules.default
    # when copying this configuration, replace with:
    # flake.inputs.nix-pi-loader.nixosModules.default
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot.pi-loader = {
    enable = true;
  };

  system.build.image = (import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    format = "raw";
    partitionTableType = "efi";
    copyChannel = false;
    diskSize = "auto";
    additionalSpace = "64M";
    bootSize = "256M";
    touchEFIVars = false;
    installBootLoader = true;
    label = "nixos";
  });

  boot.consoleLogLevel = mkDefault 7;
  # The serial ports listed here are:
  # - ttyS0: for Tegra (Jetson TX1)
  # - ttyAMA0: for QEMU's -machine virt
  boot.kernelParams = ["console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/nixos";
      neededForBoot = true;
      autoResize = true;
      fsType = "ext4";
    };
  };

  boot.growPartition = true;

  nix.channel.enable = false;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  # this should get the 1GB RAM boards running
  # 512MB RAM boards have no hope atm, nixos-rebuild is too hungry
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "nixos";
    home = "/home/nixos";
    extraGroups = [ "wheel" "docker" "networkmanager" ];

    # "password"
    hashedPassword = "$y$j9T$XvLKdKPv9QozoQQVff4lw0$RB6USOrsMr/f3PHzj4fRRtxoHtDcd3zZtV1a1Zf5iG8";
  };
  users.groups.nixos = {
    gid = 1000;
  };

  services.openssh.enable = true;
}
