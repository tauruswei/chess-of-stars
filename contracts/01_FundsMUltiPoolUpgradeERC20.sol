// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract FundsMUltiPoolUpgradeERC20 is Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    //    uint256 public maxPlayers = 8;                 // 设置资金盘允许几个人参加
    //    uint256 public firstReward = 475;              // 第一名的奖励 千分比
    //    uint256 public secondReward = 285;             // 第二名的奖励 千分比
    //    uint256 public thirdReward = 190;              // 第三名的奖励 千分比
    uint256 public maxPlayers;               // 设置资金盘允许几个人参加
    uint256 public firstReward;              // 第一名的奖励 千分比
    uint256 public secondReward;             // 第二名的奖励 千分比
    uint256 public thirdReward;              // 第三名的奖励 千分比

    struct Pool {
        uint256 minAmount;                        // 参与资金盘的最小金额
        mapping(uint => Round) rounds;
        uint roundsCount;
    }

    struct Round {
        uint256 totalFund;
        uint256 totalPlayers;
        address[] playerAddresses;
    }

    struct playerReward {
        uint poolIndex;
        uint256 roundIndex;
        uint256 reward;
    }

    IERC20 public token;

    Pool[] public pools;

    // 获奖者的历史奖励
    mapping(address => playerReward[]) public roundRewards;
    // 表示获奖者是是否在 在这一轮资金盘中
    mapping(uint => mapping(uint => mapping(address => bool))) public isPlayerParticipatedInRound;
    // 标识奖励是否已经分配完毕，防止重复分配
    mapping(uint => mapping(uint => bool)) public finishPayout;

    // 某一获奖者在某个池子中的总奖励
    mapping(uint => mapping(address => uint256)) public rewards;
    // 某一池子的总奖励
    mapping(uint => uint256) public totalRewards;

    // 获奖者的总奖励
    mapping(address => uint256) public userRewards;

    // 操作员
    mapping(address => bool) public operator;

    event RoundFinished(uint256 indexed poolIndex, uint256 indexed roundIndex, address[] playerAddresses, uint256 totalFund);
    event RoundPending(uint256 indexed poolIndex, uint256 indexed roundIndex, address playerAddresses, uint256 value);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _tokenAddress, uint256 _maxPlayers, uint256 _firstReward, uint256 _secondReward, uint256 _thirdReward, uint256[] memory _minAmounts) initializer public {
        token = IERC20(_tokenAddress);
        maxPlayers = _maxPlayers;
        firstReward = _firstReward;
        secondReward = _secondReward;
        thirdReward = _thirdReward;

        operator[msg.sender] = true;

        for (uint i = 0; i < _minAmounts.length; i++) {
            // Push an empty Pool
            pools.push();

            // Get the index of the newly added Pool
            uint poolIndex = pools.length - 1;

            // Set the properties of the Pool
            pools[poolIndex].minAmount = _minAmounts[i];
            pools[poolIndex].roundsCount = 1;
        }
        // 初始化 ReentrancyGuard
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function deposit(uint poolIndex, uint256 amount) external nonReentrant whenNotPaused {
        require(poolIndex < pools.length, "Invalid pool index");

        Pool storage pool = pools[poolIndex];
        Round storage currentRound = pool.rounds[pool.roundsCount];

        require(currentRound.totalPlayers < maxPlayers, "Round already full");
        require(amount >= pools[poolIndex].minAmount, "Need more currency");
        token.safeTransferFrom(msg.sender, address(this), amount);


        currentRound.playerAddresses.push(msg.sender);
        currentRound.totalFund += amount;
        currentRound.totalPlayers++;
        isPlayerParticipatedInRound[poolIndex][pool.roundsCount][msg.sender] = true;

        emit RoundPending(poolIndex, pool.roundsCount, msg.sender, amount);

        if (currentRound.totalPlayers == maxPlayers) {
            emit RoundFinished(poolIndex, pool.roundsCount, currentRound.playerAddresses, currentRound.totalFund);
            pool.roundsCount++;
        }
    }

    function payout(uint poolIndex, uint256 roundIndex, address first, address second, address third) external whenNotPaused {

        require(operator[msg.sender], "Permission denied");
        require(poolIndex < pools.length, "Invalid pool index");
        require(roundIndex < pools[poolIndex].roundsCount, "Invalid round index");
        require(!finishPayout[poolIndex][roundIndex], "Round already finished");

        Round storage round = pools[poolIndex].rounds[roundIndex];

        require(round.totalPlayers == maxPlayers, "Round not finished yet");
        require(isPlayerParticipatedInRound[poolIndex][roundIndex][first], "First place address didn't participate in the round");
        require(isPlayerParticipatedInRound[poolIndex][roundIndex][second], "Second place address didn't participate in the round");
        require(isPlayerParticipatedInRound[poolIndex][roundIndex][third], "Third place address didn't participate in the round");

        uint256 reward1 = _distributeReward(poolIndex, roundIndex, first, firstReward);
        uint256 reward2 = _distributeReward(poolIndex, roundIndex, second, secondReward);
        uint256 reward3 = _distributeReward(poolIndex, roundIndex, third, thirdReward);

        finishPayout[poolIndex][roundIndex] = true;
        round.totalFund = round.totalFund - reward1 - reward2 - reward3;

    }

    function _distributeReward(uint poolIndex, uint256 roundIndex, address winner, uint256 rewardPercentage) internal returns (uint256) {
        Round storage round = pools[poolIndex].rounds[roundIndex];
        uint256 rewardAmount = round.totalFund * rewardPercentage / 1000;
        rewards[poolIndex][winner] += rewardAmount;
        totalRewards[poolIndex] += rewardAmount;
        roundRewards[winner].push(playerReward(poolIndex, roundIndex, rewardAmount));
        userRewards[winner] += rewardAmount;
        return rewardAmount;
    }

    function getRewardsByOwner(address owner) view public returns (playerReward[] memory) {
        return roundRewards[owner];
    }

    function getRound(uint poolIndex, uint roundIndex) view public returns (uint256 totalFund, uint256 totalPlayers, address[] memory playerAddresses) {
        Round storage round = pools[poolIndex].rounds[roundIndex];
        return (round.totalFund, round.totalPlayers, round.playerAddresses);
    }

    function withdraw() external nonReentrant whenNotPaused {
        // uint256 reward =0;
        // for (uint i = 0; i < pools.length; i++) {
        //     reward+=rewards[i][msg.sender];
        //     totalRewards[i] -=rewards[i][msg.sender] ;
        //     rewards[i][msg.sender] = 0;
        // }
        // if ((reward==0) && (userRewards[msg.sender] > 0)){
        //     userRewards[msg.sender] = 0;
        // }else{
        // }
        require(userRewards[msg.sender] > 0, "No reward available");
        token.safeTransfer(msg.sender, userRewards[msg.sender]);
        userRewards[msg.sender] = 0;
    }


    function withdrawRemaining(address payable recipient) external onlyOwner {
        uint256 remainingBalance = token.balanceOf(address(this));
        require(remainingBalance > 0, "No remaining funds");

        uint256 totalPoolRewards = 0;
        for (uint i = 0; i < pools.length; i++) {
            totalPoolRewards += totalRewards[i];
        }

        uint256 transferAmount = remainingBalance - totalPoolRewards;
        token.safeTransfer(recipient, transferAmount);
    }

    function addOperator(address _operator) public onlyOwner {
        operator[_operator] = true;
    }
    function removeOperator(address _operator) public onlyOwner {
        operator[_operator] = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}
