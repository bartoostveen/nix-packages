args:

{
  # keep-sorted start
  mistserver = import ./mistserver.nix args;
  uptime-kuma-matrix = import ./uptime-kuma-matrix.nix args;
  # keep-sorted end
}
