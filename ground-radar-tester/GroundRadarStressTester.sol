// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GroundRadarStressTester (Hardened Doomsday Edition)
 * @notice Part of the OMCP Ecosystem (Orbital Mission Control Protocol).
 * @dev Engineered for 0G Labs Testnet to simulate and validate high-throughput parallel data availability tracks during Kessler Syndrome.
 */
contract GroundRadarStressTester {

    // --- ACCESS CONTROL & SETTINGS ---
    address public admin;
    address public radarNetworkOperator; 
    
    uint256 public totalDataBatchesRegistered;
    uint256 public constant MAX_BATCH_SIZE = 50; 

    // Added Destroyed state for cascading tracking failures
    enum TrackingStatus { ActiveTracking, DeorbitCompleted, LostSignal, Destroyed }

    struct RadarTrack {
        uint256 targetId;
        uint256 parentTargetId;       // Link to parent debris ID (0 for primary complete satellites)
        uint256 timestamp;
        uint32 predictedLandingZoneId; 
        TrackingStatus status;
        bytes32 dataMerkleRoot;        // Proof pointer to heavy files in 0G Storage
        bool exists;
    }

    mapping(uint256 => RadarTrack) public activeTracks;

    // --- EVENTS ---
    event RadarTrackRecorded(uint256 indexed targetId, bytes32 indexed dataMerkleRoot, uint32 landingZone);
    event BulkTracksProcessed(uint256 totalCount, uint256 timestamp);
    event TrackStatusUpdated(uint256 indexed targetId, TrackingStatus newStatus);
    event KesslerCascadeTriggered(uint256 indexed parentTargetId, uint256 fragmentsCount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Auth: Only System Admin allowed");
        _;
    }

    modifier onlyRadarNetwork() {
        require(msg.sender == radarNetworkOperator || msg.sender == admin, "Auth: Only authorized Radar Network allowed");
        _;
    }

    constructor(address _radarOperator) {
        admin = msg.sender;
        radarNetworkOperator = _radarOperator;
    }

    function setRadarOperator(address _newOperator) external onlyAdmin {
        require(_newOperator != address(0), "Invalid address");
        radarNetworkOperator = _newOperator;
    }

    // --- ⚡ 1. NOMINAL MODE: BULK DATA REGISTRATION ---
    function registerBulkRadarTracks(
        uint256[] calldata _targetIds,
        uint32[] calldata _landingZones,
        bytes32[] calldata _dataMerkleRoots
    ) external onlyRadarNetwork {
        uint256 count = _targetIds.length;
        require(count > 0, "StressTest: Batch arrays cannot be empty");
        require(count == _landingZones.length && count == _dataMerkleRoots.length, "StressTest: Array length mismatch");
        require(count <= MAX_BATCH_SIZE, "StressTest: Exceeds safe gas execution limits per batch");

        for (uint256 i = 0; i < count; i++) {
            uint256 tId = _targetIds[i];
            require(!activeTracks[tId].exists, "Security: Radar track ID already exists");

            activeTracks[tId] = RadarTrack({
                targetId: tId,
                parentTargetId: 0, // 0 means this is a primary complete object
                timestamp: block.timestamp,
                predictedLandingZoneId: _landingZones[i],
                status: TrackingStatus.ActiveTracking,
                dataMerkleRoot: _dataMerkleRoots[i],
                exists: true
            });

            emit RadarTrackRecorded(tId, _dataMerkleRoots[i], _landingZones[i]);
        }

        totalDataBatchesRegistered += count;
        emit BulkTracksProcessed(count, block.timestamp);
    }

    // --- 🔥 2. DOOMSDAY MODE: KESSLER SYNDROME SIMULATION ---
    /**
     * @notice Simulates catastrophic fragmentation of a major target into hundreds of micro-debris pieces.
     * @dev Flips parent target state to Destroyed and registers child fragments batch in a single block execution loop.
     * @param _parentTargetId ID of the fragmented parent satellite.
     * @param _fragmentIds Array of newly generated fragment IDs.
     * @param _landingZones Array of predicted fallback zones per fragment.
     * @param _dataMerkleRoots Array of 0G Storage proof pointers per fragment.
     */
    function triggerKesslerCascade(
        uint256 _parentTargetId,
        uint256[] calldata _fragmentIds,
        uint32[] calldata _landingZones,
        bytes32[] calldata _dataMerkleRoots
    ) external onlyRadarNetwork {
        uint256 count = _fragmentIds.length;
        require(count > 0, "Doomsday: Fragment arrays cannot be empty");
        require(count == _landingZones.length && count == _dataMerkleRoots.length, "Doomsday: Array length mismatch");
        require(count <= MAX_BATCH_SIZE, "Doomsday: Exceeds safe gas execution limits per chunk");

        // If parent target is currently active, transition state permanently to Destroyed
        if (activeTracks[_parentTargetId].exists && activeTracks[_parentTargetId].status == TrackingStatus.ActiveTracking) {
            activeTracks[_parentTargetId].status = TrackingStatus.Destroyed;
            emit TrackStatusUpdated(_parentTargetId, TrackingStatus.Destroyed);
        }

        // Atomically map and register fragments linked back to the parent incident
        for (uint256 i = 0; i < count; i++) {
            uint256 fId = _fragmentIds[i];
            require(!activeTracks[fId].exists, "Security: Fragment ID already registered");

            activeTracks[fId] = RadarTrack({
                targetId: fId,
                parentTargetId: _parentTargetId, // Hard reference link to the parent collision event
                timestamp: block.timestamp,
                predictedLandingZoneId: _landingZones[i],
                status: TrackingStatus.ActiveTracking,
                dataMerkleRoot: _dataMerkleRoots[i],
                exists: true
            });

            emit RadarTrackRecorded(fId, _dataMerkleRoots[i], _landingZones[i]);
        }

        totalDataBatchesRegistered += count;
        emit KesslerCascadeTriggered(_parentTargetId, count);
    }

    // --- 🛰️ 3. TRACK STATE SETTLEMENT ---
    function finalizeDeorbitTrack(uint256 _targetId, TrackingStatus _finalStatus) external onlyRadarNetwork {
        require(activeTracks[_targetId].exists, "StressTest: Track target not found");
        require(activeTracks[_targetId].status == TrackingStatus.ActiveTracking, "StressTest: Track already closed");

        activeTracks[_targetId].status = _finalStatus;
        emit TrackStatusUpdated(_targetId, _finalStatus);
    }

    // --- 🔍 4. READ HELPERS ---
    function getTrackSpecs(uint256 _targetId) external view returns (RadarTrack memory) {
        require(activeTracks[_targetId].exists, "Query: Target tracking record non-existent");
        return activeTracks[_targetId];
    }
}
