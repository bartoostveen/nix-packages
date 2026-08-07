args:

{
  # keep-sorted start
  mistserver = import ./mistserver.nix args;
  timedout-registry = import ./timedout-registry.nix args;
  uptime-kuma-matrix = import ./uptime-kuma-matrix.nix args;
  venator = import ./venator.nix args;
  # keep-sorted end
}
