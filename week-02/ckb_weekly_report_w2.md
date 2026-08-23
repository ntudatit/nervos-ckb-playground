# CKBuilder Weekly Report — Week 2

## 1. Overview

**Program:** CKBuilder  
**Week:** Week 2  
**Focus:** Building on CKB with JavaScript/TypeScript and CCC; initial exploration of Rust and CKB Script development  
**Project:** Nervos CKB Playground Portal + Backend Service  

During Week 2, I moved from the basic CKB exercises completed in Week 1 into building a more complete CKB application using **React, TypeScript, and CCC (Common Chain Connector)**.

The main goal was to understand how a real frontend application interacts with CKB through a connected wallet, how CCC simplifies wallet and transaction handling, and how common CKB operations can be implemented as reusable product features instead of isolated scripts.

I also extended the project with a backend service for CKB RPC access and transaction tracking. In parallel, I started exploring the Rust/CKB Script development path to understand where on-chain validation logic fits compared with application-side JavaScript/TypeScript development.

---

## Project Links

- **Live Application:** https://ntudatit.github.io/nervos-ckb-playground-portal/
- **Frontend Repository:** https://github.com/ntudatit/nervos-ckb-playground-portal
- **Backend Service Repository:** https://github.com/ntudatit/nervos-ckb-playground-service

## 2. Week 2 Goals

The main learning goals for this week were:

- Learn the role of **CCC** in CKB dApp development.
- Connect a CKB wallet through a unified React integration.
- Read the connected wallet address and CKB balance.
- Build, complete, sign, and broadcast CKB transactions.
- Store UTF-8 application data inside CKB Cells.
- Read a live Cell and decode the stored data.
- Experiment with **xUDT fungible tokens**.
- Experiment with **Spore/DOB digital objects**.
- Sign and verify messages without broadcasting a transaction.
- Connect the frontend to a backend for transaction tracking and CKB RPC access.
- Begin understanding the difference between:
  - application development with JavaScript/TypeScript and CCC, and
  - on-chain validation using Rust/CKB Scripts.

---

## 3. Development Stack

### Frontend

- React 18
- TypeScript
- Vite
- React Router
- `@ckb-ccc/connector-react`
- `@ckb-ccc/spore`
- Lucide React

### Backend

- Java
- Spring Boot
- PostgreSQL
- Flyway
- CKB JSON-RPC integration
- REST APIs for transaction tracking and dashboard data

### CKB Environment

- CKB Testnet / configurable CKB network
- CCC unified wallet Signer
- CKB RPC
- xUDT
- Spore Protocol

---

# 4. JavaScript / TypeScript + CCC

## 4.1 Integrating CCC into the React Application

The first major task was integrating CCC into the React application.

CCC provides a unified abstraction around CKB-compatible wallets and exposes React hooks that make wallet integration much easier.

The application is wrapped in a `ccc.Provider`, allowing the application to switch between supported CKB clients such as Testnet and Mainnet.

Example concept:

```tsx
<ccc.Provider
  name="CKB CCC Starter"
  defaultClient={new ccc.ClientPublicTestnet()}
  clientOptions={[
    {
      name: "CKB Testnet",
      client: new ccc.ClientPublicTestnet(),
    },
    {
      name: "CKB Mainnet",
      client: new ccc.ClientPublicMainnet(),
    },
  ]}
>
  <App />
</ccc.Provider>
```

The important CCC hooks used in the project are:

```ts
ccc.useCcc()
ccc.useSigner()
```

`useCcc()` is useful for wallet connection state and wallet UI operations, while `useSigner()` provides the active signer used for blockchain operations.

### What I learned

A major benefit of CCC is that application code does not need to be tightly coupled to one specific wallet implementation.

Once a CCC `Signer` is available, the same signer can be reused for:

- reading addresses,
- checking balances,
- signing messages,
- composing transactions,
- sending transactions,
- xUDT operations,
- Spore operations.

---

# 5. Wallet Connection and Account Information

I created a reusable wallet hook that retrieves:

- the recommended CKB address,
- the current CKB balance,
- loading state,
- wallet errors.

Example:

```ts
const signer = ccc.useSigner();

const [address, balance] = await Promise.all([
  signer.getRecommendedAddress(),
  signer.getBalance(),
]);

const balanceCkb = ccc.fixedPointToString(balance);
```

This provides the account context required by the rest of the application.

### Key learning

The wallet is not only an authentication mechanism.

In a CKB dApp, the signer is also responsible for blockchain-specific operations such as locating spendable Cells, signing transactions, and broadcasting them.

---

# 6. Transfer CKB

One of the main Week 2 features was rebuilding the CKB transfer flow using CCC.

Instead of manually constructing every low-level transaction field, the application declares the desired output and lets CCC complete the remaining transaction requirements.

The transaction flow is:

```text
Recipient Address
      ↓
Convert Address → Lock Script
      ↓
Create Transaction Output
      ↓
Collect Input Cells
      ↓
Calculate Fee + Change
      ↓
Wallet Approval
      ↓
Sign Transaction
      ↓
Broadcast
      ↓
Transaction Hash
```

The core implementation follows this pattern:

```ts
const { script: lock } = await ccc.Address.fromString(
  receiver,
  signer.client,
);

const tx = ccc.Transaction.from({
  outputs: [
    {
      capacity: ccc.fixedPointFrom(amount),
      lock,
    },
  ],
});

await tx.completeInputsByCapacity(signer);
await tx.completeFeeBy(signer, feeRate);

const txHash = await signer.sendTransaction(tx);
```

### Transaction Preview

Before sending the transaction, the UI displays a transaction preview.

This helped me understand the difference between:

1. declaring transaction intent,
2. completing inputs and fees,
3. approving the final transaction in the wallet.

### Key learning

CKB transactions are based on consuming and creating **Cells**, rather than simply modifying an account balance.

CCC significantly reduces the complexity of Cell selection, change generation, and transaction fee calculation.

---

# 7. Store Data on a CKB Cell

I implemented a feature that stores UTF-8 text directly in the data field of a CKB output Cell.

The flow is:

```text
User Message
    ↓
UTF-8 Encoding
    ↓
Hex Data
    ↓
Create Output Cell
    ↓
Complete Inputs + Fee
    ↓
Sign and Broadcast
    ↓
Wait for Live Cell
    ↓
Read Output Cell
    ↓
Decode Hex → UTF-8
```

The application converts the input string into bytes:

```ts
function utf8ToHex(value: string): `0x${string}` {
  const bytes = new TextEncoder().encode(value);

  return `0x${Array.from(
    bytes,
    b => b.toString(16).padStart(2, "0"),
  ).join("")}`;
}
```

The encoded bytes are added to `outputsData`.

```ts
const tx = ccc.Transaction.from({
  outputs: [
    {
      lock: owner.script,
      capacity: ccc.fixedPointFrom(capacity),
    },
  ],
  outputsData: [data],
});
```

After the transaction is committed, the application can retrieve output `0` as a live Cell:

```ts
const cell = await signer.client.getCellLive(
  {
    txHash,
    index: "0x0",
  },
  true,
);
```

The output data is then decoded back into the original message.

### Key learning

A CKB Cell can contain both:

- assets/capacity,
- application data.

This makes the Cell Model useful for much more than simple CKB transfers.

---

# 8. Fungible Token with xUDT

I also started working with fungible assets through **xUDT**.

The application creates an xUDT type Script using CCC:

```ts
const type = await ccc.Script.fromKnownScript(
  signer.client,
  ccc.KnownScript.XUdt,
  tokenArgs,
);
```

The user's lock Script hash can be used as an issuer identifier.

```ts
const owner = await signer.getRecommendedAddressObj();
const tokenArgs = owner.script.hash();
```

The application supports two main actions:

- Mint xUDT
- Transfer xUDT

Example mint flow:

```ts
const udt = await createUdt(signer, tokenArgs);

let { res: tx } = await udt.mint(signer, [
  {
    to,
    amount: ccc.fixedPointFrom(amount),
  },
]);

await tx.completeInputsByCapacity(signer);
await tx.completeFeeBy(signer);

const txHash = await signer.sendTransaction(tx);
```

### Key learning

CKB token ownership is represented through Cells and type Scripts.

This is different from the smart-contract storage model normally used by account-based blockchains.

---

# 9. DOB / Spore Protocol

Another feature explored this week was creating digital objects with **Spore Protocol**.

The frontend uses:

```ts
import {
  createSpore,
  transferSpore,
  meltSpore,
} from "@ckb-ccc/spore";
```

The current implementation supports:

- Create Spore
- Transfer Spore
- Melt Spore

Example creation:

```ts
const { tx, id } = await createSpore({
  signer,
  data: {
    contentType: "text/plain",
    content: new TextEncoder().encode(content),
  },
});

await tx.completeInputsByCapacity(signer);
await tx.completeFeeBy(signer);

const txHash = await signer.sendTransaction(tx);
```

The created Spore receives a unique ID that can later be used for transfers or melting.

### Key learning

Spore provides a practical example of how CKB Cells can represent persistent digital objects and ownership.

This helped connect the Cell Model concepts from Week 1 with a more application-oriented use case.

---

# 10. Message Signing and Verification

I implemented a Sign Message feature using CCC.

Unlike a blockchain transaction, signing a message does not need to create or consume any Cells.

The wallet signs the message:

```ts
const result = await signer.signMessage(message);
```

The application then verifies it:

```ts
const verified = await ccc.Signer.verifyMessage(
  message,
  result,
);
```

The UI displays:

- signature,
- wallet identity,
- signing type,
- verification result.

### Key learning

Message signing can be used to prove wallet ownership without sending an on-chain transaction.

This can later be extended into wallet-based authentication for a production application.

---

# 11. Backend Integration

Although CCC handles signing and blockchain interaction from the wallet, I also added a backend service for application-level responsibilities.

The backend currently provides:

```text
GET  /api/health
GET  /api/ckb/network
GET  /api/ckb/tip
GET  /api/ckb/transactions/{txHash}

POST /api/transactions
GET  /api/transactions/{txHash}/status

GET  /api/dashboard/{address}
```

The backend connects to a configurable CKB RPC endpoint.

Example CKB RPC methods used:

```text
get_tip_block_number
get_transaction
```

---

# 12. Transaction Tracking

After CCC broadcasts a transaction, the frontend sends the resulting transaction hash to the backend.

Example:

```ts
await backendApi.trackTransaction({
  txHash: hash,
  walletAddress,
  recipient,
  amountCkb: amount,
  direction: "SEND",
});
```

The backend stores transaction metadata in PostgreSQL and checks the transaction status from CKB RPC.

Possible lifecycle:

```text
Transaction Broadcast
       ↓
pending
       ↓
proposed
       ↓
committed
```

or:

```text
pending
   ↓
rejected
```

The backend updates non-final transactions when dashboard/status APIs are requested.

### Key learning

The blockchain should remain the source of truth for transaction status, while the application database can maintain user-friendly metadata and history.

This separation is useful for building production-oriented blockchain applications.

---

# 13. Application Structure

The Week 2 project is no longer a single exercise.

It has started to become a small CKB developer portal with separate pages for different CKB concepts.

Current frontend areas include:

```text
Dashboard
Wallet
Cells
Transactions
Explorer
Faucet
dApps
Examples
Docs
```

Feature pages include:

```text
Transfer CKB
Store Data on Cell
Fungible Token
DOB / Spore
Sign Message
```

Guide pages include:

```text
Connect Wallets
Compose Transactions
Sign Messages
UDT Tokens
Spore Protocol
Node / Backend
Playground
```

This structure allows each CKB concept to be explored independently while sharing the same wallet and application architecture.

---

# 14. Architecture

The current high-level architecture is:

```text
┌───────────────────────────────────────────────┐
│               React + TypeScript              │
│                                               │
│  Wallet │ Transfer │ Cells │ xUDT │ Spore    │
│              │                                │
│              ▼                                │
│       CCC React Connector / Signer            │
└──────────────┬────────────────────────────────┘
               │
               │ sign / send
               ▼
        CKB Wallet + CKB Network
               │
               │ tx hash / chain state
               ▼
┌───────────────────────────────────────────────┐
│             Spring Boot Backend               │
│                                               │
│  CKB RPC │ Transaction Tracking │ Dashboard  │
└──────────────┬────────────────────────────────┘
               │
               ▼
           PostgreSQL
```

The important architectural boundary is that private-key signing stays with the user's wallet.

The backend never needs access to the user's private key.

---

# 15. Rust and CKB Script Exploration

The second learning direction for Week 2 was starting to explore **Rust and CKB Script development**.

This is still an initial exploration rather than a completed Rust contract implementation in the current project.

The key distinction I learned is:

### JavaScript / TypeScript + CCC

Used mainly for:

- dApp frontend logic,
- wallet interaction,
- transaction construction,
- sending transactions,
- interacting with existing Scripts and protocols.

### Rust / CKB Script

Used when the application needs custom **on-chain validation rules**.

A CKB Script validates whether a Cell can be created or consumed according to predefined rules.

Conceptually:

```text
Application
    │
    │ builds transaction
    ▼
Transaction
    │
    │ consumes / creates Cells
    ▼
CKB Script
    │
    │ validates transaction
    ▼
Accept / Reject
```

This makes the Rust/Script layer fundamentally different from normal backend business logic.

---

# 16. Initial CKB Script Concepts Studied

The concepts I started reviewing include:

- Lock Script
- Type Script
- `code_hash`
- `hash_type`
- `args`
- Script arguments
- Transaction inputs and outputs
- Cell dependencies
- Script validation
- CKB-VM
- Rust-based Script development

### Lock Script

A Lock Script controls **who is allowed to consume a Cell**.

### Type Script

A Type Script controls **how a Cell behaves or what rules its data/asset must satisfy**.

This separation is one of the most important concepts in CKB development.

---

# 17. Challenges

## 17.1 Understanding Cell-Based Transactions

The biggest conceptual shift is that CKB does not simply update balances.

Every transaction consumes existing Cells and creates new Cells.

Thinking in terms of:

```text
inputs → validation → outputs
```

made the transaction model much clearer.

---

## 17.2 Minimum Cell Capacity

A Cell needs enough capacity to store its structure and data.

This became visible in both:

- transferring CKB,
- storing text in Cell data.

When storing larger data, the required capacity must also increase.

---

## 17.3 Transaction Completion

A transaction declaration is not automatically ready for signing.

CCC still needs to:

```ts
completeInputsByCapacity(...)
completeFeeBy(...)
```

before the transaction is complete.

This helped me understand the distinction between describing the desired transaction and producing a valid final transaction.

---

## 17.4 Asynchronous Transaction State

Immediately after broadcasting a transaction, its output may not yet be available as a live Cell.

The application has to consider transaction lifecycle states instead of assuming immediate confirmation.

This motivated the transaction tracking functionality in the backend.

---

## 17.5 Separating Wallet Responsibilities from Backend Responsibilities

It was important not to move blockchain signing into the backend.

The current architecture keeps:

```text
Wallet:
- private key
- signing
- transaction approval

Frontend + CCC:
- transaction composition
- wallet interaction

Backend:
- RPC queries
- tracking
- persistence
- dashboard/API
```

This provides a cleaner and safer architecture.

---

# 18. Key Learnings

The most important lessons from Week 2 were:

1. **CCC makes CKB dApp development significantly easier.**

   It provides a common interface for wallets, signers, addresses, Cells, transactions, and supported CKB protocols.

2. **The CKB Cell Model becomes much clearer when building real features.**

   Transfer, Cell data, tokens, and Spores are all variations of consuming and creating Cells under Script rules.

3. **Transaction construction is declarative.**

   The application declares the desired outputs, while CCC can help collect inputs and calculate fees/change.

4. **Wallet signing should remain client-side.**

   The application backend does not need access to private keys.

5. **Blockchain transaction state is asynchronous.**

   Production applications need transaction lifecycle tracking instead of treating broadcasting as final confirmation.

6. **xUDT and Spore demonstrate how general the Cell Model is.**

   Cells can represent currency, tokens, state, application data, and digital objects.

7. **Rust becomes important when custom validation logic is needed.**

   JavaScript/TypeScript is excellent for dApp interaction, but custom on-chain rules belong in CKB Scripts.


---

# 20. Week 2 Outcome

By the end of Week 2, I had moved from executing isolated CKB examples to building a reusable application architecture around CKB.

The project can now demonstrate several core concepts through a unified interface:

```text
Wallet Connection
      +
CKB Transfer
      +
Cell Data
      +
xUDT
      +
Spore / DOB
      +
Message Signing
      +
CKB RPC
      +
Transaction Tracking
```

This gave me a better understanding of how frontend wallet interaction, CKB transactions, Cells, Scripts, protocols, backend services, and persistent application state can work together in a real dApp architecture.

The Rust/CKB Script track is still at the exploration stage and will be developed further in the following weeks.

---

# 21. Plan for Week 3

For Week 3, I plan to go deeper into **CKB Script development with Rust** while continuing to improve the CCC application.

Planned areas:

- Set up a stable Rust + CKB Script development environment.
- Build a minimal custom Lock Script.
- Understand Script execution through CKB-VM.
- Study `Script`, `CellDep`, `Witness`, and transaction validation in more depth.
- Write tests for the custom Script.
- Deploy the Script to a local/devnet environment.
- Integrate the custom Script into the existing TypeScript/CCC portal.
- Improve transaction lifecycle handling in the application.
- Continue documenting implementation evidence and technical learnings.

The main objective for the next stage is to connect both sides of CKB development:

```text
TypeScript + CCC
        ↓
Build Transactions
        ↓
Custom Rust CKB Script
        ↓
On-chain Validation
```

This should turn the project from a CCC-based blockchain application into a deeper full-stack CKB project with both off-chain application logic and custom on-chain validation.

---

## 22. Summary

Week 2 was focused on turning CKB fundamentals into working application features.

I practiced CKB development through:

- JavaScript/TypeScript
- React
- CCC
- wallet integration
- CKB transaction composition
- Cell data
- xUDT
- Spore
- message signing
- CKB RPC
- backend transaction tracking

At the same time, I began exploring how **Rust and CKB Scripts** provide the next layer of CKB development by defining custom validation logic at the blockchain level.

This week helped bridge the gap between learning the Cell Model conceptually and applying it in a more realistic full-stack CKB application.
