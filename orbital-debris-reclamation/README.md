# 🛰️ Orbital Debris Reclamation & DePIN Recycling System (v2.0)

An advanced **DePIN (Decentralized Physical Infrastructure) & Social Impact** smart contract built on Solidity (`^0.8.20`) for the **"Want to Mars" ecosystem (Galileo Network)**.

---

## 📜 Scenario & Mechanics
This smart contract manages the physical reclamation, tracking, and incentivized recycling of fallen aerospace/orbital debris with built-in social relief fund routing:

1. **DePIN Asset Registration:** The central admin registers dropped orbital scrap specifying physical land-grid coordinates (e.g., `"Nevada, Area 51"`), metal composition (`Titanium`, `Aluminum`, `Steel`, `Copper`, `RareEarth`), weight, and native ETH reward pools.
2. **Automated Reward Split:** Upon recycling verification, rewards are distributed via an **80/20 split**:
   - **80%** to the primary **Smelter Facility**.
   - **20%** to the field **Scrapper / Collector**.
3. **Social Relief Hub Integration:** If a scrapper address is registered as an active **Social Relief Hub**, its 20% share is automatically rerouted to a secured multisig fund vault.
4. **Pull Payment & Expiration:** Beneficiaries withdraw earned yield via a secure pull-payment pattern. Unclaimed rewards inactive for >30 days can be reclaimed by administration.

---

## 🔄 Version 2.0 Refactoring Highlights (Hackathon Patch)

- **Social Relief Fund Vault Rerouting:** Fixed logical split so scrapper rewards redirect straight to designated fund vault wallets instead of circular address mappings.
- **Timestamp Lockout Fix:** Optimised `_addPendingBalance` so accumulating payouts do **not** reset the 30-day withdrawal timer for active accounts.
- **Gas Optimizations:** Migrated string parameters to `calldata` and marked functions as `external`.
- **Land-Grid Standard:** Standardized asset coordinate tracking to match physical DePIN geolocation specifications.

---

## 🛠️ Security & Architecture Features

- **Pull-Payment Dividend Pattern:** Zeroes pending balances prior to executing modern `.call{value: amount}("")` native transfers to eliminate Reentrancy risks.
- **Active Balance Timer Protection:** Prevents indefinite fund lockups when multiple payments are sent to the same address.
- **Time-Locked Recovery:** Admin can only recover abandoned funds after a strict 30-day timelock (`block.timestamp >= timestamp + 30 days`).

---

## 💻 Contract Roles

| Role / Entity | Variable / Address | Description |
| :--- | :--- | :--- |
| **System Admin** | `admin` | Registers dropped assets, approves scrap processing, manages social hubs |
| **Smelter Facility** | `_smelterAddress` | Receives 80% processing reward |
| **Scrapper / Collector** | `_scrapperAddress` | Receives 20% field collection reward |
| **Social Relief Hub** | `socialHubs` | Reroutes collector rewards to designated community/relief vaults |

---

## 🚀 Technical Overview

- **Solidity Version:** `^0.8.20`
- **License:** MIT
- **Ecosystem:** Galileo Network / "Want to Mars"
- **Category:** DePIN / Real World Recycling / Social Impact
