{
  config,
  wlib,
  lib,
  ...
}:
let
  # implements a subset of kdl that *should* be sufficient for niri config
  inherit
    (rec {
      isFlag = v: v == null || v == true;
      mkBlock = n: v: ''
        ${n} {
          ${v}
        }'';
      # surround strings with qoutes
      toVal = v: if builtins.isString v then ''"${v}"'' else builtins.toString v;
      mkKeyVal =
        k: v:
        "${k} ${if lib.lists.isList v then lib.strings.concatStringsSep " " (map toVal v) else toVal v}";
      attrsToKdl =
        a:
        lib.concatMapAttrsStringSep "\n" (
          n: v:
          if (isFlag v) then
            #don't output anything if its false
            if v == false then "" else n
          else if (lib.isAttrs v) then
            mkBlock n (attrsToKdl v)
          else
            mkKeyVal n v
        ) a;
    })
    attrsToKdl
    ;
in
{
  _class = "wrapper";
  options = {
    settings = {
      binds = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        description = "Bindings of niri";
        example = ''
          "Mod+T".spawn-sh = lib.getExe pkgs.alacritty;
          "Mod+H" = "focus-column-or-monitor-left";
          "Mod+N".spawn = ["alacritty" "msg" "create-windown"]; 
        '';
      };
      layout = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        description = "Layout settings of niri";
      };
    };
    "config.kdl" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.content = lib.strings.concatStringsSep "\n" [
        (attrsToKdl { inherit (config.settings) binds layout; })
      ];
      description = ''
        Configuration file for Niri.
        See <https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction>
      '';
      example = ''
        input {
          keyboard {
              numlock
          }

          touchpad {
              tap
              natural-scroll
          }
        }
      '';
    };
  };
  config.filesToPatch = [
    "share/applications/*.desktop"
    "share/systemd/user/niri.service"
  ];
  config.package = config.pkgs.niri;
  config.env = {
    NIRI_CONFIG = toString config."config.kdl".path;
  };
  config.meta.maintainers = [
    lib.maintainers.zimward
    {
      name = "turbio";
      github = "turbio";
      githubId = 1428207;
    }
  ];
  config.meta.platforms = lib.platforms.linux;
}
