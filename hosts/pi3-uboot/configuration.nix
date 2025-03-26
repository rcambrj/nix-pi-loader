{ config, flake, lib, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ../../helpers/host-common.nix

    flake.inputs.nixos-hardware.nixosModules.raspberry-pi-3
  ];
  boot.pi-loader.bootMode = "uboot";
}
