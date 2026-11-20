#!/bin/bash

# shellcheck enable=all

# Open a wttr.in page as a floating web app.
#
# The browser gives a web app its class and title only once its surface is
# mapped, which is too late for a Hyprland window rule to float it. So the
# window is floated, resized and centered as soon as it shows up.

set -euo pipefail

readonly WIDTH=1100
readonly HEIGHT=850

url="${1:-}"
if [[ -z ${url} ]]; then
  echo "usage: weather-webapp.sh <url>" >&2
  exit 1
fi

omarchy-launch-or-focus-webapp wttr "${url}" >/dev/null 2>&1 || true

for _ in {1..200}; do
  address=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class | test("wttr\\.in"; "i")) | .address' | head -n1 || true)
  if [[ -n ${address} ]]; then
    # resize acts on the focused window, and relative deltas are the only
    # absolute-size route this Hyprland exposes.
    size=$(hyprctl clients -j 2>/dev/null | jq -r --arg a "${address}" '.[] | select(.address == $a) | "\(.size[0]) \(.size[1])"' | head -n1 || true)
    width=${size%% *}
    height=${size##* }

    hyprctl dispatch "hl.dsp.focus({ window = \"address:${address}\" })" >/dev/null 2>&1 || true
    hyprctl dispatch "hl.dsp.window.float({ window = \"address:${address}\" })" >/dev/null 2>&1 || true
    if [[ -n ${width} && -n ${height} ]]; then
      hyprctl dispatch "hl.dsp.window.resize({ x = $((WIDTH - width)), y = $((HEIGHT - height)), relative = true })" >/dev/null 2>&1 || true
    fi
    hyprctl dispatch "hl.dsp.window.center({ window = \"address:${address}\" })" >/dev/null 2>&1 || true
    exit 0
  fi
  sleep 0.1
done
