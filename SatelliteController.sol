// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SatelliteController
 * @dev Autonomous Orbit Operations & Satellite Autopilot powered by Decentralized Autonomous Agents.
 * Designed for EVM-compatible networks.
 */
contract SatelliteController {
    
    // --- 🛡️ ACCESS CONTROL & SECURITY SETTINGS ---
    address public owner;              // Earth Control Center / Admin
    address public autonomousAgentPKP; // Address of the autonomous off-chain agent (PKP)
    address public baseFactoryAddress; // Processing Base / Recycling Vault Contract
    
    bool public emergencyStopped;      // Emergency kill switch from Earth
    
    // --- ⚡ GAS OPTIMIZATION: State Flags ---
    uint8 public constant STATE_IDLE           = 1;  // 00000001 — Standby / Idle
    uint8 public constant STATE_NAVIGATING     = 2;  // 00000010 — Rendezvous / Navigation
    uint8 public constant STATE_MAD_KING       = 4;  // 00000100 — Mad King Protocol (Burn Them All)
    uint8 public constant STATE_ECO_BLOCKED    = 8;  // 00001000 — Environmental Hazard Lockout
    
    uint8 public currentSatelliteState;

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
        currentSatelliteState = STATE_IDLE;
    }

    // --- ⚙️ EARTH CONTROL MANAGEMENT ---
    function setAutonomousAgent(address _newPKP) external onlyEarth {
        autonomousAgentPKP = _newPKP;
    }

    function toggleEmergencyStop() external onlyEarth {
        emergencyStopped = !emergencyStopped;
        emit EmergencyStateToggled(emergencyStopped);
    }

    // --- 🛰️ 1. TARGET REGISTRATION & BUDGET VERIFICATION ---
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
        
        targets[_targetId] = DebrisTarget({
            length: _length,
            width: _width,
            height: _height,
            weightKg: _weightKg,
            aluminumPercent: _aluminumPercent,
            estRemovalCost: _estRemovalCost,
            telemetryMerkleRoot: _telemetryMerkleRoot,
            isBurnedInAtmosphere: false,
            isCapturedForBase: false
        });

        emit TargetRegistered(_targetId, _telemetryMerkleRoot, _estRemovalCost);
    }

    // --- 🔥 2. MAD KING PROTOCOL (`burnThemAll`) & ECO-SHIELD ---
    /**
     * @dev Autonomous execution function.
     * Evaluates debris toxicity before clearing trajectory corridor.
     * Burns debris in atmosphere if environmental threshold is respected.
     */
    function executeMadKingProtocol(uint256 _targetId) external onlyAutopilot {
        DebrisTarget storage target = targets[_targetId];
        require(!target.isBurnedInAtmosphere && !target.isCapturedForBase, "Target already processed!");

        // 🧮 Off-chain validation formula: Harm Index = Weight * Aluminum %
        uint256 calculatedOzoneHarm = (uint256(target.weightKg) * uint256(target.aluminumPercent)) / 10;

        // 🛡️ Eco-Shield Verification
        if (calculatedOzoneHarm > maxOzoneHarmThreshold) {
            currentSatelliteState = STATE_ECO_BLOCKED;
            emit EcoBlockTriggered(_targetId, calculatedOzoneHarm);
            revert("Eco-Shield: Debris is too toxic for atmospheric burning! Reroute to Base.");
        }

        // 🔥 Activate Mad King Protocol
        currentSatelliteState = STATE_MAD_KING;
        target.isBurnedInAtmosphere = true;

        emit MadKingActivated(_targetId, "Clearing trajectory corridor via Burn Them All Protocol");
        emit DebrisDisposed(_targetId, "Atmospheric Vaporization");

        // Return satellite to navigation mode
        currentSatelliteState = STATE_NAVIGATING;
    }

    // --- 💰 3. BASE BALANCE CHECK & HEAVY DEBRIS CAPTURE ---
    function captureForBase(uint256 _targetId) external onlyAutopilot {
        DebrisTarget storage target = targets[_targetId];
        require(!target.isBurnedInAtmosphere && !target.isCapturedForBase, "Target already processed!");

        // 💵 Check Base vault balance
        uint256 baseBalance = baseFactoryAddress.balance;
        require(baseBalance >= target.estRemovalCost, "Budget Lock: Base does not have enough funds for capture!");

        target.isCapturedForBase = true;
        currentSatelliteState = STATE_IDLE;

        emit DebrisDisposed(_targetId, "Captured and Rerouted to Recycled Base");
    }

    // Auxiliary state changer
    function setSatelliteState(uint8 _newState) external onlyAutopilot {
        currentSatelliteState = _newState;
    }
}
