// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Interface for cross-contract budget locking on the Recycling Base / Vault.
 */
interface IMetalBase {
    function lockDebrisBudget(uint256 targetId, uint256 amount) external returns (bool);
}

/**
 * @title SatelliteController
 * @dev Autonomous Orbit Operations & Satellite Autopilot.
 * Fully hardened version with state-lock protection and cross-contract interop.
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
        bool isBurnedInAtmosphere;   // Burn status flag
        bool isCapturedForBase;      // Base capture flag
        bool isEcoBlocked;           // Eco-shield lock flag (Prevents infinite retry loops)
        bool exists;                 // Protection against target ID overwrite
    }

    // Target Debris ID => Debris Data
    mapping(uint256 => DebrisTarget) public targets;
    
    // --- 📣 EVENTS ---
    event TargetRegistered(uint256 indexed targetId, bytes32 indexed telemetryMerkleRoot, uint256 estCost);
    event MadKingStarted(uint256 indexed targetId, string reason);
    event MadKingFinished(uint256 indexed targetId);
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

    function setBaseFactoryAddress(address _newBase) external onlyEarth {
        baseFactoryAddress = _newBase;
    }

    function toggleEmergencyStop() external onlyEmergencyStopAllowed {
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
            isEcoBlocked: false,
            exists: true
        });

        currentSatelliteState = SatelliteState.Navigating;
        emit TargetRegistered(_targetId, _telemetryMerkleRoot, _estRemovalCost);
    }

    // --- 🔥 2A. START MAD KING PROTOCOL (Step 1) ---
    function startMadKingProtocol(uint256 _targetId) external onlyAutopilot {
        DebrisTarget storage target = targets[_targetId];
        require(target.exists, "Target does not exist!");
        require(!target.isBurnedInAtmosphere && !target.isCapturedForBase, "Target already processed!");
        require(!target.isEcoBlocked, "Eco-Shield: Target is eco-blocked from burning!");

        // 🧮 Off-chain validation formula
        uint256 calculatedOzoneHarm = (uint256(target.weightKg) * uint256(target.aluminumPercent)) / 10;

        // 🛡️ Eco-Shield Verification with lock flag
        if (calculatedOzoneHarm > maxOzoneHarmThreshold) {
            target.isEcoBlocked = true; // Permanently lock target from burning
            currentSatelliteState = SatelliteState.EcoBlocked;
            emit EcoBlockTriggered(_targetId, calculatedOzoneHarm);
            return;
        }

        // 🔥 Activate Mad King burning mode
        currentSatelliteState = SatelliteState.MadKing;
        emit MadKingStarted(_targetId, "Clearing trajectory corridor via Burn Them All Protocol");
    }

    // --- 🔥 2B. FINISH MAD KING PROTOCOL (Step 2) ---
    function finishMadKingProtocol(uint256 _targetId) external onlyAutopilot {
        require(currentSatelliteState == SatelliteState.MadKing, "Satellite is not in MadKing mode!");
        DebrisTarget storage target = targets[_targetId];

        target.isBurnedInAtmosphere = true;
        emit DebrisDisposed(_targetId, "Atmospheric Vaporization Completed");
        emit MadKingFinished(_targetId);

        // Return satellite to navigation mode
        currentSatelliteState = SatelliteState.Navigating;
    }

    // --- 💰 3. CROSS-CONTRACT BUDGET LOCK & CAPTURE ---
    function captureForBase(uint256 _targetId) external onlyAutopilot {
        DebrisTarget storage target = targets[_targetId];
        require(target.exists, "Target does not exist!");
        require(!target.isBurnedInAtmosphere && !target.isCapturedForBase, "Target already processed!");

        // 🔗 Cross-contract interaction: lock budget directly in the Base Vault
        bool success = IMetalBase(baseFactoryAddress).lockDebrisBudget(_targetId, target.estRemovalCost);
        require(success, "Budget Lock Failed on Recycled Base!");

        target.isCapturedForBase = true;
        currentSatelliteState = SatelliteState.Idle;

        emit DebrisDisposed(_targetId, "Captured and Rerouted to Recycled Base");
    }
}

