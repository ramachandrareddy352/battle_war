// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TestDateTime.sol";

contract BattleWar is TestDateTime, ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _totalArmyCount;

    // errors
    error battleWar__ZeroAddressError();
    error battleWar__ArmyIsAlreadyExist();
    error battleWar__OneDayIsNotCompleted();
    error battleWar__NotEnoughMoney();
    error battleWar__ExceedAountOfPlayers();
    error battleWar__TokenDoesNotExist();
    error battleWar__TargetArmyNotFind();
    error battleWar__NotEnoughMoneyToAttack();
    error battleWar__NotEnoughArmyToAttack();
    error battleWar__LastAttackIsLessThanOneDay();
    error battleWar__NotEnoughTargetArmy();
    error BattelWar__YouDoNotHaveArmy();
    error BattleWar__ZeroPrice();

    // events
    event createdArmyEvent(address owner, string name);
    event attackArmyEvent(
        address owner, 
        address target, 
        address winner, 
        uint256 winningAmount, 
        uint256 attackCount
    );
    event buyArmyEvent(
        address owner,
        uint256 amount,
        uint16 _defenders,
        uint16 _attackers,
        uint16 _machines,
        uint16 _raiders,
        uint16 _health
    );

    // struct  // 60
    struct army {
        string name; // uint8 takes more gas than uint256
        uint16 defenders; // 5
        uint16 attackers; // 5
        uint16 machines; // 10
        uint16 raiders; // 15
        uint16 health; // 25
        uint16 winCount;
        uint16 lossCount;
        uint256 lastAttackTime;
        uint256 lastTimeRewardCollected;
    }

    // variables
    uint16 private constant QUANTITY_OF_PLAYERS = 100;
    uint256 private constant INITIAL_REWARD_AMOUNT = 1000;
    uint256 private constant DAILY_REWARD_AMOUNT = 200;
    uint256 private constant MAXIMUM_PLAYERS = 50000;
    uint256 private constant OFFER_AMOUNT = 5000;
    uint256 private i_ETHER_OFFER_AMOUNT = 10 ether;
    uint256 private constant ATTACK_AMOUNT_FEE = 250;
    uint256 private constant WINNING_AMOUNT_FOR_OWNER = 1250;
    uint256 private constant WINNING_AMOUNT_FOR_TARGET__OWNER = 500;
    address[] private s_players;

    // war tracking arrays;
    mapping(address owner => address[] targets) private ownerAttackedList;
    mapping(address attacker => address[] owners) private attackedByOwners;
    address[] private s_attackers;
    address[] private s_winners;
    address[] private s_targets;
    string[] private s_timeStamps;

    // mapping
    mapping(address owner => army myArmy) private ownerArmy;
    mapping(address owner => bool haveArmy) private createdArmyOrNot;
    mapping(address owner => uint256 balance) private balanceOfPlayer;
    mapping(address owner => uint256[] tokenIds) private s_tokenIdList;

    // modifiers
    modifier armyNotCreated() {
        if(!createdArmyOrNot[msg.sender]) {
            revert BattelWar__YouDoNotHaveArmy();
        }
        _;
    }

    constructor() ERC721("BattleWar", "BWAR") {}

    /* ---------------------------- PAYABLE FUNCTIONS ------------------------- */
    receive() external payable {}
    fallback() external payable {}

    /* ---------------------------- MINT REWARD ---------------------------- */
    string[25] private _tokenURI = ["a", "b", "c"];

    function mint(uint256 _winCount, address _owner) private nonReentrant returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_owner, tokenId);
        uint256 index = (_winCount / 5) - 1;
        _setTokenURI(tokenId, _tokenURI[index]);
        s_tokenIdList[_owner].push(tokenId);
        return (tokenId);
    }

    /* ---------------------------- WITHDRAW AMOUNT ---------------------------- */
    function withdrawAmount(address _owner) public payable nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        payable(_owner).transfer(balance);
    }

    /* ---------------------------- CREATE ARMY ---------------------------- */
    function createArmy(string memory _name) external nonReentrant returns (bool) {
        if (msg.sender == address(0)) {
            revert battleWar__ZeroAddressError();
        }
        if (createdArmyOrNot[msg.sender]) {
            revert battleWar__ArmyIsAlreadyExist();
        }
        createdArmyOrNot[msg.sender] = true;
        balanceOfPlayer[msg.sender] = INITIAL_REWARD_AMOUNT;
        s_players.push(msg.sender);
        ownerArmy[msg.sender] = army(_name, 5, 5, 5, 5, 5, 0, 0, block.timestamp, block.timestamp);
        _totalArmyCount.increment();
        emit createdArmyEvent(msg.sender, _name);
        return true;
    }

    /* ---------------------------- COLLECT DAILY REWARDS ---------------------------- */
    function collectDailyRewards() external nonReentrant armyNotCreated returns (bool) {
        army storage myArmy = ownerArmy[msg.sender];
        if (block.timestamp < myArmy.lastTimeRewardCollected + 1 days) {
            revert battleWar__OneDayIsNotCompleted();
        }
        balanceOfPlayer[msg.sender] += DAILY_REWARD_AMOUNT;
        myArmy.lastTimeRewardCollected = block.timestamp;
        return true;
    }

    /* ---------------------------- DESTROY ARMY ---------------------------- */
    function destroyArmy() external nonReentrant armyNotCreated returns (bool) {
        if (msg.sender == address(0)) {
            revert battleWar__ZeroAddressError();
        }
        balanceOfPlayer[msg.sender] = 0;
        ownerArmy[msg.sender] = army("", 0, 0, 0, 0, 0, 0, 0, 0, 0);
        createdArmyOrNot[msg.sender] = false;
        _totalArmyCount.decrement();
        return true;
    }

    /* ---------------------------- BUY ARMY PLAYERS ---------------------------- */
    function buyArmy(uint16 _defenders, uint16 _attackers, uint16 _machines, uint16 _raiders, uint16 _health)
        external
        nonReentrant
        armyNotCreated
        returns (bool)
    {
        return _buyArmy(_defenders, _attackers, _machines, _raiders, _health);
    }

    function _buyArmy(uint16 _defenders, uint16 _attackers, uint16 _machines, uint16 _raiders, uint16 _health)
        private
        returns (bool)
    {
        if (msg.sender == address(0)) {
            revert battleWar__ZeroAddressError();
        }
        army memory myArmyMemory = ownerArmy[msg.sender];
        if (
            (myArmyMemory.defenders + _defenders > MAXIMUM_PLAYERS)
                || (myArmyMemory.attackers + _attackers > MAXIMUM_PLAYERS)
                || (myArmyMemory.machines + _machines > MAXIMUM_PLAYERS)
                || (myArmyMemory.raiders + _raiders > MAXIMUM_PLAYERS) || (myArmyMemory.health + _health > MAXIMUM_PLAYERS)
        ) {
            revert battleWar__ExceedAountOfPlayers();
        }
        uint256 totalCost = (_attackers * 5) + (_defenders * 5) + (_machines * 10) + (_raiders * 15) + (_health * 25);
        if (balanceOfPlayer[msg.sender] < totalCost) {
            revert battleWar__NotEnoughMoney();
        }
        balanceOfPlayer[msg.sender] -= totalCost;
        army storage myArmy = ownerArmy[msg.sender];
        myArmy.defenders += _defenders;
        myArmy.attackers += _attackers;
        myArmy.machines += _machines;
        myArmy.raiders += _raiders;
        myArmy.health += _health;
        emit buyArmyEvent(msg.sender, totalCost, _defenders, _attackers, _machines, _raiders, _health);
        return true;
    }

    /* ---------------------------- BUY ARMY IN OFFER ---------------------------- */
    function buyArmyInOffer() external nonReentrant armyNotCreated returns (bool) {
        return _buyArmyInOffer();
    }

    function _buyArmyInOffer() private returns (bool) {
        if (msg.sender == address(0)) {
            revert battleWar__ZeroAddressError();
        }
        army memory myArmyMemory = ownerArmy[msg.sender];
        if (
            (myArmyMemory.defenders + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.attackers + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.machines + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.raiders + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.health + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
        ) {
            revert battleWar__ExceedAountOfPlayers();
        }
        if (balanceOfPlayer[msg.sender] < OFFER_AMOUNT) {
            revert battleWar__NotEnoughMoney();
        }
        balanceOfPlayer[msg.sender] -= OFFER_AMOUNT;
        army storage myArmy = ownerArmy[msg.sender];
        myArmy.defenders += QUANTITY_OF_PLAYERS;
        myArmy.attackers += QUANTITY_OF_PLAYERS;
        myArmy.machines += QUANTITY_OF_PLAYERS;
        myArmy.raiders += QUANTITY_OF_PLAYERS;
        myArmy.health += QUANTITY_OF_PLAYERS;
        emit buyArmyEvent(
            msg.sender,
            OFFER_AMOUNT,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS
        );
        return true;
    }

    /* ---------------------------- BUY ARMY WITH ETHERS ---------------------------- */
    function buyArmyWithEthers() public payable armyNotCreated nonReentrant {
        if (msg.sender == address(0)) {
            revert battleWar__ZeroAddressError();
        }
        army memory myArmyMemory = ownerArmy[msg.sender];
        if (
            (myArmyMemory.defenders + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.attackers + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.machines + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.raiders + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
                || (myArmyMemory.health + QUANTITY_OF_PLAYERS > MAXIMUM_PLAYERS)
        ) {
            revert battleWar__ExceedAountOfPlayers();
        }
        if (msg.value != i_ETHER_OFFER_AMOUNT) {
            // taking 10 ethers for buying army
            revert battleWar__NotEnoughMoney();
        }
        payable(address(this)).transfer(msg.value);
        army storage myArmy = ownerArmy[msg.sender];
        myArmy.defenders += QUANTITY_OF_PLAYERS;
        myArmy.attackers += QUANTITY_OF_PLAYERS;
        myArmy.machines += QUANTITY_OF_PLAYERS;
        myArmy.raiders += QUANTITY_OF_PLAYERS;
        myArmy.health += QUANTITY_OF_PLAYERS;
        emit buyArmyEvent(
            msg.sender,
            msg.value,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS,
            QUANTITY_OF_PLAYERS
        );
    }

    /* ---------------------------- ATTACK ARMY ---------------------------- */
    function getCount(address _targetArmyOwner) public view returns (uint256) {
        army memory myArmy = ownerArmy[msg.sender];
        army memory targetArmy = ownerArmy[_targetArmyOwner];
        uint256 count = 1; // if all are equal there is chance to win 60%
        if (balanceOfPlayer[msg.sender] > balanceOfPlayer[_targetArmyOwner]) count += 1;
        if (myArmy.defenders > targetArmy.defenders) count += 2;
        if (myArmy.attackers > targetArmy.attackers) count += 2;
        if (myArmy.machines >= targetArmy.machines) count += 3;
        if (myArmy.raiders >= targetArmy.raiders) count += 3;
        if (myArmy.health >= targetArmy.health) count += 5;
        if (myArmy.winCount > targetArmy.winCount) count += 1;
        if (myArmy.lossCount < targetArmy.lossCount) count += 1;
        return count;
    }

    function attackArmy(address _targetArmyOwner) external nonReentrant armyNotCreated returns (address) {
        if (!createdArmyOrNot[_targetArmyOwner] || _targetArmyOwner == msg.sender) {
            revert battleWar__TargetArmyNotFind();
        }
        if (balanceOfPlayer[msg.sender] < ATTACK_AMOUNT_FEE) {
            revert battleWar__NotEnoughMoneyToAttack();
        }

        army memory m_myArmy = ownerArmy[msg.sender];
        army memory m_targetArmy = ownerArmy[_targetArmyOwner];
        if (
            m_myArmy.defenders <= 5 || m_myArmy.attackers <= 5 || m_myArmy.machines <= 5 || m_myArmy.raiders <= 5
                || m_myArmy.health <= 5
        ) {
            revert battleWar__NotEnoughArmyToAttack();
        }
        if (
            m_targetArmy.defenders < 5 || m_targetArmy.attackers < 5 || m_targetArmy.machines < 5
                || m_targetArmy.raiders < 5 || m_targetArmy.health < 5
        ) {
            revert battleWar__NotEnoughTargetArmy();
        }

        if (block.timestamp < m_myArmy.lastAttackTime + 1 days) {
            revert battleWar__LastAttackIsLessThanOneDay();
        }
        balanceOfPlayer[msg.sender] -= ATTACK_AMOUNT_FEE;
        uint256 count = getCount(_targetArmyOwner);

        uint256 number = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, block.number, block.timestamp))
        ) % 100;

        ownerAttackedList[msg.sender].push(_targetArmyOwner);
        attackedByOwners[_targetArmyOwner].push(msg.sender);
        s_attackers.push(msg.sender);
        s_targets.push(_targetArmyOwner);

        uint256 m_getYear = getYear(block.timestamp);
        uint256 m_getMonth = getMonth(block.timestamp);
        uint256 m_getDay = getDay(block.timestamp);
        // string memory str_getYear = uintToString(m_getYear);
        // string memory str_getMonth = uintToString(m_getMonth);
        // string memory str_getDay = uintToString(m_getDay);
        string memory dateInString =
            concatStrings(uintToString(m_getDay), "/", uintToString(m_getMonth), "/", uintToString(m_getYear));
        s_timeStamps.push(dateInString);

        return changeStatesOfArmy(number, count, msg.sender, _targetArmyOwner);
    }

    function changeStatesOfArmy(uint256 number, uint256 count, address _owner, address _targetArmyOwner)
        private
        returns (address winner)
    {
        army storage s_myArmy = ownerArmy[_owner];
        army storage s_targetArmy = ownerArmy[_targetArmyOwner];
        if (number <= count * 5) {
            s_myArmy.winCount++;
            s_targetArmy.lossCount++;
            s_myArmy.lastAttackTime = block.timestamp;
            s_winners.push(_owner);
            if (s_myArmy.winCount % 5 == 0) {
                mint(s_myArmy.winCount, _owner);
            }
            balanceOfPlayer[_owner] += WINNING_AMOUNT_FOR_OWNER;
            reduceLessArmy(_owner);
            // reduceLessArmy(_targetArmyOwner);
            emit attackArmyEvent(_owner, _targetArmyOwner, _owner, WINNING_AMOUNT_FOR_OWNER, s_winners.length);
            return _owner;
        } else {
            s_targetArmy.winCount++;
            s_myArmy.lossCount++;
            s_myArmy.lastAttackTime = block.timestamp;
            s_winners.push(_targetArmyOwner);
            balanceOfPlayer[_targetArmyOwner] += WINNING_AMOUNT_FOR_TARGET__OWNER;
            reduceMoreArmy(_owner);
            // reduceLessArmy(_targetArmyOwner);
            emit attackArmyEvent(
                _owner, _targetArmyOwner, _targetArmyOwner, WINNING_AMOUNT_FOR_TARGET__OWNER, s_winners.length
            );
            return _targetArmyOwner;
        }
    }

    /* ---------------------------- REDUCE ARMY ---------------------------- */
    function reduceMoreArmy(address _owner) private {
        army storage s_myArmy = ownerArmy[_owner];
        s_myArmy.defenders -= 5;
        s_myArmy.attackers -= 5;
        s_myArmy.machines -= 5;
        s_myArmy.raiders -= 5;
        s_myArmy.health -= 5;
    }

    function reduceLessArmy(address _owner) private {
        army storage s_myArmy = ownerArmy[_owner];
        s_myArmy.defenders -= 2;
        s_myArmy.attackers -= 2;
        s_myArmy.machines -= 2;
        s_myArmy.raiders -= 2;
        s_myArmy.health -= 2;
    }

    function change_eth_offer_amount(uint newPrice) external onlyOwner nonReentrant {
        if(newPrice <= 0) {
            revert BattleWar__ZeroPrice();
        }
        i_ETHER_OFFER_AMOUNT = newPrice;
    }

    /* ----------------------------- GETTER FUNCTIONS ----------------------------- */

    function get_TokenURI(uint256 _tokenId) external view returns (string memory) {
        if (!_exists(_tokenId)) {
            revert battleWar__TokenDoesNotExist();
        }
        string memory URI = tokenURI(_tokenId);
        return URI;
    }

    function get_Owner(uint256 _tokenId) external view returns (address) {
        if (!_exists(_tokenId)) {
            revert battleWar__TokenDoesNotExist();
        }
        return ownerOf(_tokenId);
    }

    function get_QUANTITY_OF_PLAYERS() external pure returns (uint256) {
        return QUANTITY_OF_PLAYERS;
    }

    function get_totalArmyCount() external view returns (uint256) {
        return _totalArmyCount.current();
    }

    function get_INITIAL_REWARD_AMOUNT() external pure returns (uint256) {
        return INITIAL_REWARD_AMOUNT;
    }

    function get_DAILY_REWARD_AMOUNT() external pure returns (uint256) {
        return DAILY_REWARD_AMOUNT;
    }

    function get_MAXIMUM_PLAYERS() external pure returns (uint256) {
        return MAXIMUM_PLAYERS;
    }

    function get_OFFER_AMOUNT() external pure returns (uint256) {
        return OFFER_AMOUNT;
    }

    function get_ATTACK_AMOUNT_FEE() external pure returns (uint256) {
        return ATTACK_AMOUNT_FEE;
    }

    function get_WINNING_AMOUNT_FOR_OWNER() external pure returns (uint256) {
        return WINNING_AMOUNT_FOR_OWNER;
    }

    function get_WINNING_AMOUNT_FOR_TARGET__OWNER() external pure returns (uint256) {
        return WINNING_AMOUNT_FOR_TARGET__OWNER;
    }

    function get_playersList() external view returns (address[] memory) {
        return s_players;
    }

    function get_ownerAttackedList(address _owner) external view returns (address[] memory) {
        return ownerAttackedList[_owner];
    }

    function get_attackedByOwners(address _target) external view returns (address[] memory) {
        return attackedByOwners[_target];
    }

    function get_s_attackers() external view returns (address[] memory) {
        return s_attackers;
    }

    function get_s_winners() external view returns (address[] memory) {
        return s_winners;
    }

    function get_s_targets() external view returns (address[] memory) {
        return s_targets;
    }

    function get_s_timeStamps() external view returns (string[] memory) {
        return s_timeStamps;
    }

    function get_ownerArmy(address _owner) external view returns (army memory) {
        return ownerArmy[_owner];
    }

    function get_createdArmyOrNot(address _owner) external view returns (bool) {
        return createdArmyOrNot[_owner];
    }

    function get_balanceOfPlayer(address _owner) external view returns (uint256) {
        return balanceOfPlayer[_owner];
    }

    function get_s_tokenIdList(address _owner) external view returns (uint256[] memory) {
        return s_tokenIdList[_owner];
    }
}
