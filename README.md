# NixOS loaders for Raspberry Pi

status: unstable

## What is it?

A module to make booting your NixOS configuration possible on a Raspberry Pi.

### The problem

The traditional way of putting an operating system onto a machine is:

1. transfer the installation software onto portable storage
1. put it in the target machine
1. install onto the machine's internal storage

It should already be possible to do this by downloading the [NixOS ARM installation image].
You will need two SD cards or USB sticks to complete this method. Although I couldn't even get
the ARM installer image to boot, so that may already be enough of a justification.

However, with Raspberry Pis and other single board computers, the usual way is different:

1. transfer a fully working operating system to an SD card or USB stick
1. put it in the target machine and boot

This repository's module makes it possible to use this last method.

Note: there are other methods too, such as [nixos-anywhere].

## Will it work on my board?

You should absolutely read [the NixOS wiki on ARM].

In the following table, `aarch64` is assumed unless otherwise noted.

| SBC                   | status | notes                                             |
|-----------------------|--------|---------------------------------------------------|
| Raspberry Pi 1        | ❌     | 32 bit (armv6l) so no binary cache                |
| Raspberry Pi Zero (W) | ❌     | 32 bit (armv6l) so no binary cache                |
| Raspberry Pi 2        | ❌     | 32 bit (armv7l) so no binary cache                |
| Raspberry Pi Zero 2W  | ??     | untested. probably boots but cannot nixos-rebuild |
| Raspberry Pi 3        | ✅     | boots. requires zram for nixos-rebuild            |
| Raspberry Pi 4        | ??     | untested. probably works                          |
| Raspberry Pi 5        | ??     | untested. see [NixOS wiki on Raspberry Pi 5]      |
| Your favourite board  | ??     | PRs welcome!                                      |

Do you have one of these boards? Please let me know whether this boots!

## Getting started

### Prebuilt image

Download the prebuilt image from the latest [github releases]

The prebuilt image has SSH enabled and you should be able to login in with:

```
username: nixos
password: password
```

The purpose of this image is to allow you to quickly test whether this module will work for you.
It isn't intended to serve as a long lived OS for your board. For that, keep reading...


### Roll your own


```
# flake.nix
inputs.nix-pi-loader.url = "github:rcambrj/nix-pi-loader";
```

```
# configuration.nix
imports = [
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
  partitionTableType = "efi";
  touchEFIVars = false;
  installBootLoader = true;
});
```

Then run

```
nix build <path-to-flake>#nixosConfigurations.<your-machine-name>.config.system.build.image
```

## Troubleshooting

### Boots but cannot nixos-rebuild

If your board has less than ~1.5GB RAM, you might see it lockup when running nixos-rebuild.
You can use zram to fix that.

```
zramSwap = {
  enable = true;
  memoryPercent = 50; # play with this number
};
```

Alternatively, configure a swap file or partition, or use another (more powerful) machine
to run `nixos-rebuild` with `--target-host`.

## Upcoming work

### Submit `extraCommandsAfter` option

`generic-extlinux-compatible` has been copied into this repository as it lacks a way to
receive extra commands to execute during the `installBootloader` step. This has been added by
way of a new `extraCommandsAfter` option. After some battle testing it may be worthwhile
suggesting that this change be merged to nixpkgs.

If this functionality get upstreamed, then `boot.loader.generic-extlinux-compatible-pi-loader`
will be removed, so please keep that in mind when checking for new versions of this module.

### Write tests

TODO: learn how to write nix tests, then write tests

### Fix nixos-rebuild for low RAM boards

`nixos-rebuild` will not work if the board has less than ~1.5GB RAM. While this can be fixed with
zram, there's only so much that zram can do, that is to say that boards with 512MB RAM cannot
magic 300% RAM. Some alternatives are mentioned in the troubleshooting section, but I wonder
whether `nixos-rebuild` can be run with some parameters to make it less demanding.

### Pi firmwares in nixpkgs

There already exists a [raspberrypi.nix] in nixpkgs which has been abandoned and the NixOS team
has already expressed that this is a conscious decision favouring lessening the workload required
to keep up with each new pi board. That is, the NixOS support goes as far as supporting u-boot
via the `generic-extlinux-compatible` module and anything beyond that is the user's responsibility.

So upstreaming the main part of this module to nixpkgs is unlikely to happen.

## Credits

A lot of this module is based on [sd-image-aarch64.nix]. Thanks for all the work
which went into that module and everything which leads up to it.

I've merely put the cherry on top (and badly at that).

[NixOS ARM installation image]: https://nixos.org/download/#nixos-iso
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
[the NixOS wiki on ARM]: https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi
[NixOS wiki on Raspberry Pi 5]: https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_5
[raspberrypi.nix]: https://github.com/NixOS/nixpkgs/blob/6afb255d976f85f3359e4929abd6f5149c323a02/nixos/modules/system/boot/loader/raspberrypi/raspberrypi.nix
[github releases]: https://github.com/rcambrj/nix-pi-loader/releases/
[sd-image-aarch64.nix]: https://github.com/NixOS/nixpkgs/blob/794d005bdd26af909ecbe6e4fc618f14518d4df4/nixos/modules/installer/sd-card/sd-image-aarch64.nix
