# 🛰️ Orbital Debris Reclamation & DePIN Recycling System (v3.0)
An advanced, cross-chain DePIN (Decentralized Physical Infrastructure) & Social Impact smart contract built on Solidity (^0.8.20) for the "Want to Mars" ecosystem (Galileo Network / SimpleChain).

## 🚀 Cross-Chain Deployment Info
* **Contract Address (This Base/Vault):** 0x821273fccd93cca8a1f357c94c9ef83c6b5c6829
* **Linked Orbit Autopilot (LitVM):** 0xd1837aBD2E9796900DeE10DC6C1D70833a1eE291
* **Compiler Version:** Solidity v0.8.34 (Optimization: No, EVM: Osaka)

📜 Scenario & Mechanics
This smart contract manages the physical reclamation, tracking, and incentivized recycling of fallen aerospace/orbital debris with built-in social relief fund routing and cross-chain automation:

* **Cross-Chain Budget Locking**: The linked satellite controller on LitVM can directly trigger budget reservation (`lockDebrisBudget`) inside this vault prior to physical orbital capture.
* **DePIN Asset Registration**: The central admin or linked satellite registers dropped orbital scrap specifying tracking specs, metal composition (Titanium, Aluminum, Steel, Copper, RareEarth), and weight.
* **Automated Reward Split**: Upon recycling verification, rewards are distributed via an 80/20 split:
  * 80% to the primary Smelter Facility.
  * 20% to the field Scrapper / Collector.
* **Social Relief Hub Integration**: If a scrapper address is registered as an active Social Relief Hub, its 20% share is automatically rerouted to a secured multisig fund vault.
* **Pull Payment & Expiration**: Beneficiaries withdraw earned yield via a secure pull-payment pattern. Unclaimed rewards inactive for >30 days can be reclaimed by administration.

🔄 Version 3.0 Refactoring Highlights (Cross-Chain Upgradability Patch)
* **Fractional Scrap Processing**: Handles fragmented debris. If an object broke apart during atmospheric entry, the contract scales rewards proportionally based on actual delivered weight.
* **Pluggable Modular Architecture**: Introduced the `economicPluginModule` state slot to connect future tax or business logic updates without modifying core linked code.
* **Inter-Contract Synchronization**: Integrated strict access controls (`onlySatellite`) to securely sync real-time orbital calculations with terrestrial financial vaults.

🌍 Socio-Economic Inclusivity & Off-Chain "Zero-Barrier" Onboarding
The **Social Relief Hub** module is specifically engineered to bridge the gap between high-tech decentralized infrastructure and marginalized, unbanked field collectors (Scrappers) who face extreme economic hardship and lack access to smartphones, internet, or Web3 wallets.

#### The Physical-to-Digital Care Proxy Cycle:
1. **Zero-Barrier Collection**: Impoverished or unbanked individuals can physically retrieve and deliver localized orbital debris directly to a certified Smelter Facility without any prior cryptographic setup or staking requirements.
2. **Automated Institutional Routing**: If a collector does not possess a Web3 address, the processing admin designates the recipient as an active *Social Relief Hub* address. The smart contract automatically splits the reward via the 80/20 standard, routing the 20% scrapper share directly into a secured Multisig Vault managed by a registered humanitarian entity.
3. **Physical Off-Ramp & Rehabilitation**: The designated Social Relief Hub acts as a physical custodian. Instead of direct token transfers, it converts the on-chain value into immediate, life-saving off-chain resources for the collector:
   * Emergency food security and clean water.
   * Sanitary and medical care access.
   * Clothing and temporary shelter onboarding.
4. **Liquidity Distribution**: The remaining balance of the earned reward is safely held and distributed to the collector by the hub in local fiat currency or physical resources, empowering underrepresented participants to transition from survival to stable, long-term protocol engagement.

🛠️ Security & Architecture Features
* **Pull-Payment Dividend Pattern**: Zeroes pending balances prior to executing modern `.call{value: amount}("")` native transfers to eliminate Reentrancy risks.
* **Fractional Reward Scaling Safeguards**: Enforces strict checks to prevent scrap inflation beyond the initially locked orbital budget pool.
* **Time-Locked Recovery**: Admin can only recover abandoned funds after a strict 30-day timelock (`block.timestamp >= timestamp + 30 days`).

💻 Contract Roles
* **System Admin (`admin`)**: Manages social hubs, approves fractional scrap processing, and updates modules.
* **Satellite Controller (`satelliteController`)**: Autonomous orbit autopilot allowed to lock budgets and push physics specs.
* **Smelter Facility (`_smelterAddress`)**: Receives 80% processing reward.
* **Scrapper / Collector (`_scrapperAddress`)**: Receives 20% field collection reward.
* **Social Relief Hub (`socialHubs`)**: Reroutes collector rewards to designated community/relief vaults.

🚀 Technical Overview
* **Solidity Version:** ^0.8.20
* **License:** MIT
* **Ecosystem:** Galileo Network / SimpleChain / LitVM Interop
* **Category:** DePIN / Real World Recycling / Social Impact

