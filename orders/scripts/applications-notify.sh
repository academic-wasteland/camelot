#!/bin/sh
set -eu
export PATH="$HOME/.local/bin:$PATH"
exec pangenome-town authority notify
