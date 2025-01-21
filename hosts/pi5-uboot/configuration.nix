{ config, flake, lib, modulesPath, pkgs, ... }: with lib; {
  imports = [
    flake.nixosModules.host-common

    flake.inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ];
  boot.pi-loader.bootMode = "uboot";
}
