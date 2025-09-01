#!/usr/bin/env bats

@test "wz_notify.sh содержит --permalog" {
  run grep -q -- '--permalog' ~/wheelzone-script-utils/scripts/Loki/wz_notify.sh
  [ "$status" -eq 0 ]
}
