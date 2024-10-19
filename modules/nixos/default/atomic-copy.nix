{ pkgs }:

pkgs.substituteAll {
  src = ./atomic-copy.sh;
  isExecutable = true;
  path = [pkgs.coreutils pkgs.gnused pkgs.gnugrep];
  inherit (pkgs) bash;
}
