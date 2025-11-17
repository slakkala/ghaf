# SPDX-FileCopyrightText: 2022-2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# VM memory usage manager on host
#
{
  pkgs,
  config,
  lib,
  ...
}:
let
  balloonvms = builtins.filter (
    name: (config.microvm.vms.${name}.config.config.microvm.balloon or false)
  ) (builtins.attrNames (config.microvm.vms or { }));
in
{
  services.dbus.packages = [ pkgs.ghaf-mem-manager ];
  systemd.services = {
    "ghaf-mem-managerd" = {
      description = "Manage MicroVM memory levels";
      after = [ "dbus.service" ];
      requires = [ "dbus.service" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "ae.tii.MemManager";
        Environment = [
          "RUST_LOG=debug"
        ];
        ExecStart = "${pkgs.ghaf-mem-manager}/bin/ghaf-mem-managerd -l 70 -H 85";
      };
    };
  }
  //
    builtins.foldl'
      (
        result: name:
        result
        // (
          let
            microvmConfig = config.microvm.vms.${name}.config.config.microvm;
            appvmConfig = config.ghaf.virtualization.microvm.appvm.vms.${lib.removeSuffix "-vm" name};
          in
          {
            "ghaf-mem-manager-${name}" = {
              description = "Manage MicroVM '${name}' memory levels";
              after = [
                "microvm@${name}.service"
                "ghaf-mem-managerd.service"
              ];
              requires = [
                "microvm@${name}.service"
                "ghaf-mem-managerd.service"
              ];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.dbus}/bin/dbus-send --system --type=method_call --print-reply --dest=ae.tii.MemManager / ae.tii.MemManager.AttachVm string:${config.microvm.stateDir}/${name}/${name}.sock uint64:${
                  toString (appvmConfig.ramMb * 1024 * 1024)
                } uint64:${toString (microvmConfig.mem * 1024 * 1024)}";
              };
            };
          }
        )
      )
      {
        balloon-manager =
          let
            balloonvmnames = map (name: "ghaf-mem-manager-" + name + ".service") balloonvms;
          in
          {
            description = "Manage MicroVM balloons";
            after = balloonvmnames;
            requires = balloonvmnames;
            wantedBy = [ "microvms.target" ];
            script = ":";
          };
      }
      balloonvms;
}
