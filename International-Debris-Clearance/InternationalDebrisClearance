// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title InternationalDebrisClearance
 * @notice Core RWA and Geopolitical Clearing component of the OMCP Ecosystem.
 * @dev Engineered for SimpleChain Testnet. Implements secure .call value transfers and separate equity tracks.
 */
contract InternationalDebrisClearance {

    // --- ACCESS CONTROL & STATE ---
    address public admin;
    address public recyclingFacility;   // Terrestrial Smelter (Gets 80% operational buffer)
    address public socialInsuranceFund; // Social Relief Hub / Multisig Vault (Gets 20% fallback)

    uint256 public totalBatches;

    enum CountryJurisdiction { USA, China, Russia, EU, India, Japan }
    enum ClearanceStatus { Pending, CustomsHold, Approved, Disbursed }

    struct DebrisBatch {
        uint256 batchId;
        CountryJurisdiction originCountry;
        uint256 targetId;
        uint256 weightKg;
        uint256 bountyAmountWei;    
        ClearanceStatus status;
        bool isCustomsApproved;     
    }

    mapping(uint256 => DebrisBatch) public batches;
    
    // --- 📊 SEPARATED RWA EQUITY LEDGERS ---
    mapping(uint256 => uint256) public sovereignFinancialEquity; // Tracks liquid capital tokens (Wei)
    mapping(uint256 => uint256) public sovereignMaterialEquity;  // Tracks raw physical resource assets (Kg)

    // --- EVENTS ---
    event DebrisBatchRegistered(uint256 indexed batchId, uint256 indexed targetId, CountryJurisdiction country, uint256 bounty);
    event CustomsAuditUpdated(uint256 indexed batchId, ClearanceStatus status, bool approved);
    event FinancialClearanceExecuted(uint256 indexed batchId, uint256 smelterPayout, address indexed scrapperTarget, uint256 scrapperPayout);
    event RWAResourceEquityLogged(uint256 indexed countryId, uint256 resourceWeightKg, string resourceType);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Auth: Only Clearing Admin allowed");
        _;
    }

    constructor(address _recyclingFacility, address _socialInsuranceFund) {
        admin = msg.sender;
        recyclingFacility = _recyclingFacility;
        socialInsuranceFund = _socialInsuranceFund;
    }

    function updateLogisticsAddresses(address _newFacility, address _newFund) external onlyAdmin {
        if (_newFacility != address(0)) recyclingFacility = _newFacility;
        if (_newFund != address(0)) socialInsuranceFund = _newFund;
    }

    // --- ⚡ 1. RWAS INGESTION & EQUITY TRACKING ---
    function registerDebrisBatch(
        CountryJurisdiction _country,
        uint256 _targetId,
        uint256 _weightKg
    ) external payable returns (uint256) {
        totalBatches++;

        batches[totalBatches] = DebrisBatch({
            batchId: totalBatches,
            originCountry: _country,
            targetId: _targetId,
            weightKg: _weightKg,
            bountyAmountWei: msg.value,
            status: ClearanceStatus.Pending,
            isCustomsApproved: false
        });

        if (msg.value > 0) {
            sovereignFinancialEquity[uint256(_country)] += msg.value;
        }

        emit DebrisBatchRegistered(totalBatches, _targetId, _country, msg.value);
        return totalBatches;
    }

    function logMaterialEquityContribution(CountryJurisdiction _country, uint256 _weightKg, string calldata _metalType) external onlyAdmin {
        require(_weightKg > 0, "RWA: Weight must be greater than zero");
        sovereignMaterialEquity[uint256(_country)] += _weightKg;
        emit RWAResourceEquityLogged(uint256(_country), _weightKg, _metalType);
    }

    // --- 🇺🇸 2. LEGAL BORDER AUDIT ---
    function processCustomsAudit(uint256 _batchId, bool _shouldApprove) external onlyAdmin {
        DebrisBatch storage batch = batches[_batchId];
        require(batch.batchId != 0, "Clearance: Shipment record non-existent");
        require(batch.status == ClearanceStatus.Pending || batch.status == ClearanceStatus.CustomsHold, "Clearance: Audit phase closed");

        if (_shouldApprove) {
            batch.status = ClearanceStatus.Approved;
            batch.isCustomsApproved = true;
        } else {
            batch.status = ClearanceStatus.CustomsHold;
            batch.isCustomsApproved = false;
        }

        emit CustomsAuditUpdated(_batchId, batch.status, batch.isCustomsApproved);
    }

    // --- 🧮 3. OPTIMIZED 80/20 CLEARANCE (SECURE MULTISIG PATHWAY) ---
    function executeFinancialClearance(uint256 _batchId, address _scrapperAddress) external onlyAdmin {
        DebrisBatch storage batch = batches[_batchId];
        require(batch.batchId != 0, "Clearance: Shipment record non-existent");
        require(batch.isCustomsApproved, "Security Lock: Customs approval mandatory");
        require(batch.status == ClearanceStatus.Approved, "Security Lock: Batch finalized or locked");
        
        uint256 totalPayout = batch.bountyAmountWei;
        batch.status = ClearanceStatus.Disbursed;

        if (totalPayout == 0) {
            emit FinancialClearanceExecuted(_batchId, 0, address(0), 0);
            return;
        }

        uint256 smelterShare = (totalPayout * 8000) / 10000; 
        uint256 socialShare = totalPayout - smelterShare;     

        // DYNAMIC SOCIAL ROUTING (OR/OR LOGIC)
        address finalScrapperTarget = (_scrapperAddress == address(0)) ? socialInsuranceFund : _scrapperAddress;

        emit FinancialClearanceExecuted(_batchId, smelterShare, finalScrapperTarget, socialShare);

        // --- MODERN EVM SECURE CALL TRANSFERS FOR MULTISIG WALLETS & CONTRACTS ---
        (bool successSmelter, ) = payable(recyclingFacility).call{value: smelterShare}("");
        require(successSmelter, "RWA: Smelter payout transfer failed");

        (bool successScrapper, ) = payable(finalScrapperTarget).call{value: socialShare}("");
        require(successScrapper, "RWA: Scrapper payout transfer failed");
    }
}
