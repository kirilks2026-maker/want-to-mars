// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OrbitalDebrisReclamation (Version 2.0 - Hackathon Winners Edition)
 * @notice Part of the "Want to Mars" ecosystem (Galileo Network).
 * @dev Gas-optimized (external/calldata), Pull Payment pattern, reset timer fix, and Social Relief module.
 */
contract OrbitalDebrisReclamation {

    // --- ENUMS & STRUCTS ---

    enum MetalType { Titanium, Aluminum, Steel, Copper, RareEarth }

    struct DebrisObject {
        uint256 id;
        string name;
        string coordinates;
        MetalType metalType;
        uint256 weightKg;
        uint256 rewardValueWei;
        bool isRecycled;
    }

    struct SocialReliefHub {
        string hubName;
        address walletAddress; // Vault/Multisig address of the social fund
        bool isActive;
    }

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    // --- STATE VARIABLES ---

    address public admin;
    uint256 public nextAssetId;

    mapping(uint256 => DebrisObject) public trackedDebris;
    mapping(MetalType => uint256) public recycledMetalsKg;
    mapping(address => Deposit) public pendingBalances;
    mapping(address => SocialReliefHub) public socialHubs;

    // --- EVENTS ---

    event AssetRegistered(uint256 indexed assetId, string name, string coordinates, uint256 rewardValueWei);
    event ScrapProcessed(uint256 indexed assetId, address indexed smelter, address indexed scrapper, uint256 totalReward);
    event FundsDeposited(address indexed beneficiary, uint256 amount);
    event FundsWithdrawn(address indexed beneficiary, uint256 amount);
    event UnclaimedFundsReclaimed(address indexed beneficiary, uint256 amount);
    event SocialHubRegistered(address indexed hubAddress, address indexed fundsWallet, string name);

    // --- MODIFIERS ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    constructor() payable {
        admin = msg.sender;
    }

    // --- 1. ASSET REGISTRATION (Gas-Optimized: external + calldata) ---

    function registerDroppedAsset(
        string calldata _name,
        string calldata _coordinates, // E.g., "Nevada, Area 51" or "Texas, Sector 4"
        MetalType _metalType,
        uint256 _weightKg
    ) external payable onlyAdmin {
        require(msg.value > 0, "Reward value must be greater than zero");

        uint256 assetId = nextAssetId;

        trackedDebris[assetId] = DebrisObject({
            id: assetId,
            name: _name,
            coordinates: _coordinates,
            metalType: _metalType,
            weightKg: _weightKg,
            rewardValueWei: msg.value,
            isRecycled: false
        });

        nextAssetId++;

        emit AssetRegistered(assetId, _name, _coordinates, msg.value);
    }

    // --- 2. SCRAP PROCESSING & REWARD DISTRIBUTION ---

    function processScrap(
        uint256 _assetId,
        address _smelterAddress,
        address _scrapperAddress
    ) external onlyAdmin {
        DebrisObject storage debris = trackedDebris[_assetId];

        require(!debris.isRecycled, "Asset already recycled");
        require(_smelterAddress != address(0), "Invalid smelter address");
        require(_scrapperAddress != address(0), "Invalid scrapper address");

        debris.isRecycled = true;

        recycledMetalsKg[debris.metalType] += debris.weightKg;

        uint256 totalValue = debris.rewardValueWei;
        uint256 smelterReward = (totalValue * 80) / 100;
        uint256 scrapperReward = totalValue - smelterReward;

        _addPendingBalance(_smelterAddress, smelterReward);

        // Check if the scrapper address is registered as an active Social Relief Hub
        if (socialHubs[_scrapperAddress].isActive) {
            // Funds are routed directly to the Social Fund Vault
            _addPendingBalance(socialHubs[_scrapperAddress].walletAddress, scrapperReward);
        } else {
            // Funds are routed to the regular scrapper address
            _addPendingBalance(_scrapperAddress, scrapperReward);
        }

        emit ScrapProcessed(_assetId, _smelterAddress, _scrapperAddress, totalValue);
    }

    // --- 3. WITHDRAWAL (Pull Payment Pattern) ---

    function withdraw() external {
        uint256 amount = pendingBalances[msg.sender].amount;
        require(amount > 0, "No funds available for withdrawal");

        pendingBalances[msg.sender].amount = 0;
        pendingBalances[msg.sender].timestamp = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsWithdrawn(msg.sender, amount);
    }

    // --- 4. RECLAIM UNCLAIMED FUNDS (30-Day Expiration) ---

    function reclaimUnclaimedFunds(address _abandonedAddress) external onlyAdmin {
        Deposit storage dep = pendingBalances[_abandonedAddress];
        require(dep.amount > 0, "No funds to reclaim");
        require(block.timestamp >= dep.timestamp + 30 days, "Hold period not expired (30 days)");

        uint256 reclaimedAmount = dep.amount;
        dep.amount = 0;
        dep.timestamp = 0;

        (bool success, ) = admin.call{value: reclaimedAmount}("");
        require(success, "Reclaim transfer failed");

        emit UnclaimedFundsReclaimed(_abandonedAddress, reclaimedAmount);
    }

    // --- 5. SOCIAL RELIEF HUB MANAGEMENT ---

    function registerSocialHub(
        address _hubAddress, 
        address _fundsWallet, 
        string calldata _hubName
    ) external onlyAdmin {
        require(_hubAddress != address(0) && _fundsWallet != address(0), "Invalid address");
        
        socialHubs[_hubAddress] = SocialReliefHub({
            hubName: _hubName,
            walletAddress: _fundsWallet, // Designated fund vault
            isActive: true
        });

        emit SocialHubRegistered(_hubAddress, _fundsWallet, _hubName);
    }

    // --- INTERNAL FUNCTIONS ---

    function _addPendingBalance(address _beneficiary, uint256 _amount) internal {
        // Reset timer only if the balance was zero (prevents lockup reset for active accounts)
        if (pendingBalances[_beneficiary].amount == 0) {
            pendingBalances[_beneficiary].timestamp = block.timestamp;
        }

        pendingBalances[_beneficiary].amount += _amount;
        emit FundsDeposited(_beneficiary, _amount);
    }

    receive() external payable {}
}
