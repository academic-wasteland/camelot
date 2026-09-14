#!/bin/sh
# Gas City service entrypoint: Camelot's envoy (registrar + Agent Card) on $GC_SERVICE_SOCKET.
set -eu
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
: "${GC_SERVICE_SOCKET:?GC_SERVICE_SOCKET is required}"
if [ -z "${PT_TOWN_TOML:-}" ] && [ -n "${GC_SERVICE_STATE_ROOT:-}" ]; then
  PT_TOWN_TOML="$(cd "$GC_SERVICE_STATE_ROOT/../../.." && pwd)/town.toml"
  export PT_TOWN_TOML
fi
exec pangenome-town authority serve --socket "$GC_SERVICE_SOCKET"
