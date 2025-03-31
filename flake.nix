{
  description = "A module to make booting your NixOS configuration possible on a Raspberry Pi";

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs?ref=7cf092925906d588daabc696d663c100f2bbacc6";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint
  outputs = inputs:
  with builtins;
  with inputs.nixpkgs.lib;
  let
    blueprint = inputs.blueprint { inherit inputs; };

    optionalImage = hostConfig: if (
      (hasAttr "config" hostConfig) &&
      (hasAttr "system" hostConfig.config) &&
      (hasAttr "build"  hostConfig.config.system) &&
      (hasAttr "image"  hostConfig.config.system.build)
    ) then hostConfig.config.system.build.image else false;
    imagesAndFalses = mapAttrs
      (hostName: hostConfig: optionalImage hostConfig)
      blueprint.nixosConfigurations;
    images = filterAttrs
      (hostName: hostImage: hostImage != false)
      imagesAndFalses;
  in
  blueprint // {
    packages = blueprint.packages // {
      # this system doesn't impact the target system of the hosts
      x86_64-linux = blueprint.packages."x86_64-linux" // images;
    };
  };
}
