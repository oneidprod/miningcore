# miningcore-buildonly — Claude Project File

## What This Repo Is
A fork of miningcore (Ethereum/Solidity-based multi-algo mining pool software). This repo contains code changes and build scripts. It is built here and deployed to a VPS. The VPS runs AMD EPYC 7551 (Zen 1) which supports AVX2 but NOT AVX512.

The companion config repo is at `../miningcore_config` (private, `github.com:oneidprod/miningcore_config.git`, main branch).

## Key Code Changes Made
- [src/Miningcore/Blockchain/Bitcoin/BitcoinJob.cs](src/Miningcore/Blockchain/Bitcoin/BitcoinJob.cs) line 794: replaced hardcoded GhostRider symbol list with `coin.HasSmartNodes` to fix `bad-cb-payee` errors for any GR coin with smartnodes.
- [src/Miningcore/Persistence/Postgres/Repositories/BlockRepository.cs](src/Miningcore/Persistence/Postgres/Repositories/BlockRepository.cs): minor whitespace fix in INSERT query (space before `confirmationprogress`).

## Build Scripts
| Script | Purpose |
|-|-|
| `build-only.sh` | Standard build, dotnet publish only, no native libs |
| `build-only-vps-amd.sh` | VPS-targeted build: patches files to use `-march=znver1`/`-DARCH=znver1`, builds native libs, then dotnet publish. Restores originals on exit. |
| `build-ubuntu-*.sh` | Legacy full-environment scripts, not used for normal builds |

To build for VPS: `./build-only-vps-amd.sh [outdir]` (default outdir: `../../build`)

The VPS build script patches these files temporarily (restores on exit):
- `src/Native/check_cpu.sh` — disables AVX512 detection
- `src/Native/libcryptonote/Makefile` — `-march=native` → `-march=znver1`
- `src/Miningcore/build-libs-linux.sh` — `-DARCH=native` → `-DARCH=znver1`

## VPS PostgreSQL Setup
- TimescaleDB is in use. `max_locks_per_transaction` must be 512 (not default 64).
- `max_connections` set to 200 (VPS has only ~956MB RAM, can't go higher safely).
- StatsRecorder `DeletePoolStatsBeforeAsync`/`DeleteMinerStatsBeforeAsync` may time out on large tables — this is a known slow query issue, not a code bug.
- `ShareRecorder` `42703: column "minereffort" does not exist` error was seen; the column exists in `blocks` table. Root cause not yet fully resolved.

## GhostRider Coin Rules
All GhostRider coins must have `"hasSmartNodes": true` in `miningcore_config/coins.json`. Multi-algo coins (e.g., BUTK, MTBC) that include GR also need both `"hasMasterNodes": true` and `"hasSmartNodes": true`.

## Git Policy
- Never commit without building and testing.
- Never commit secrets.
- Both this repo and `miningcore_config` should be committed and pushed at end of each session.

## Backlog
- Investigate `42703: column "minereffort" does not exist` ShareRecorder error fully (column exists in blocks; may be a view or different table path).
- Investigate StatsRecorder timeout on `DeletePoolStatsBeforeAsync`/`DeleteMinerStatsBeforeAsync` — check table sizes and index coverage on `poolstats`/`minerstats`.
- All GhostRider coins (including OSN, MENEL, DUN, and others added in remote commits) already have `hasSmartNodes: true` in miningcore_config — no action needed there.

## Session Log

### Session 1 - 2026-06-03 - complete
- Fixed `bad-cb-payee` GhostRider error: replaced hardcoded symbol list with `coin.HasSmartNodes` in BitcoinJob.cs line 794.
- Added missing `hasSmartNodes`/`hasMasterNodes` flags to BBC, GSPC, JGC, MTBC and others in miningcore_config/coins.json. Committed and pushed config repo (eb7b3c6).
- Created `build-only.sh` and `build-only-vps-amd.sh`.
- Resolved AVX512 illegal instruction crash on VPS by patching native lib builds to use znver1.
- Fixed PostgreSQL `max_locks_per_transaction` (512) and `max_connections` (200).
- Rebased dev branch on remote (remote had 4 new commits adding more GR coins to hardcoded list; our HasSmartNodes fix supersedes them). Pushed both repos.
- Pending: `minereffort` column error and StatsRecorder timeout not yet resolved.

### Session 2 - next
