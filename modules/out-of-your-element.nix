{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    # keep-sorted start
    getAttrFromPath
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optional
    splitString
    types
    # keep-sorted end
    ;

  inherit (types)
    # keep-sorted start
    attrs
    nullOr
    path
    # keep-sorted end
    ;

  cfg = config.services.out-of-your-element;

  configFormat = pkgs.formats.json { };
in
{
  options.services.out-of-your-element = {
    enable = mkEnableOption "out-of-your-element, a Matrix-Discord bridge with modern features";
    package = mkPackageOption pkgs "out-of-your-element" { };
    suppressOriginWarning = mkEnableOption "suppressing the warning when the origin configuration is incorrect";
    configFile = mkOption {
      description = "file that contains the server config, overrides services.out-of-your-element.settings!";
      type = path;
      default = configFormat.generate "out-of-your-element.json" cfg.settings;
      defaultText = "<<generated JSON from services.out-of-your-element.settings>>";
    };
    registrationSecretsFile = mkOption {
      description = "File that contains secrets for the registration. Gets merged with declarative `settings` option.";
      type = nullOr path;
      default = null;
      example = "/path/to/ooye-registration.yaml";
    };
    settings = mkOption {
      description = "out-of-your-element server config, see the example";
      type = attrs;
      default = { };
      example = {
        id = "ooye";
        namespaces = {
          aliases = [
            {
              exclusive = true;
              regex = "#_ooye_.*:yourhomeserver.com";
            }
          ];
          users = [
            {
              exclusive = true;
              regex = "@_ooye_.*:yourhomeserver.com";
            }
          ];
        };
        ooye = {
          bridge_origin = "example.com";
          content_length_workaround = false;
          include_user_id_in_mxid = false;
          invite = [ ];
          max_file_size = 5000000;
          namespace_prefix = "_ooye_";
          receive_presences = true;
          server_name = "yourhomeserver.com";
          server_origin = "https://matrix.yourhomeserver.com";
        };
        protocols = [ "discord" ];
        rate_limited = false;
        sender_localpart = "_ooye_bot";
        socket = 6693;
        url = "example.com";
      };
    };
  };

  config = mkIf cfg.enable {
    warnings =
      let
        secretWarning =
          name:
          optional (getAttrFromPath (splitString "." name) cfg.settings != null) ''
            services.out-of-your-element.settings.${name} is set.

            This copies the registration secrets into the world-readable Nix store.
            You should never do this in a production setup! It is recommended to use registrationSecretsFile instead.
            This file (in JSON) will be merged on runtime with the declarative settings.
          '';
      in
      secretWarning "as_token"
      ++ secretWarning "hs_token"
      ++ secretWarning "ooye.discord_client_secret"
      ++ secretWarning "ooye.discord_token"
      ++ secretWarning "ooye.web_password"
      ++ optional (
        cfg.settings.ooye.bridge_origin != cfg.settings.url
        && !cfg.suppressOriginWarning ''
          settings.ooye.bridge_origin does not equal settings.url! This is probably wrong.

          You can suppress this warning by setting `services.out-of-your-element.suppressOriginWarning = true;`
        ''
      );

    systemd.services.out-of-your-element = {
      description = "out-of-your-element - a Matrix-Discord bridge with modern features";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      script = ''
        jq -s 'reduce .[] as $item ({}; . * $item)' \
          ${cfg.settingsFile} $CREDENTIALS_DIRECTORY/registration-secrets > registration.yaml
        out-of-your-element
      '';
      path = [
        pkgs.jq
        cfg.package
      ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "out-of-your-element";
        WorkingDirectory = "%S/out-of-your-element";
        LoadCredential = [ "registration-secrets:${cfg.registrationSecretsFile}" ];
        Restart = "on-failure";
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MountAPIVFS = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = "strict";
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = 27;
      };
    };
  };
}
