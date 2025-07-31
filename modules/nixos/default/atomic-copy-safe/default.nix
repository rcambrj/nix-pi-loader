{ lib, pkgs }:

pkgs.replaceVarsWith {
  src = ./atomic-copy-safe.sh;
  isExecutable = true;
  replacements = {
    path = lib.makeBinPath [
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
    ];
    inherit (pkgs) bash;
  };
}
