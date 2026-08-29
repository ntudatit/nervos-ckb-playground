# CKBuilder Weekly Report — Week 3

## 1. Overview

**Program:** CKBuilder  
**Week:** Week 3  
**Focus:** Building a browser-based Fiber payment platform on Nervos CKB  
**Project:** FiberPay Platform  

During Week 3, I evolved the Week 2 CKB playground into **FiberPay**, a payment application and operations platform built on **Nervos CKB + Fiber**.

Week 2 focused on learning the CKB Cell Model through CCC, wallet integration, CKB transfers, xUDT, Spore, and backend transaction tracking. Week 3 moved to the payment-channel layer and explored how Fiber can support instant payments while CKB remains the settlement and asset layer.

The central architectural principle became:

```text
CKB   = trust, ownership, assets, and settlement
Fiber = instant, low-cost, high-frequency payments
```

The project now contains three product surfaces:

```text
FiberPay Checkout → customers and payment recipients
Merchant Console  → orders, invoices, and payment lifecycle
FiberOps          → node, channel, liquidity, and incident operations
```

## Project Links

- **Live Application:** https://fiber-pay.vercel.app/

---

## 2. Week 3 Goals

The main goals for this week were:

- Run Fiber directly in the browser with `@nervosnetwork/fiber-js`.
- Preserve a browser-local Fiber identity with IndexedDB.
- Connect the browser node to public Fiber peers over WSS.
- Understand the difference between a Fiber public key and a libp2p Peer ID.
- Open and fund Fiber channels with a CKB wallet.
- Create, inspect, cancel, and pay Fiber invoices.
- Test payment readiness before sending real funds.
- Explore multi-hop, MPP, and trampoline routing.
- Build a two-node local browser lab.
- Add merchant orders and payment-attempt persistence.
- Build channel health, reconciliation, and incident views.
- Move the backend from the earlier Java service to Rust/Axum.
- Prepare deployment with cross-origin isolation, Docker, PostgreSQL, and free hosting.

---

## 3. Development Stack

### Portal

- React 18
- TypeScript
- Vite
- React Router
- `@nervosnetwork/fiber-js@0.9.0`
- `@ckb-ccc/connector-react`
- `@ckb-ccc/spore`
- IndexedDB
- Web Workers / WebAssembly

### Backend

- Rust
- Axum
- Tokio
- SQLx
- PostgreSQL
- JWT wallet authentication
- Server-Sent Events
- Structured tracing

### Deployment

- Docker / Docker Compose
- Nginx
- Vercel or Netlify-compatible static deployment
- Render-compatible Rust service
- Neon-compatible PostgreSQL

---

## 4. From CKB Playground to FiberPay

The biggest product change this week was reorganizing the application around a payment platform rather than a collection of blockchain examples.

The new architecture is:

```text
Customer / Merchant / Operator
              │
              ▼
        React FiberPay Portal
      ┌───────┼──────────┐
      ▼       ▼          ▼
  Checkout  Merchant   FiberOps
      │
      ▼
Browser Fiber WASM Node
      │
      ├── Web Worker
      ├── IndexedDB
      └── WSS peer connections
              │
              ▼
         Fiber Network
              │
              ▼
         CKB Settlement
```

The previous CCC and CKB features remain useful for wallet interaction, funding, xUDT, and Spore. However, they now sit behind a clearer product boundary.

### What I learned

A blockchain application becomes easier to reason about when its product surfaces follow user responsibilities rather than protocol names.

Customers need a checkout. Merchants need order and payment state. Operators need node and liquidity diagnostics.

---

## 5. Running Fiber in the Browser

The portal now embeds a Fiber node directly through:

```ts
import { Fiber, randomSecretKey } from "@nervosnetwork/fiber-js";
```

The runtime loads a Fiber YAML configuration and starts the node in the browser.

Conceptually:

```text
Browser
  ↓
fiber-js
  ↓
Fiber WASM Worker
  ↓
IndexedDB
  ↓
WSS
  ↓
Fiber Testnet
```

The private identity keys are generated locally and persisted in IndexedDB. They are not sent to the Rust backend, PostgreSQL, or AI service.

Each local node profile receives a separate database prefix. This makes it possible to run Node A and Node B as separate browser identities for testing.

### Key learning

The browser can operate as a non-custodial Fiber edge node, but it has different networking constraints from a native FNN node.

It cannot accept normal inbound TCP connections and needs browser-compatible WebSocket transport.

---

## 6. Cross-Origin Isolation

Fiber WASM uses Web Workers and `SharedArrayBuffer`. The browser document must therefore be cross-origin isolated.

Required headers:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Resource-Policy: cross-origin
```

I configured these headers for:

- Vite development server
- Vite preview server
- Vercel
- Netlify-compatible `_headers`
- Nginx Docker deployment

I also created a deployment verification command:

```powershell
npm run verify:isolation
```

This checks every Fiber WASM route and confirms that all required headers are present.

### Challenge

Strict COOP isolation can conflict with popup wallets because it separates the opener context. This explained an earlier wallet popup error where the FiberOps window was considered closed.

The important lesson is that WASM isolation and wallet popup behavior must be considered together at the application architecture level.

---

## 7. Connecting Fiber Nodes

Browser nodes connect to public relays through WSS multi-addresses.

Example structure:

```text
/dns4/example.fiber.node/tcp/443/wss/p2p/<peer-id>
```

The project supports two connection modes:

1. Explicit WSS multi-address
2. Fiber public key resolved from network graph information

The runtime validates that browser peer addresses contain `/ws` or `/wss`. Raw TCP peers are rejected because browsers cannot connect to them directly.

An important distinction is:

```text
/p2p/<value>  = libp2p Peer ID
02... / 03... = compressed Fiber identity public key
```

The connection API persists peer information using `save: true`.

### Key learning

Peer transport identity and Fiber payment identity are related but not interchangeable. Mixing them produced invalid connection and channel operations.

---

## 8. Channel Funding with a CKB Wallet

Fiber payments require channel liquidity. A connected peer without a funded channel cannot send payments.

The intended flow is:

```text
Connect Fiber peer
       ↓
Choose peer Fiber pubkey
       ↓
Build unsigned funding transaction
       ↓
CKB wallet completes capacity and CellDeps
       ↓
Wallet signs transaction
       ↓
Submit signed funding transaction to Fiber
       ↓
Wait for CKB confirmation
       ↓
Channel becomes Ready
```

The project supports external wallet funding by freezing the transaction structure produced by Fiber and allowing the wallet to complete and sign it.

This exposed several real integration challenges:

- resolving lock-script CellDeps,
- preserving the Fiber funding outputs,
- handling wallet-added inputs and change,
- allowing witness changes while preventing structural changes,
- supporting known CKB lock scripts.

### Key learning

Opening a Fiber channel is both a Fiber operation and a CKB transaction workflow. The application must respect invariants from both systems.

---

## 9. Invoices and Payment Flow

The portal can create Fiber invoices with:

- amount,
- description,
- expiry,
- payment preimage,
- MPP support,
- trampoline-routing support,
- optional UDT type Script.

The main payment lifecycle is:

```text
Create invoice
      ↓
Parse and validate invoice
      ↓
Run payment readiness / dry run
      ↓
Build route
      ↓
Send Fiber payment
      ↓
Track payment hash
      ↓
Settle merchant order
```

The Checkout page performs a dry run before sending the real payment.

This provides a practical answer to the question:

```text
Can this node pay this invoice now?
```

---

## 10. Payment Readiness and Liquidity

I encountered two important Fiber errors during testing.

### Self-payment

```text
allow_self_payment is not enabled, can not pay to self
```

This occurs when the invoice belongs to the same Fiber identity attempting to pay it.

The correct production behavior is to pay an invoice from another node. A self-payment flag can be exposed only for explicit local QA.

### Insufficient outbound liquidity

```text
total outbound liquidity 0 is insufficient
```

A connected node does not automatically have outbound payment capacity. It needs a Ready channel with sufficient local balance.

Payment readiness now analyzes:

- invoice validity and expiry,
- route availability,
- outbound liquidity,
- estimated fee,
- route parts,
- payment failure reason.

Possible results are:

```text
READY
RISKY
UNPAYABLE
```

### Key learning

Connectivity is not the same as payment readiness. A peer can be online while the local node still has zero usable outbound liquidity.

---

## 11. Multi-Hop, MPP, and Trampoline Routing

Week 3 also introduced routing beyond a direct channel.

The transfer console supports:

- dry-run payments,
- maximum fee limits,
- timeout configuration,
- maximum route parts,
- trampoline hops,
- explicit multi-hop route construction.

Validation was added for:

- a maximum of five trampoline hops,
- duplicate trampoline nodes,
- missing maximum fee configuration,
- using the final recipient as a trampoline hop,
- incompatible combinations of MPP and multiple trampoline hops.

The two-node lab creates separate browser profiles and provides a repeatable workflow:

```text
Node A → Relay A → Public Channel A
Node B → Relay B → Public Channel B
Node B creates invoice
Node A runs readiness
Node A sends payment
Fiber graph routes payment across available channels
```

### Key learning

Multi-hop payments depend on public channel gossip, local outbound liquidity, remote route capacity, fee policies, and invoice capabilities.

---

## 12. FiberOps Control Center

The project now includes an operations workspace for monitoring the browser node and payment system.

### Operations Overview

- node health,
- connected peers,
- active channels,
- local and remote balance,
- open incidents,
- runtime compatibility.

### Channel Health

Each channel is evaluated using:

- channel state,
- enabled/disabled status,
- local and remote balances,
- outbound-liquidity ratio,
- pending TLC count.

The result is classified as:

```text
HEALTHY
WARNING
CRITICAL
```

### Reconciliation

Reconciliation compares invoice and payment state using a payment hash. It detects missing or inconsistent lifecycle information before an operator retries a payment.

### Incident Center

Unhealthy channels and reconciliation mismatches are converted into operator-facing incidents with diagnoses and recommended actions.

### AI Copilot

The AI layer is read-only by default. It can retrieve operational context, explain failures, and recommend actions, but it cannot automatically send payments or close channels.

---

## 13. Merchant Payment Architecture

FiberPay now separates payment state from merchant order state.

Payment lifecycle:

```text
CREATED
  ↓
INVOICE_CREATED
  ↓
WAITING_PAYMENT
  ↓
IN_FLIGHT
  ↓
SETTLED
```

Merchant order lifecycle:

```text
ORDER_CREATED
  ↓
PAYMENT_PENDING
  ↓
PAID
  ↓
FULFILLMENT_PENDING
  ↓
COMPLETED
```

The Rust API stores:

- merchant orders,
- payment attempts,
- payment hashes,
- invoice addresses,
- fees and route parts,
- failures,
- audit logs.

Write operations can use an `Idempotency-Key`. Repeating the same create-order request with the same key returns the existing order instead of duplicating business state.

An outbox table was also introduced as a foundation for future asynchronous events and webhooks.

### Key learning

Fiber is the source of truth for payment execution, while PostgreSQL is the source of record for application and merchant state. These states need explicit reconciliation.

---

## 14. Rust Backend Evolution

Week 2 used a Java/Spring Boot backend. In Week 3, the service was rebuilt in Rust using Axum and Tokio.

The Rust service now provides:

- CKB RPC and indexer access,
- wallet challenge authentication,
- JWT authorization,
- transaction tracking,
- merchant orders,
- Fiber payment records,
- FiberOps snapshots,
- reconciliation,
- incidents,
- AI knowledge retrieval,
- read-only MCP tools,
- PostgreSQL migrations.

The backend does not receive user private keys. Wallet signing remains in CCC and the browser.

### PostgreSQL pool challenge

During free deployment testing, the service encountered:

```text
pool timed out while waiting for an open connection
```

The SQLx pool was updated to support configurable:

- maximum and minimum connections,
- connection-acquire timeout,
- idle timeout,
- maximum connection lifetime.

The recommended serverless configuration uses a pooled Neon connection URL, zero minimum idle connections, and recycled connections.

This was an important lesson about adapting a conventional connection pool to a serverless database and sleeping free-tier services.

---

## 15. Deployment Architecture

The project includes two deployment approaches.

### Docker deployment

```text
Nginx Portal
   │
   ├── React SPA
   ├── COOP / COEP headers
   └── /api reverse proxy
             │
             ▼
        Rust Axum API
             │
             ▼
         PostgreSQL
```

Docker configuration includes:

- multi-stage portal image,
- Nginx SPA fallback,
- Fiber isolation headers,
- Rust release image,
- health checks,
- PostgreSQL persistence,
- automatic embedded migrations.

### Free testnet deployment

```text
Vercel Hobby → Portal
Render Free  → Rust API
Neon Free    → PostgreSQL
```

This stack is useful for testnet demonstrations, but not for real merchant SLAs because free services can sleep and have usage limits.

---

## 16. Continuous CKB RPC Activity

Running a Fiber browser node creates continuous CKB RPC traffic because the node needs to follow chain state and funding transactions.

Additional application polling includes:

- transaction SSE polling,
- pending transaction refresh,
- FiberOps telemetry refresh,
- CKB tip queries.

This led to a clearer distinction between necessary protocol synchronization and optional UI polling.

Future improvements should:

- pause UI polling when the tab is hidden,
- use slower intervals for non-critical telemetry,
- stop transaction polling after terminal states,
- use a dedicated RPC service for production workloads.

---

## 17. Testing and Verification

The Week 3 project includes tests for:

- CKB amount/unit conversion,
- external funding transaction invariants,
- browser peer-address validation,
- Fiber public-key validation,
- raw TCP rejection for browser peers.

The deployment process also verifies:

- TypeScript compilation,
- Vite production build,
- Rust `cargo check`,
- Docker Compose configuration,
- cross-origin-isolation headers on every Fiber route.

The header verifier checks routes including:

```text
/checkout
/merchant
/fiber-node
/fiber-ops
/fiber-ai
/fiber-transfers
/fiber-lab
```

---

## 18. Main Challenges

### 18.1 Browser networking limitations

Fiber documentation often assumes a native node. A browser node needs WSS and cannot use raw TCP peer addresses.

### 18.2 Wallet funding invariants

Wallets may modify inputs, outputs, CellDeps, or witnesses while completing a CKB transaction. Fiber external funding must detect unsupported structural changes.

### 18.3 Liquidity before payments

A successful peer connection does not create outbound liquidity. Payments remain unavailable until the channel is funded and Ready.

### 18.4 Cross-origin isolation versus popup wallets

The security headers required by SharedArrayBuffer can interfere with popup-based wallet flows.

### 18.5 Multi-system state

Merchant orders, Fiber invoices, Fiber payments, channel state, and CKB settlement can temporarily disagree. This makes idempotency and reconciliation essential.

### 18.6 Free deployment constraints

Free API and database services may sleep, recycle connections, impose rate limits, or delay the first request.

---

## 19. Key Learnings

The most important Week 3 lessons were:

1. **Fiber extends CKB rather than replacing it.**

   Fiber handles instant payments, while CKB remains the settlement and asset layer.

2. **A browser can run a real non-custodial Fiber node.**

   WASM, Workers, IndexedDB, and WSS make this possible, but introduce browser-specific constraints.

3. **Connectivity, channel readiness, and liquidity are separate conditions.**

   All three must be valid before a payment can succeed.

4. **Dry runs are an important payment-safety mechanism.**

   Route and fee validation should happen before committing funds.

5. **Payment state and business state must be modeled independently.**

   Reconciliation connects them without incorrectly treating the database as the payment network.

6. **Idempotency is essential for payment APIs.**

   Network retries must not create duplicate orders or duplicate payment attempts.

7. **AI should not be in the critical fund-control path.**

   It is useful for explanation and diagnosis, while deterministic code and operator approval control real actions.

8. **Deployment headers and connection pools are part of application correctness.**

   Fiber WASM cannot start without isolation, and a service cannot remain reliable if its database pool is not tuned for its hosting model.

---

## 20. Week 3 Outcome

By the end of Week 3, the project had evolved from a general CKB developer playground into a focused Fiber payment platform.

The implemented platform now demonstrates:

```text
Browser Fiber WASM Node
        +
WSS Peer Connectivity
        +
CKB Wallet Channel Funding
        +
Fiber Invoices and Payments
        +
Readiness and Routing
        +
Merchant Orders and Idempotency
        +
Channel Health and Reconciliation
        +
Rust API and PostgreSQL
        +
Deployment and Observability Foundations
```

The project remains testnet-oriented, but it now addresses real payment-system concerns rather than only protocol demonstrations.

---

## 21. Plan for Week 4

The next development stage should focus on reliability and a complete end-to-end testnet demonstration.

Planned work:

- Complete a repeatable two-node multi-hop payment test.
- Improve channel funding compatibility across supported CCC wallets.
- Add visibility-aware and backoff-based RPC polling.
- Add webhook endpoints, HMAC signatures, retries, and delivery history.
- Add a background outbox worker.
- Improve tenant and merchant role boundaries.
- Add richer payment-attempt and reconciliation history.
- Add OpenTelemetry metrics for payment latency, failures, liquidity, and database-pool usage.
- Test xUDT payments over Fiber.
- Trigger Spore receipts and xUDT rewards asynchronously after successful payments.
- Add browser end-to-end tests for Checkout, Merchant, and FiberOps.
- Complete free testnet deployment and document live application evidence.

The main Week 4 objective is:

```text
Invoice
  ↓
Readiness
  ↓
Multi-hop Fiber payment
  ↓
Merchant order settled
  ↓
Webhook delivered
  ↓
CKB asset action queued
```

---

## 22. Summary

Week 3 was focused on applying CKB knowledge to a practical Fiber payment application.

I worked with:

- Fiber WASM and browser node lifecycle,
- WSS peer connectivity,
- channel funding with CKB,
- invoice creation and payment,
- route readiness and liquidity,
- multi-hop, MPP, and trampoline routing,
- merchant order state,
- idempotency and reconciliation,
- Rust/Axum services,
- PostgreSQL persistence,
- cross-origin-isolated deployment,
- free testnet hosting constraints.

The most important outcome is a clearer full-stack understanding of how CKB and Fiber work together:

```text
React + CCC + Fiber WASM
          ↓
Instant payment execution
          ↓
Rust orchestration and operational state
          ↓
CKB settlement, ownership, and assets
```

FiberPay is now a stronger foundation for continuing into production-oriented Fiber infrastructure, merchant payments, and CKB asset integration.
