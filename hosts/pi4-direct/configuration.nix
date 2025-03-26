{ config, flake, lib, modulesPath, pkgs, ... }: with lib; {
  imports = [
    ../../helpers/host-common.nix

    flake.inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];
  boot.pi-loader.bootMode = "direct";
}
