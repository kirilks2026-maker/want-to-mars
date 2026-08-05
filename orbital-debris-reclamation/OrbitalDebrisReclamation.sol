// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OrbitalDebrisReclamationAndSmelter (Version 3.0)
 * @notice Core Vault & Processing Base for the "Want to Mars" ecosystem.
 * @dev Gas-optimized, features cross-contract sync, pluggable architecture, and partial delivery support.
 */
contract OrbitalDebrisReclamationAndSmelter {

    // --- ENUMS & STRUCTS ---

    enum MetalType { Titanium, Aluminum, Steel, Copper, RareEarth }

    struct DebrisObject {
        uint256 id;
        string name;
        string coordinates;
        MetalType metalType;
        uint256 totalWeightKg;       // Initial estimated weight received from the satellite
        uint256 processedWeightKg;   // Mass actually delivered and processed on Earth
        uint256 rewardValueWei;      // Total locked native ETH budget allocated for rewards
        uint256 paidOutWei;          // Total rewards distributed for delivered parts so far
        bool isFullyRecycled;        // Flips to true when processedWeightKg == totalWeightKg
        bool exists;                 // Protection against ID duplication
    }

    struct SocialReliefHub {
        string hubName;
        address walletAddress;       // Vault/Multisig address of the humanitarian fund
        bool isActive;
    }

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    // --- STATE VARIABLES ---

    address public admin;
    address public satelliteController; // Address of the deployed orbit autopilot contract
    uint256 public nextAssetId;

    mapping(uint256 => DebrisObject) public trackedDebris;
    mapping(MetalType => uint256) public recycledMetalsKg;
    mapping(address => Deposit) public pendingBalances;
    mapping(address => SocialReliefHub) public socialHubs;

    // --- UPGRADABILITY: PLUGGABLE MODULAR ARCHITECTURE ---
    address public economicPluginModule; // Address placeholder for future business logic/tax expansions

    // --- EVENTS ---

    event AssetRegistered(uint256 indexed assetId, string name, string coordinates, uint256 rewardValueWei);
    event PartialScrapProcessed(uint256 indexed assetId, address indexed scrapper, uint256 deliveredWeight, uint256 rewardPaid);
    event DebrisClosed(uint256 indexed assetId);
    event FundsDeposited(address indexed beneficiary, uint256 amount);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);
    event SocialHubRegistered(address indexed hubAddress, address indexed fundsWallet, string name);

    // --- ACCESS MODIFIERS ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Auth: Caller is not admin");
        _;
    }

    modifier onlySatellite() {
        require(msg.sender == satelliteController, "Auth: Only registered Satellite allowed!");
        _;
    }

    constructor() payable {
        admin = msg.sender;
    }

    // --- ⚙️ INTER-CONTRACT LINKING & UPDATES ---
    
    function setSatelliteController(address _satellite) external onlyAdmin {
        require(_satellite != address(0), "Invalid satellite address");
        satelliteController = _satellite;
    }

    function setEconomicPluginModule(address _newModule) external onlyAdmin {
        require(_newModule != address(0), "Invalid module address");
        economicPluginModule = _newModule;
    }

    // --- 🛰️ 1. CROSS-CHAIN INTEROP: Orbit Autopilot locks budget via Lit VM ---
    function lockDebrisBudget(uint256 _targetId, uint256 _amount) external onlySatellite returns (bool) {
        require(!trackedDebris[_targetId].exists, "Base: Asset already locked");
        require(address(this).balance >= _amount, "Base: Insufficient global ETH liquidity inside the vault!");

        // Initializes a dynamic target mapping. Specs will be updated upon physical arrival
        trackedDebris[_targetId] = DebrisObject({
            id: _targetId,
            name: "Orbit-Captured Scrap",
            coordinates: "In Orbital Transit",
            metalType: MetalType.Titanium, 
            totalWeightKg: 0, 
            processedWeightKg: 0,
            rewardValueWei: _amount,
            paidOutWei: 0,
            isFullyRecycled: false,
            exists: true
        });

        return true;
    }

    // Invoked by the satellite to push refined physics data once the corridor is clear
    function updateTargetSpecs(uint256 _targetId, uint256 _weightKg, MetalType _type) external onlySatellite {
        require(trackedDebris[_targetId].exists, "Base: Target not found");
        trackedDebris[_targetId].totalWeightKg = _weightKg;
        trackedDebris[_targetId].metalType = _type;
    }

    // --- 🌍 2. EARTH OPERATIONS: Fractional Scrap Processing ---
    /**
     * @notice Handles fragmented debris retrieval (e.g., object broke down into separate parts).
     * @param _deliveredWeight Mass in kilograms delivered by a specific field scrapper.
     */
    function processPartialScrap(
        uint256 _assetId,
        uint256 _deliveredWeight,
        address _smelterAddress,
        address _scrapperAddress
    ) external onlyAdmin {
        DebrisObject storage debris = trackedDebris[_assetId];

        require(debris.exists, "Asset does not exist");
        require(!debris.isFullyRecycled, "Asset is already fully recycled and closed");
        require(_deliveredWeight > 0, "Weight must be greater than zero");

        // Protection against scrap inflation (cannot deliver more than registered by the satellite)
        if (debris.totalWeightKg > 0) {
            require(debris.processedWeightKg + _deliveredWeight <= debris.totalWeightKg, "Error: Delivered weight exceeds satellite specs!");
        }

        // Proportional reward scaling formula
        uint256 pieceReward = (debris.rewardValueWei * _deliveredWeight) / debris.totalWeightKg;
        
        // Safeguard to prevent math overflows beyond the initially locked budget pool
        if (debris.paidOutWei + pieceReward > debris.rewardValueWei) {
            pieceReward = debris.rewardValueWei - debris.paidOutWei;
        }

        // State changes
        debris.processedWeightKg += _deliveredWeight;
        debris.paidOutWei += pieceReward;
        recycledMetalsKg[debris.metalType] += _deliveredWeight;

        // Core DePIN 80/20 commercial split
        uint256 smelterShare = (pieceReward * 80) / 100;
        uint256 scrapperShare = pieceReward - smelterShare;

        _addPendingBalance(_smelterAddress, smelterShare);

        // Zero-Barrier Onboarding Integration (Social Relief Hub Routing)
        if (socialHubs[_scrapperAddress].isActive) {
            _addPendingBalance(socialHubs[_scrapperAddress].walletAddress, scrapperShare);
        } else {
            _addPendingBalance(_scrapperAddress, scrapperShare);
        }

        emit PartialScrapProcessed(_assetId, _scrapperAddress, _deliveredWeight, pieceReward);

        // Closes the asset card permanently if total physical volume matches orbit calculations
        if (debris.processedWeightKg == debris.totalWeightKg) {
            debris.isFullyRecycled = true;
            emit DebrisClosed(_assetId);
        }
    }

    // --- 3. WITHDRAWAL MANAGEMENT (Pull Payment Pattern) ---

    function withdraw() external {
        uint256 amount = pendingBalances[msg.sender].amount;
        require(amount > 0, "No funds available for withdrawal");

        pendingBalances[msg.sender].amount = 0;
        pendingBalances[msg.sender].timestamp = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsWithdrawn(msg.sender, amount);
    }

    function registerSocialHub(address _hubAddress, address _fundsWallet, string calldata _hubName) external onlyAdmin {
        require(_hubAddress != address(0) && _fundsWallet != address(0), "Invalid address");
        socialHubs[_hubAddress] = SocialReliefHub({hubName: _hubName, walletAddress: _fundsWallet, isActive: true});
        emit SocialHubRegistered(_hubAddress, _fundsWallet, _hubName);
    }

    // --- INTERNAL FUNCTIONS ---

    function _addPendingBalance(address _beneficiary, uint256 _amount) internal {
        if (pendingBalances[_beneficiary].amount == 0) {
            pendingBalances[_beneficiary].timestamp = block.timestamp;
        }
        pendingBalances[_beneficiary].amount += _amount;
        emit FundsDeposited(_beneficiary, _amount);
    }

    receive() external payable {}
}
