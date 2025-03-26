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
    # nixpkgs.url = "github:nixos/nixpkgs?ref=bff5f93f3673edf9c08670b9ffd3619752e76619";
    nixpkgs.url = "github:rcambrj/nixpkgs?ref=2da4f42b82b099ed9a1153a9e07efe37ebddc9b6";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
