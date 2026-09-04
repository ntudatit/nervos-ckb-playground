# Week 4 Report — Building on CKB

**Project:** FiberPay Platform  
**Live application:** [https://fiber-pay.vercel.app/](https://fiber-pay.vercel.app/)  
**Reporting period:** Week 4  
**Network target:** Nervos CKB Testnet and Fiber Testnet  
**Technology:** TypeScript, React, CCC, Spore SDK, Fiber JS, Rust and PostgreSQL

## 1. Objective

Week 4 applied the CKB beginner material by building practical Cell Model features inside a basic application. The exercises covered Transfer CKB, Store Data on Cell, fungible tokens, DOBs, Simple Lock, CCC and Fiber payment channels.

The resulting application is **FiberPay**, a non-custodial CKB asset and Fiber payment platform. It combines wallet-signed Layer 1 transactions with browser-based Fiber payment-channel operations.

## 2. Architecture

```text
React / Vite portal
  ├─ CCC wallet connection and CKB transactions
  ├─ xUDT token and Spore / DOB studios
  ├─ Browser-local Fiber WASM node
  └─ Checkout, merchant and FiberOps interfaces

Rust / Axum service
  ├─ CKB RPC, indexer and transaction tracking
  ├─ PostgreSQL persistence and audit history
  └─ Merchant reconciliation, operational API and MCP
```

Wallets sign CKB transactions client-side. The application does not request or store wallet private keys. Fiber identity is generated locally and persisted in IndexedDB.

## 3. Beginner exercises

### Transfer CKB — implemented

The portal uses CCC to connect a wallet, decode the receiver address, construct an output Cell, collect input Cells, complete fees and change, request wallet approval, broadcast the transaction and track its lifecycle.

Implementation: [`portal/src/pages/features/TransferCkbPage.tsx`](../portal/src/pages/features/TransferCkbPage.tsx)

### Store Data on Cell — implemented

The Store Data page encodes UTF-8 text as hexadecimal bytes, stores it in `outputsData`, lets CCC calculate occupied capacity, broadcasts the transaction, retrieves output `0x0` as a live Cell and decodes the bytes back into text.

Implementation: [`portal/src/pages/features/StoreDataPage.tsx`](../portal/src/pages/features/StoreDataPage.tsx)

### Fungible Token — implemented

The Token Studio:

- derives an xUDT identifier from the issuer Lock Script hash;
- constructs the known xUDT Type Script;
- encodes amounts as 16-byte little-endian integers;
- adds xUDT Cell dependencies;
- mints and transfers tokens with change; and
- queries live token Cells, balances, owner Lock hashes and OutPoints.

Implementation: [`portal/src/pages/features/FungibleTokenPage.tsx`](../portal/src/pages/features/FungibleTokenPage.tsx)

### DOB / Spore — implemented

The DOB Studio mints text, image or binary content as a Spore Cell, optionally associates it with a Cluster, queries a live Spore by ID, decodes and renders content from the Cell, transfers ownership and melts a Spore after confirmation.

Implementations:

- [`portal/src/pages/features/DobSporePage.tsx`](../portal/src/pages/features/DobSporePage.tsx)
- [`portal/src/pages/features/SporeClusterPage.tsx`](../portal/src/pages/features/SporeClusterPage.tsx)

### Simple Lock — pending

This exercise is not yet implemented. Completion requires a dedicated hash-lock contract, `ckb-debugger` tests, OffCKB deployment, a funded lock Cell, a rejected wrong-preimage attempt and a committed correct-preimage spend. It is the main remaining gap in the beginner checklist.

## 4. CCC and wallet integration

FiberPay uses `@ckb-ccc/connector-react` for Testnet/Mainnet clients, wallet discovery, signer access, address conversion, transaction construction, input collection, fee completion and signing. Development defaults to CKB Testnet; learning exercises should remain on Devnet or Testnet.

## 5. Fiber payment application

FiberPay extends the Layer 1 exercises with `@nervosnetwork/fiber-js` running as a browser-local node. It supports:

- persistent local identity and WSS peer connections;
- channel creation, external wallet funding and shutdown;
- invoice creation, parsing, cancellation and lookup;
- route dry runs, invoice payments, MPP and trampoline routing;
- channel health and payment monitoring;
- merchant checkout and order lifecycle management; and
- reconciliation and incident reporting.

Implementation: [`portal/src/fiber-wasm/runtime.ts`](../portal/src/fiber-wasm/runtime.ts)

Fiber routes use COOP/COEP headers for `SharedArrayBuffer`; wallet-popup routes remain non-isolated for connector compatibility.

## 6. Rust backend

The Rust service uses CKB SDK, JSON-RPC types and Axum. It provides transaction lifecycle events, indexer synchronization, asset audit records, merchant persistence, Fiber reconciliation and PostgreSQL access. This is application-side Rust and does not replace the pending Simple Lock contract.

Implementation: [`rust-service`](../rust-service)

## 7. Verification

| Check | Result |
| --- | --- |
| Portal unit tests | 8 passed |
| TypeScript strict type-check | Passed |
| Rust `cargo check` | Passed |
| Git whitespace validation | Passed |

The Vite build transformed the application modules but could not clean `portal/dist/assets` because of a local Windows `EPERM` file lock. Independent TypeScript compilation passed.

These checks validate code quality but do not prove that public Testnet transactions or Fiber payments reached their final state.

## 8. Lessons learned

- CKB assets are represented by Cells and controlled by Lock Scripts.
- Cell capacity pays for both stored state and CKB value.
- `outputsData` stores application bytes; Type Scripts enforce rules such as xUDT.
- CCC simplifies Cell collection, fees, change and wallet signing.
- Spore stores digital-object content and ownership directly in Cells.
- Fiber moves repeated payments off-chain while CKB provides funding and settlement.
- A submitted hash is not completion proof; the committed state must be verified.

## 9. Next Week Work

Week 5 will focus on **CKB Script Fundamentals** and completing the Simple Lock exercise that remains pending from the beginner checklist.

Planned work:

- Study the CKB validation model, Script groups, witnesses and exit codes.
- Review Script development with Rust and JavaScript and select the implementation language.
- Build a hash-lock Script that verifies a witness preimage against the hash stored in Script args.
- Add tests for correct, incorrect and missing preimages.
- Build and inspect the contract with `ckb-debugger`.
- Deploy the contract to OffCKB Devnet.
- Fund a Cell protected by the custom lock and unlock it with the correct preimage.
- Begin integrating a Simple Lock Lab into FiberPay.


## 10. References

- [Transfer CKB](https://docs.nervos.org/docs/dapp/transfer-ckb)
- [Store Data on Cell](https://docs.nervos.org/docs/dapp/store-data-on-cell)
- [Create a Fungible Token](https://docs.nervos.org/docs/dapp/create-token)
- [Create a DOB](https://docs.nervos.org/docs/dapp/create-dob)
- [Build a Simple Lock](https://docs.nervos.org/docs/dapp/simple-lock)
- [CCC documentation](https://docs.ckbccc.com/)
- [Fiber Network documentation](https://www.fiber.world/docs)
- [Nervos RFCs](https://github.com/nervosnetwork/rfcs)
