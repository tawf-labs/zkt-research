// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.31;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PrivateDonationPool
 * @notice Privacy-preserving donation pool. Amount commitment is computed
 *         inside the Noir circuit (pedersen_hash(secret, amount)) and
 *         verified on-chain as a public input. The event emits only
 *         (poolId, nullifier, amountCommitment) — no donor, no amount.
 *
 *         Amount is visible in calldata (required for transferFrom); a
 *         known limitation. Future work moves amount into a circuit-private
 *         witness with fixed denominations.
 * @dev Called by ZKTCore after ZK proof verification completes. The donor
 *      must approve this contract to spend IDRX tokens before calling
 *      ZKTCore.donateZKPrivate().
 */
contract PrivateDonationPool is AccessControl, ReentrancyGuard {
    bytes32 public constant CORE_ROLE = keccak256("CORE_ROLE");

    modifier onlyCore() {
        require(hasRole(CORE_ROLE, msg.sender), "PrivateDonationPool: only CORE_ROLE");
        _;
    }

    IERC20 public idrxToken;

    mapping(uint256 => uint256) public poolRaisedAmount;
    mapping(uint256 => bool) public poolFundsWithdrawn;
    mapping(bytes32 => bytes32) public nullifierCommitments;
    mapping(bytes32 => bool) public spentCommitments;

    event PrivateDonationReceived(
        uint256 indexed poolId,
        bytes32 indexed nullifier,
        bytes32 amountCommitment
    );

    event PrivatePoolWithdrawn(
        uint256 indexed poolId,
        address indexed amil,
        uint256 amount
    );

    event PrivatePoolRedistributed(
        uint256 indexed poolId,
        address indexed escrow,
        uint256 amount
    );

    constructor(address _idrxToken) {
        require(_idrxToken != address(0), "Invalid token");
        idrxToken = IERC20(_idrxToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Receive a privacy-preserved donation. Called only by ZKTCore
     *         after ZK proof verification. The amountCommitment comes from
     *         the Noir circuit's second public return value (publicInputs[6]).
     * @param donor The original donor (passed by ZKTCore as msg.sender)
     * @param poolId The campaign pool receiving the donation
     * @param amount Donation amount in IDRX (visible in calldata, NOT in event)
     * @param nullifier The spent nullifier from circuit
     * @param amountCommitment Pedersen commitment from circuit: pedersen_hash(secret, amount)
     */
    function donatePrivately(
        address donor,
        uint256 poolId,
        uint256 amount,
        bytes32 nullifier,
        bytes32 amountCommitment
    ) external onlyCore nonReentrant {
        require(donor != address(0), "Invalid donor");
        require(amount > 0, "Amount must be > 0");
        require(nullifier != bytes32(0), "Invalid nullifier");
        require(amountCommitment != bytes32(0), "Invalid commitment");
        require(!spentCommitments[amountCommitment], "Commitment already used");

        spentCommitments[amountCommitment] = true;
        nullifierCommitments[nullifier] = amountCommitment;

        require(
            idrxToken.transferFrom(donor, address(this), amount),
            "IDRX transfer failed"
        );

        poolRaisedAmount[poolId] += amount;

        emit PrivateDonationReceived(poolId, nullifier, amountCommitment);
    }

    /**
     * @notice Withdraw funds from a campaign pool to the amil institution.
     */
    function withdrawFunds(uint256 poolId, address amil) external onlyCore nonReentrant {
        require(amil != address(0), "Invalid amil address");
        require(!poolFundsWithdrawn[poolId], "Funds already withdrawn");

        uint256 amount = poolRaisedAmount[poolId];
        require(amount > 0, "No funds to withdraw");

        poolFundsWithdrawn[poolId] = true;
        poolRaisedAmount[poolId] = 0;

        require(
            idrxToken.transfer(amil, amount),
            "IDRX transfer failed"
        );

        emit PrivatePoolWithdrawn(poolId, amil, amount);
    }

    /**
     * @notice Redistribute private pool funds to ZakatEscrowManager for amil-managed
     *         recipient disbursement. Called by ZKTCore. The pool balance is zeroed
     *         and the escrow receives the full amount into its donation pipeline.
     */
    function redistributeToEscrow(address escrow, uint256 poolId)
        external onlyCore nonReentrant returns (uint256) {
        require(escrow != address(0), "Invalid escrow");

        uint256 amount = poolRaisedAmount[poolId];
        require(amount > 0, "No funds to redistribute");

        poolRaisedAmount[poolId] = 0;
        idrxToken.approve(escrow, amount);

        emit PrivatePoolRedistributed(poolId, escrow, amount);
        return amount;
    }

    /**
     * @notice Verify a nullifier's commitment matches on-chain record.
     */
    function getCommitmentForNullifier(bytes32 nullifier)
        external view returns (bytes32) {
        return nullifierCommitments[nullifier];
    }
}
