# CKBuilder Weekly Report — Week 1

## 1. Overview

**Program:** CKBuilder  
**Week:** Week 1  
**Focus:** CKB Environment Setup, Fundamentals & Basic Exercises  
**Repository:** `nervos-ckb-playground`

This week focused on setting up a local Nervos CKB development environment, understanding the CKB Cell Model and transaction fundamentals, and completing the first practical CKB exercise.

The main hands-on work was based on the CKBuilder **Basic Exercises** tutorials. All five exercises were completed, with screenshots retained as proof of participation and completion.

## 2. Goals for Week 1

- [x] Set up a GitHub repository for the CKBuilder learning journey.
- [x] Set up a local CKB development environment.
- [x] Install and explore OffCKB.
- [x] Run a local CKB Devnet.
- [x] Understand RPC communication with a CKB node.
- [x] Study CKB Layer 1 and the Cell Model.
- [x] Understand transactions, Inputs and Outputs.
- [x] Understand CKByte / capacity.
- [x] Understand Lock Scripts and Type Scripts.
- [x] Complete the Basic Exercises tutorials.
- [x] Complete the **Transfer CKB** exercise.
- [x] Complete the **Store Data on Cell** exercise.
- [x] Complete the **Create Fungible Token** exercise.
- [x] Complete the **Create DOB** exercise.
- [x] Complete the **Build a Simple Lock** exercise.
- [x] Retain screenshots as evidence and record the work in the development log.

## 3. Development Environment

- Windows
- Node.js / npm
- OffCKB CLI
- Git / GitHub
- Visual Studio Code

## 4. Local CKB Devnet

### Install

```bash
npm install -g @offckb/cli
```

### Start

```bash
offckb node
```

### Stop

```text
CTRL+C
```

### Reset

```bash
offckb clean
```

### Local RPC Endpoints

When OffCKB is running locally, the CKB Devnet and RPC Proxy are available at:

```text
CKB Devnet RPC:  http://127.0.0.1:8114
RPC Proxy:       http://127.0.0.1:28114
```

The `simple-transfer` example was successfully launched against the local Devnet.

## 5. CKB Fundamentals

### CKB Layer 1

CKB is the Layer 1 blockchain of the Nervos ecosystem and provides the base layer for state, assets, verification, and security.

### Cell Model

CKB uses the Cell Model as its fundamental state representation.

```text
Cell
├── Capacity
├── Data
├── Lock Script
└── Type Script
```

Cells are consumed and recreated rather than updated directly.

```text
Old Cell
   ↓
Transaction
   ↓
New Cells
```

### Transaction

```text
Live Cells
   ↓
Inputs
   ↓
Transaction
   ↓
Outputs
   ↓
New Live Cells
```

### Lock Script

Lock Script answers:

```text
WHO can consume this Cell?
```

### Type Script

Type Script answers:

```text
HOW can the Cell/state change?
```

## 6. Basic Exercises

After setting up the environment and reviewing the technical concepts, the practical tutorials were started.

The CKBuilder Basic Exercises include:

| Exercise | Week 1 Status |
|---|---|
| Transfer CKB | **Completed** |
| Store Data on Cell | **Completed** |
| Create Fungible Token | **Completed** |
| Create DOB (Digital Object) | **Completed** |
| Build a Simple Lock | **Completed** |

All five Basic Exercises were completed during Week 1. Detailed example responses are intentionally not included in this report; completion is recorded here and supporting screenshots are retained as evidence.

## 6.1 Transfer CKB

**Status:** Completed

Completed the Transfer CKB tutorial and verified the transaction flow on the local CKB Devnet.

## 6.2 Store Data on Cell

**Status:** Completed

Completed the Store Data on Cell tutorial and practiced storing data in a CKB Cell.

## 6.3 Create Fungible Token

**Status:** Completed

Completed the Create Fungible Token tutorial and practiced the basic concepts involved in creating a fungible token on CKB.

## 6.4 Create DOB

**Status:** Completed

Completed the Create DOB (Digital Object) tutorial and practiced the basic concepts involved in creating a digital object on CKB.

## 6.5 Build a Simple Lock

**Status:** Completed

Completed the Build a Simple Lock tutorial and practiced the basic Lock Script development workflow.

For intensive smart contract development on CKB, Rust will be studied as the primary language for Script development.

## 7. L1 Developer Course

The CKB L1 Developer Course was also identified as a learning resource for understanding the theoretical aspects of CKB.

Some lab exercises use Lumos or Capsule. These are not the current focus and can be skipped where they are not required for the CKBuilder learning path.

## 8. Devnet / Testnet / Mainnet

| Network | Purpose |
|---|---|
| Devnet | Local development |
| Testnet | Public testing |
| Mainnet | Production |

## 9. RPC

Basic architecture:

```text
Application / CLI / SDK
          |
          | JSON-RPC
          v
      CKB Node
          |
          v
   CKB Blockchain
```

During Week 1, the local CKB RPC endpoint was verified and the `Transfer CKB` application successfully communicated with the local Devnet.

## 10. Hands-on Transaction

The `simple-transfer` example was used to perform a CKB transfer on the local Devnet.

The transaction returned the following hash:

```text
0xfe5a36d26993397c036d1b62c15a66d266fa3189c4731c87f2e9684416a16639
```

The transaction contained:

- **Input:** `10,000 CKB`
- **Output #0:** `62 CKB`
- **Output #1:** approximately `9,937.999999535 CKB`
- **Transaction fee:** approximately `0.000000465 CKB`

The transaction was subsequently inspected to verify its Input and Output Cells.

## 11. Evidence

All practical exercises should retain screenshots as proof of participation and completion.

### 11.1 Source Project

The Nervos Docs repository was cloned and the `simple-transfer` example was opened.

![Source Project](evidence/week-01/01-source-project.PNG)

### 11.2 CKB Devnet Running

OffCKB successfully started the local CKB Devnet and RPC Proxy.

![CKB Devnet Running](evidence/week-01/02-devnet-running.PNG)

### 11.3 Account and CKB Address

The `simple-transfer` application displayed the CKB account, address, Lock Script, and available capacity.

![Account and Address](evidence/week-01/03-account-address.PNG)

### 11.4 Transaction Hash

The Transfer CKB exercise was successfully submitted and a transaction hash was returned.

![Transaction Hash](evidence/week-01/04-transaction-hash.PNG)

### 11.5 Transaction Input and Output

The transaction was inspected and the Input/Output Cells were verified.

![Transaction Input and Output](evidence/week-01/05-transaction-input-output.PNG)

## 12. Challenges

The main conceptual challenge was moving from an account/balance mental model to the CKB Cell Model.

Traditional account model:

```text
Account
  ↓
Balance update
```

CKB Cell Model:

```text
Cell
  ↓
Consume
  ↓
Transaction
  ↓
Create new Cell
```

Working through the Transfer CKB exercise helped connect the theoretical Cell Model with an actual transaction.

## 13. Key Takeaways

- CKB is a Layer 1 blockchain.
- CKB uses the Cell Model.
- Transactions consume existing Cells and create new Cells.
- Inputs reference Cells being consumed.
- Outputs create new Cells.
- Lock Scripts control ownership / authorization.
- Type Scripts enforce application-specific state rules.
- Capacity represents the amount of CKBytes stored in a Cell.
- RPC allows applications to communicate with CKB nodes.
- OffCKB provides a convenient local development environment.
- A CKB transfer can be understood as consuming an existing Cell and creating new output Cells.
- Practical exercises are important for connecting CKB concepts with real transactions.

## 14. Next Week — Learn Building on CKB

Next week will focus on building applications on CKB using **JavaScript / TypeScript** and **CCC (Common Chain Connector)**.

### CCC

- Explore the CCC App.
- Test code in the CCC Playground.
- Study the CCC code examples.
- Explore the CCC API.
- Build basic CKB application flows using JavaScript / TypeScript.

### Rust and CKB Script Development

Rust is recommended for intensive smart contract development on CKB because of its efficiency, security, and strong tooling support.

Planned topics:

- Rust SDK.
- CKB Script development.
- CKB-CLI.
- Building and testing Scripts.
- Understanding Script arguments and execution.

### Other Developer Tools

Also explore the following tools and resources as needed:

- CKB Testnet Faucet.
- CKB Debugger.
- CKB Tools.

### Other SDK Languages

Explore the available CKB SDK/documentation for:

- Go
- Java

## 15. Payment Channels on CKB

CKB is designed as a secure and decentralized Layer 1 optimized for verification, while higher layers can provide scaling and high-throughput use cases.

Payment channel technologies are an important scaling direction on CKB.

The main payment channel projects to explore are:

### Fiber Network

A Lightning-compatible peer-to-peer payment channel and swap network built on CKB.

### Perun

An Ethereum-compatible peer-to-peer payment channel and swap solution for CKB.

These topics are secondary to the main Week 2 focus and can be explored after the CCC fundamentals.

## 16. Week 2 Checklist

- [ ] Explore CCC App.
- [ ] Run examples in the CCC Playground.
- [ ] Study CCC code examples.
- [ ] Explore CCC API.
- [ ] Build a basic JavaScript/TypeScript CKB application.
- [ ] Start Rust fundamentals for CKB Script development.
- [ ] Explore Rust SDK.
- [ ] Explore CKB-CLI.
- [ ] Explore CKB Debugger.
- [ ] Explore CKB Tools.
- [ ] Review Fiber Network and Perun at a high level.
