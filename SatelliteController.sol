// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SatelliteController
 * @dev Autonomous Orbit Operations & Satellite Autopilot powered by Decentralized Autonomous Agents.
 * Refactored state handling & security checks.
 */
contract SatelliteController {
    
    // --- 🛡️ ACCESS CONTROL & SECURITY SETTINGS ---
    address public owner;              // Earth Control Center / Admin
    address public autonomousAgentPKP; // Address of the autonomous off-chain agent (PKP)
    address public baseFactoryAddress; // Processing Base / Recycling Vault Contract
    
    bool public emergencyStopped;      // Emergency kill switch from Earth
    
    // --- 🛰️ State Handling via Enum ---
    enum SatelliteState {
        Idle,         // 0 — Standby
        Navigating,   // 1 — Rendezvous / Navigation
        MadKing,      // 2 — Mad King Protocol (Active Burning)
        EcoBlocked    // 3 — Environmental Hazard Lockout
    }
    
    SatelliteState public currentSatelliteState;

    // --- 🌍 ENVIRONMENTAL LIMITS ---
    uint256 public maxOzoneHarmThreshold = 1000; // Maximum allowed atmospheric harm index per operation

    // --- 🛰️ DATA STRUCTURES ---
    struct DebrisTarget {
        uint32 length;               // Dimensions: Length (cm)
        uint32 width;                // Dimensions: Width (cm)
        uint32 height;               // Dimensions: Height (cm)
        uint32 weightKg;             // Mass in Kilograms
        uint8  aluminumPercent;      // Ratio of aluminum / toxic metals (0-100%)
        uint256 estRemovalCost;      // Estimated deorbiting cost
        bytes32 telemetryMerkleRoot; // Merkle root of telemetry & HD imaging (Off-chain Data)
        bool isBurnedInAtmosphere;
        bool isCapturedForBase;
        bool exists;                 // Protection against target ID overwrite
    }

    // Target Debris ID => Debris Data
    mapping(uint256 => DebrisTarget) public targets;
    
    // --- 📣 EVENTS ---
    event TargetRegistered(uint256 indexed targetId, bytes32 indexed telemetryMerkleRoot, uint256 estCost);
    event MadKingActivated(uint256 indexed targetId, string reason);
    event EcoBlockTriggered(uint256 indexed targetId, uint256 calculatedHarm);
    event DebrisDisposed(uint256 indexed targetId, string method);
    event EmergencyStateToggled(bool isStopped);

    // --- 🔒 ACCESS MODIFIERS ---
    modifier onlyEarth() {
        require(msg.sender == owner, "Security: Only Earth Control Center can execute!");
        _;
    }

    modifier onlyAutopilot() {
        require(msg.sender == autonomousAgentPKP || msg.sender == owner, "Security: Access Denied! Only Autonomous Agent allowed.");
        require(!emergencyStopped, "Security: System is in Emergency Lockout!");
        _;
    }

    constructor(address _autonomousAgentPKP, address _baseFactoryAddress) {
        owner = msg.sender;
        autonomousAgentPKP = _autonomousAgentPKP;
        baseFactoryAddress = _baseFactoryAddress;
        currentSatelliteState = SatelliteState.Idle;
    }

    // --- ⚙️ EARTH CONTROL MANAGEMENT ---
    function setAutonomousAgent(address _newPKP) external onlyEarth {
        autonomousAgentPKP = _newPKP;
    }

    function toggleEmergencyStop() external onlyEarth {
        emergencyStopped = !emergencyStopped;
        emit EmergencyStateToggled(emergencyStopped);
    }

    // --- 🛰️ 1. TARGET REGISTRATION ---
    function registerTarget(
        uint256 _targetId,
        uint32 _length,
        uint32 _width,
        uint32 _height,
        uint32 _weightKg,
        uint8 _aluminumPercent,
        uint256 _estRemovalCost,
        bytes32 _telemetryMerkleRoot
    ) external onlyAutopilot {
        require(!targets[_targetId].exists, "Security: Target ID already registered!");
        
        targets[_targetId] = DebrisTarget({
            length: _length,
            width: _width,
            height: _height,
            weightKg: _weightKg,
            aluminumPercent: _aluminumPercent,
            estRemovalCost: _estRemovalCost,
            telemetryMerkleRoot: _telemetryMerkleRoot,
            isBurnedInAtmosphere: false,
            isCapturedForBase: false,
            exists: true
        });

        currentSatelliteState = SatelliteState.Navigating;
        emit TargetRegistered(_targetId, _telemetryMerkleRoot, _estRemovalCost);
    }

    // --- 🔥 2. MAD KING PROTOCOL & ECO-SHIELD (Safe Return) ---
    function executeMadKingProtocol(uint256 _targetId) external onlyAutopilot {
        DebrisTarget storage target = targets[_targetId];
        require(target.exists, "Target does not exist!");
        require(!target.isBurnedInAtmosphere && !target.isCapturedForBase, "Target already processed!");

        // 🧮 Off-chain validation formula
        uint256 calculatedOzoneHarm = (uint256(target.weightKg) * uint256(target.aluminumPercent)) / 10;

        // 🛡️ Eco-Shield Check (Soft Lockout without revert)
        if (calculatedOzoneHarm > maxOzoneHarmThreshold) {
            currentSatelliteState = SatelliteState.EcoBlocked;
            emit EcoBlockTriggered(_targetId, calculatedOzoneHarm);
            return;
        }

        // 🔥 Activate Mad King
        currentSatelliteState = SatelliteState.MadKing;
        target.isBurnedInAtmosphere = true;

        emit MadKingActivated(_targetId, "Clearing trajectory corridor via Burn Them All Protocol");
        emit DebrisDisposed(_targetId, "Atmospheric Vaporization");

        // Return to navigation
        currentSatelliteState = SatelliteState.Navigating;
    }

    // --- 💰 3. BASE BALANCE CHECK & CAPTURE ---
    function captureForBase(uint256 _targetId) external onlyAutopilot {
        DebrisTarget storage target = targets[_targetId];
        require(target.exists, "Target does not exist!");
        require(!target.isBurnedInAtmosphere && !target.isCapturedForBase, "Target already processed!");

        // 💵 Check Base vault balance
        uint256 baseBalance = baseFactoryAddress.balance;
        require(baseBalance >= target.estRemovalCost, "Budget Lock: Base does not have enough funds for capture!");

        target.isCapturedForBase = true;
        currentSatelliteState = SatelliteState.Idle;

        emit DebrisDisposed(_targetId, "Captured and Rerouted to Recycled Base");
    }
}
