#
# this file exists to make garnix build and cache all of the:
# nixosConfigurations.*.config.system.build.image
# because garnix.yml does not permit specifying these targets directly
#
{ flake, pkgs, ... }:
with builtins;
with pkgs.lib;
let
  optionalImage = hostConfig: if (
    (hasAttr "config" hostConfig) &&
    (hasAttr "system" hostConfig.config) &&
    (hasAttr "build"  hostConfig.config.system) &&
    (hasAttr "image"  hostConfig.config.system.build)
  ) then hostConfig.config.system.build.image else false;
  imagesAndFalses = mapAttrs
    (hostName: hostConfig: optionalImage hostConfig)
    flake.nixosConfigurations;
  images = filterAttrs
    (hostName: hostImage: hostImage != false)
    imagesAndFalses;
in pkgs.symlinkJoin {
  name = "garnix-build";
  paths = attrValues images;
}