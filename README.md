# make-disk-image.nix loader for Raspberry Pi

status: unstable

## What is it?

A module to make booting your NixOS configuration possible on a Raspberry Pi using `make-disk-image.nix`

While [nix-community/raspberry-pi-nix] has wide support for creating images which boot on
Raspberry Pis, the approach of using `sd-image.nix` restricts the ability to test the machine
end to end (including bootloader) using `qemu-vm.nix`, which is what `testers.runNixOSTest` uses.

## Getting started

### Prebuilt image

Download the prebuilt image from the latest [github releases]

CAUTION: the image has SSH enabled with a known username/password.

The prebuilt image has SSH enabled, you can log in with:

```
username: nixos
password: password
```

The purpose of this image is to allow you to quickly test whether this module will work for you.
It isn't intended to serve as a long lived OS for your board.

### Roll your own

```
# flake.nix
inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";
inputs.nix-pi-loader.url  = "github:rcambrj/nix-pi-loader";
```

```
# configuration.nix
imports = [
  # select the relevant nixos-hardware module
  # inputs.nixos-hardware.nixosModules.raspberry-pi-3
  # inputs.nixos-hardware.nixosModules.raspberry-pi-4

	inputs.nix-pi-loader.nixosModules.default
];
boot.pi-loader.enable = true;
```

You cannot use `boot.loader.generic-extlinux-compatible`. This module disables it because it has its
own modified version at `boot.loader.generic-extlinux-compatible-pi-loader`. You can set options
there instead, but please see the upcoming work section for why this might be removed in the future.

### Building an image file

```
# configuration.nix
system.build.image = (import "${toString modulesPath}/../lib/make-disk-image.nix" {
  inherit lib config pkgs;
  format = "raw";
  partitionTableType = "legacy+boot";
  touchEFIVars = false;
  installBootLoader = true;
});
```

Then run

```
nix build <path-to-flake>#nixosConfigurations.<your-machine-name>.config.system.build.image
```

[github releases]: https://github.com/rcambrj/nix-pi-loader/releases/
[nix-community/raspberry-pi-nix]: https://github.com/nix-community/raspberry-pi-nix