{
  description = "my flake";

  # Add all your dependencies here
  inputs = {
    # pin nixpkgs https://github.com/NixOS/nixpkgs/pull/362081#issuecomment-2596822330
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Load the blueprint
  outputs = inputs: inputs.blueprint { inherit inputs; };
}
