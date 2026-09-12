# Week 5 Report — CKB Script Fundamentals

**Project:** CellRoute  
**Deliverable:** Simple Lock Lab  
**Recorded Devnet verification:** September 9, 2026

## Objective

Build, test, and deploy a CKB lock script, then demonstrate funding and spending a protected Cell through the portal. The exercise covers the Cell lifecycle, Script groups, code dependencies, witnesses, and transaction commitment.

## Work completed

- Implemented a TypeScript bearer hash-lock using CKB JS VM, with contract source and tooling isolated in [`contracts/`](contracts/README.md).
- Added the portal's `/simple-lock` page for address derivation, Devnet funding, live capacity lookup, transaction review, unlocking, and status checks.
- Added native VM fixtures for successful and rejected spends, including grouped inputs.
- Added deployment and metadata export scripts that publish the bytecode hash, code OutPoint, JS VM dependency, and Devnet genesis identity.
- Recorded a committed unlock and node rejection results in [machine-readable Devnet evidence](contracts/deployment/week5-evidence.json).

## How the lock works

The lock stores a CKB-personalized BLAKE2b-256 digest in its arguments. To spend a protected Cell, a transaction supplies the original preimage as raw bytes in the first witness of the input lock group. The script hashes those bytes and compares the result with the stored digest.

| Result | Exit code |
| --- | --- |
| Correct preimage | `0` |
| Malformed arguments | `5` |
| Missing or empty witness | `6` |
| Incorrect preimage | `7` |
| Witness larger than 1,024 bytes | `8` |

Funding creates a new Cell without executing its output lock. Spending consumes that Cell and executes its input lock group; any nonzero script result rejects the transaction. The unlock is complete only when the node reports `committed`.

TypeScript was chosen to reuse the project's CCC transaction stack and OffCKB workflow. The build produces bytecode executed by CKB JS VM, so the transaction requires both the VM code Cell and the contract bytecode Cell as dependencies. See the [technical report](docs/week-5-report.md) for the validation lifecycle and language-choice discussion.

## Recorded results

The following results come from the existing Week 5 report and evidence; they were not rerun for this documentation update.

| Validation | Recorded outcome |
| --- | --- |
| Native VM contract tests | 8/8 passed |
| Portal helper tests | 13/13 passed |
| TypeScript checks and production portal build | Passed |
| Chromium Simple Lock browser test | 1/1 passed |
| Devnet unlock | `committed` |
| Node rejection checks | Wrong preimage: `7`; missing witness: `6` |
| Successful native debugger fixture | 13,136,726 cycles |

The browser test checks wallet-free address derivation and the initial submission state. The separate Devnet verification script exercises an actual unlock and rejection cases.

### Devnet transaction evidence

| Item | Recorded value |
| --- | --- |
| Bytecode code hash | `0x191a12efda778478ac4173a4b4c0218e8676d0e2fc568dbb6500862f6d14d273` |
| Code OutPoint | `0xd6e697ad00741fae4027c352f31ffd51cd243bedafe577d30905901e39152a08:0` |
| Funding transaction | `0xe11568d8b55c4aace03f6eb120df92d4d651f58a99d3c470bb3fa1490ebaa409` |
| Unlock transaction | `0x0a6013948b1026a13b76839b2aec7ce3de25d7799be989ff9d172fc05cca72cc` |

These identifiers belong to the recorded local OffCKB Devnet. Resetting the chain requires redeployment and regenerated metadata.

## Reproduce the demonstration

Prerequisites: Node.js 22+, OffCKB CLI, and native `ckb-debugger` 1.1.1 on `PATH` or configured through `CKB_DEBUGGER`.

From the repository root, build and test the contract:

```sh
cd contracts
npm ci
npm run typecheck
npm test
```

Start `offckb node` in a separate terminal and keep it running. From `contracts/`:

```sh
offckb system-scripts --output deployment/system-scripts.json
npm run deploy
npm run export:metadata
node scripts/verify-devnet.mjs --address
offckb deposit <printed-address> 200
```

Replace `<printed-address>` with the address returned by the verification script. After funding commits, run `npm run test:devnet` to verify the unlock and regenerate the evidence JSON.

To open the portal, start another terminal at the repository root:

```sh
cd portal
npm ci
npm run dev
```

Open `/simple-lock` on the displayed local URL. Derive an address from a preimage, fund it on OffCKB Devnet, refresh live capacity, select a Cell, enter a recipient and the original preimage, review the transaction, and submit. Query its status until `committed`. Wallet funding requires an OffCKB Devnet wallet; terminal funding is also available.

## Challenges and lessons

- The Windows WASM debugger could not resolve the transaction fixture path. The native debugger enabled the VM tests to run.
- CCC fee handling required Devnet DAO metadata. The metadata export now includes that information and the standard funding lock.
- Group-relative witness loading allows the lock to work when unrelated inputs precede its inputs and when multiple inputs share the same lock.
- A successful submission is distinct from chain commitment; the verification workflow waits for the final status.

## Scope and limitations

This is an educational bearer hash-lock for local Devnet funds. Anyone who knows the preimage can spend Cells using the same digest, and submitting an unlock publicly reveals it. The contract does not authorize a specific recipient or bind the spend to a transaction signature.

The portal keeps the preimage in React memory. It unlocks one plain capacity Cell at a time, excludes typed Cells and Cells carrying data, and uses a 0.001 CKB fee. Deployment records are chain-specific.

