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
      # host disk images are put into packages
      # nixosConfigurations.*.config.system.build.image
      # because garnix.yml does not permit specifying these targets directly
      # and building on garnix is significantly better than github runners
      #
      # disk images will be built in a qemu virtual machine. the chosen system
      # (aarch64-linux) might have an impact on build speed, but qemu will fill
      # the gap (slower) if there is a missmatch
      aarch64-linux = blueprint.packages."aarch64-linux" // images;
    };
  };
}
