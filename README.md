# Camelot

Camelot is the authority town of The Academic Wasteland (BioHackathon 2026). It hosts **demo** authorities:
an accreditation council, a research ethics board, and data access committees for the pangenome towns
[Ubar](https://github.com/academic-wasteland/ubar) (KSA samples) and
[Yamatai](https://github.com/academic-wasteland/yamatai) (JPT samples).

All authorities here have invented names. They do not represent KAUST, NIG, or any real ethics board,
data access committee, or institution.

Design: [resources, credentials, and compute](https://github.com/academic-wasteland/pangenome-town/blob/main/docs/resources-and-credentials.md).

## What Camelot does

| Issuer | Role | Accredited by |
|---|---|---|
| `ethics-council` | AccreditationCouncil (trust anchor of Ubar and Yamatai) | none |
| `wasteland-irb` | EthicsBoard, issues `EthicsApproval` | `ethics-council` |
| `ubar-dac` | DataAccessCommittee for Ubar's controlled tier, issues `DataAccessAuthorization` | `ethics-council` |
| `yamatai-dac` | DataAccessCommittee for Yamatai's controlled tier | `ethics-council` |

- The **envoy** service serves the registrar and an Agent Card through the supervisor at
  `http://127.0.0.1:8372/v0/city/camelot/svc/envoy/`: `/.well-known/agent-card.json`, `/v0/keys`,
  `POST /v0/applications`, `/v0/applications/<id>`, `/v0/credentials/<id>`, `/v0/status/<id>`.
- Residents **Iris** (`irb`) and **Dagny** (`dac`) run on the lab's local Qwen. They review pending
  applications and mail a recommendation to the human operator. They cannot issue anything.
- **Decisions are human only.** Approve, deny, and revoke exist only as CLI commands, never over HTTP.
- The `applications-notify` order mails `human` once per new pending application.

Credentials are Ed25519-signed JSON documents shaped like W3C Verifiable Credentials 2.0 (without claiming
conformance to its Data Integrity suites). Issuer private keys live in `~/.gc/authority/camelot/` (mode 0600),
never in this repository. Public issuer records and accreditations are committed under `registry/issuers/`;
applications, issued credentials, and the revocation list are runtime state and gitignored.

## Setup

```sh
uv tool install --editable ../pangenome-town      # provides the pangenome-town CLI
scripts/bootstrap-authorities.sh                  # issuers and accreditations from town.toml (idempotent)
gc start                                          # register with the local supervisor and start the envoy
```

## Applying for a credential (researcher side)

Researchers act through a pangenome town. The holder key never leaves `~/.gc/holders/`.

```sh
pangenome-town --town ../yamatai/town.toml holder new --holder https://orcid.org/<your-orcid>
pangenome-town --town ../yamatai/town.toml holder apply --holder https://orcid.org/<your-orcid> \
  --type EthicsApproval --issuer wasteland-irb \
  --scope https://w3id.org/academic-wasteland/pangenome-town/contract/AggregateFrequencyScope \
  --protocol WREB-2026-001 --purpose "Allele frequency differences between KSA and JPT in HLA class I"
pangenome-town --town ../yamatai/town.toml holder apply --holder https://orcid.org/<your-orcid> \
  --type DataAccessAuthorization --issuer ubar-dac \
  --dataset https://w3id.org/academic-wasteland/ubar/datasets/ksa-individual-genotypes \
  --scope https://w3id.org/academic-wasteland/pangenome-town/contract/AggregateFrequencyScope \
  --purpose "Allele frequency differences between KSA and JPT in HLA class I"
```

## Deciding (operator side)

```sh
pangenome-town authority applications --state pending
pangenome-town authority show app-1234abcd
pangenome-town authority approve app-1234abcd --valid-days 30
pangenome-town authority deny app-1234abcd --reason "scope broader than the stated purpose"
pangenome-town authority revoke https://w3id.org/academic-wasteland/camelot/credentials/<uuid>
```

Ask a resident for a review: `gc session new irb`, then mail its session id, or wait for the nudge.

## Using credentials

```sh
pangenome-town --town ../yamatai/town.toml holder fetch --holder https://orcid.org/<your-orcid> app-1234abcd
pangenome-town --town ../yamatai/town.toml rcp submit --to ubar --kind allele-frequency \
  --region GRCh38:chr6:29940000-29990000 \
  --on-behalf-of https://orcid.org/<your-orcid> --holder https://orcid.org/<your-orcid>
```

Ubar verifies signatures, holder binding, validity, and revocation in code; the reasoner then decides whether
the issuers sit under Ubar's trust anchor, whether the approved scope covers the task, and whether the output
may be released.
