# Cell Model

A Cell is a fundamental state unit in CKB.

```text
Cell
├── Capacity
├── Data
├── Lock Script
└── Type Script
```

Cells are immutable. State transitions consume old Cells and create new Cells.

```text
Old Cell
   ↓
Transaction
   ↓
New Cell
```
