#!/bin/sh
# Create Camelot's demo issuers and accreditations from town.toml. Idempotent: existing keys are never regenerated.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
export PT_TOWN_TOML="$here/town.toml"
python3 - "$here/town.toml" <<'PY' | while IFS='|' read -r kind slug name role by; do
import sys, tomllib
data = tomllib.load(open(sys.argv[1], "rb"))
issuers = data["authority"]["issuers"]
for item in issuers:
    print(f"issuer|{item['slug']}|{item['name']}|{item['role']}|")
for item in issuers:
    if item.get("accredited_by"):
        print(f"accredit|{item['slug']}|||{item['accredited_by']}")
PY
  if [ "$kind" = issuer ]; then
    pangenome-town authority init-issuer "$slug" --name "$name" --role "$role" >/dev/null
    echo "issuer $slug"
  else
    if pangenome-town authority issuers | python3 -c "import json,sys; d={i['slug']: i for i in json.load(sys.stdin)}; sys.exit(0 if d['$slug']['accreditedBy'] else 1)"; then
      echo "accreditation $slug already present"
    else
      role=$(python3 -c "import tomllib; d=tomllib.load(open('$here/town.toml','rb')); print([i['role'] for i in d['authority']['issuers'] if i['slug']=='$slug'][0])")
      pangenome-town authority accredit --by "$by" --subject "$slug" --roles "$role" >/dev/null
      echo "accredited $slug by $by"
    fi
  fi
done
