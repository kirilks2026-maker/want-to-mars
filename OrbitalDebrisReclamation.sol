// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OrbitalDebrisReclamation
 * @notice Enterprise-grade DePIN smart contract for autonomous orbital debris recycling.
 * Features strict industrial funding, designated drop-zone tracking, and authorized smelter enforcement.
 * Economic Split: 20% to the independent scrapper, 80% to the certified regional smelter.
 */
contract OrbitalDebrisReclamation {
    address public spaceXAdmin;       // Mission coordinator (Elon Musk)
    address public authorizedSmelter; // The only certified recycling facility allowed to process scrap

    enum MetalType { Aluminum, Titanium, Tungsten }

    struct DebrisObject {
        string objectName;
        string dropZoneCoordinates; // e.g., "Drop Zone: Sector 7-Alpha (Texas Desert)"
        MetalType metalType;
        uint256 totalWeightKg;
        uint256 rawValueWei;        // Hardcoded processing budget allocated by SpaceX
        bool isProcessed;
    }

    DebrisObject[] public trackedDebris;
    
    // Closed-loop aerospace industrial warehouse inventory
    uint256 public recycledTitaniumKg;
    uint256 public recycledTungstenKg;
    uint256 public recycledAluminumKg;

    // Strict 100% economic distribution split (No leftovers inside the contract)
    uint256 public constant SCRAPPER_PAYOUT_PERCENT = 20; // Risk and retrieval labor reward
    uint256 public constant SMELTER_EXPENSE_PERCENT = 80; // High-energy induction furnace compensation

    event DebrisRegistered(uint256 indexed assetId, string name, string coordinates, uint256 weight);
    event MaterialRefined(uint256 indexed assetId, MetalType metal, uint256 weight);
    event RocketBuilt(string rocketType, uint256 titaniumUsed);
    event SmelterUpdated(address indexed newSmelter);

    modifier onlyAdmin() {
        require(msg.sender == spaceXAdmin, "Access denied: SpaceX Admin only");
        _;
    }

    modifier onlyAuthorizedSmelter() {
        require(msg.sender == authorizedSmelter, "Access denied: Unauthorized processing point");
        _;
    }

    // Deployer funds the operational pool immediately upon contract deployment
    constructor(address _authorizedSmelter) payable {
        spaceXAdmin = msg.sender;
        authorizedSmelter = _authorizedSmelter; // Setting up the contractually bound smelter address
    }

    // Allows Elon Musk to replenish the factory operational budget at any time
    function fundOperationalPool() public payable onlyAdmin {}

    // Allows changing the factory address if SpaceX signs a contract with a new facility
    function updateAuthorizedSmelter(address _newSmelter) public onlyAdmin {
        require(_newSmelter != address(0), "Invalid smelter address");
        authorizedSmelter = _newSmelter;
        emit SmelterUpdated(_newSmelter);
    }

    // 1. REGISTRATION: Admin logs a controlled impact event at the designated coordinates
    function registerDroppedAsset(
        string memory _name, 
        string memory _coordinates,
        MetalType _type, 
        uint256 _weight, 
        uint256 _valueWei
    ) public onlyAdmin {
        trackedDebris.push(DebrisObject(_name, _coordinates, _type, _weight, _valueWei, false));
        emit DebrisRegistered(trackedDebris.length - 1, _name, _coordinates, _weight);
    }

    // 2. INDUSTRIAL PROCESSING: Only the authorized smelter can trigger execution and distribute rewards
    function processScrap(uint256 _objectId, address payable _scrapperAddress) public onlyAuthorizedSmelter {
        DebrisObject storage debris = trackedDebris[_objectId];
        require(!debris.isProcessed, "Asset already processed");
        require(_scrapperAddress != address(0), "Invalid scrapper address");
        
        uint256 totalValue = debris.rawValueWei;
        uint256 operatorReward = (totalValue * SCRAPPER_PAYOUT_PERCENT) / 100;
        uint256 smelterComp = (totalValue * SMELTER_EXPENSE_PERCENT) / 100;

        // Double check liquidity availability
        require(address(this).balance >= totalValue, "Operational pool depleted");

        debris.isProcessed = true;

        // 100% efficiency: entire weight moves into SpaceX smart storage
        if (debris.metalType == MetalType.Aluminum) recycledAluminumKg += debris.totalWeightKg;
        if (debris.metalType == MetalType.Titanium) recycledTitaniumKg += debris.totalWeightKg;
        if (debris.metalType == MetalType.Tungsten) recycledTungstenKg += debris.totalWeightKg;

        emit MaterialRefined(_objectId, debris.metalType, debris.totalWeightKg);

        // Safe immediate financial distribution (Gas-optimized low level calls)
        (bool successScrap, ) = _scrapperAddress.call{value: operatorReward}("");
        require(successScrap, "Scrapper payout failed");

        (bool successSmelt, ) = payable(authorizedSmelter).call{value: smelterComp}("");
        require(successSmelt, "Smelter payout failed");
    }

    // 3. CLOSED-LOOP CONSUMPTION: SpaceX utilizes recycled metal directly for production
    function buildStarshipHull(uint256 _requiredTitaniumKg) public onlyAdmin {
        require(recycledTitaniumKg >= _requiredTitaniumKg, "Insufficient titanium reserves in warehouse");
        recycledTitaniumKg -= _requiredTitaniumKg;
        
        emit RocketBuilt("Starship v3", _requiredTitaniumKg);
    }

    function getPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }
}