{ pkgs, config, lib, ... }:

let
  cfg = config.dotenv;

  dotenvPath = config.devenv.root + "/" + cfg.filename;

  dotenvFound = lib.pathExists dotenvPath;
  parseLine = line:
    let
      parts = builtins.match "(.+) *= *(.+)" line;
    in
    if (!builtins.isNull parts) && (builtins.length parts) == 2 then
      { name = builtins.elemAt parts 0; value = builtins.elemAt parts 1; }
    else
      null;

  parseEnvFile = content: builtins.listToAttrs (lib.filter (x: !builtins.isNull x) (map parseLine (lib.splitString "\n" content)));
in
{
  options.dotenv = {
    enable = lib.mkEnableOption ".env integration, doesn't support comments or multiline values.";

    filename = lib.mkOption {
      type = lib.types.str;
      default = ".env";
      description = ''
        The name of the dotenv file to load.
      '';
    };

    resolved = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      internal = true;
    };

    disableHint = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Disable the hint that are printed when the dotenv module is not enabled, but .env is present.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      env = lib.mapAttrs (name: value: lib.mkDefault value) config.dotenv.resolved;
      dotenv.resolved = parseEnvFile (builtins.readFile dotenvPath);
    })
    (lib.mkIf (!cfg.enable && !cfg.disableHint) {
      enterShell = lib.optionalString dotenvFound ''
        echo "💡 ${cfg.filename} file found, but dotenv integration is not enabled."
        echo 
        echo "   To enable it, add \`dotenv.enable = true;\` to your devenv.nix file.";
        echo "   To disable this hint, add \`dotenv.disableHint = true;\` to your devenv.nix file.";
      '';
    })
  ];
}