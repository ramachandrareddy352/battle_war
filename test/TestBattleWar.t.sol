// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {BattleWar} from "../src/BattleWar.sol";

contract TestBattleWar is StdCheats, Test{
    
    BattleWar battleWar;
    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);
    address user4 = address(4);
    address user5 = address(5);
    
    receive() external payable {}
    fallback() external payable {}

    function setUp() external {
        battleWar = new BattleWar();
    }

    function test_RevertsForNonExistToken() public {
        vm.expectRevert(BattleWar.battleWar__TokenDoesNotExist.selector);
        battleWar.get_TokenURI(1);
    }

    function test_Name_Symbol() public {
        string memory symbol = battleWar.symbol();
        string memory name = battleWar.name();
        assertEq(symbol, "BWAR");
        assertEq(name, "BattleWar");
    }

    function test_CreateArmy() public {
        vm.startPrank(user1);
        assert(!battleWar.get_createdArmyOrNot(user1));  // initially army is not created

        assert(battleWar.createArmy("rama"));   // creating army by user-1
        assert(battleWar.get_createdArmyOrNot(user1));  // testing that army is created
        
        uint256 initialCount = 5;
        assertEq(battleWar.get_ownerArmy(user1).name, "rama");
        assertEq(battleWar.get_ownerArmy(user1).defenders, initialCount);
        assertEq(battleWar.get_ownerArmy(user1).attackers, initialCount);
        assertEq(battleWar.get_ownerArmy(user1).machines, initialCount);
        assertEq(battleWar.get_ownerArmy(user1).raiders, initialCount);
        assertEq(battleWar.get_ownerArmy(user1).health, initialCount);
        assertEq(battleWar.get_ownerArmy(user1).winCount, 0);
        assertEq(battleWar.get_ownerArmy(user1).lossCount, 0);
        assertEq(battleWar.get_ownerArmy(user1).lastAttackTime, block.timestamp);
        assertEq(battleWar.get_ownerArmy(user1).lastTimeRewardCollected, block.timestamp);

        // checking balance
        assertEq(battleWar.get_balanceOfPlayer(user1), 1000);
        vm.stopPrank();
    }

    function test_RevertsIfZeroAddress() public {
        vm.startPrank(address(0));
        vm.expectRevert(BattleWar.battleWar__ZeroAddressError.selector);
        battleWar.createArmy("rama");
        vm.stopPrank();
    }

    function test_RevertsIfArmyIsAlreadyCreated() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");

        vm.expectRevert(BattleWar.battleWar__ArmyIsAlreadyExist.selector);  // reverts if address has already army
        battleWar.createArmy("chandu");
        vm.stopPrank();
    }

    function test_RevertsNotCompletingDay() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        vm.expectRevert(BattleWar.battleWar__OneDayIsNotCompleted.selector);
        battleWar.collectDailyRewards();
        vm.stopPrank();
    }

    function test_collectDailyRewards() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        assertEq(battleWar.get_ownerArmy(user1).lastTimeRewardCollected, 1); 
        // moving block.timestamp to 2 days further
        skip(2 days);
        assert(battleWar.collectDailyRewards());
        assertEq(battleWar.get_balanceOfPlayer(user1), battleWar.get_INITIAL_REWARD_AMOUNT() + battleWar.get_DAILY_REWARD_AMOUNT());
        assertEq(battleWar.get_ownerArmy(user1).lastTimeRewardCollected, block.timestamp);
        vm.stopPrank();
    }

    function test_ReverstForNotExistArmyDestroy() public {
        vm.startPrank(user1);
        vm.expectRevert(BattleWar.BattelWar__YouDoNotHaveArmy.selector);
        battleWar.destroyArmy();
        vm.stopPrank();
    }

    function test_SuccessfullyDestroyArmy() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        assertEq(battleWar.get_totalArmyCount(),1);
        // here we destroying our army
        assert(battleWar.destroyArmy());
        assertEq(battleWar.get_totalArmyCount(),0);
        assertEq(battleWar.get_ownerArmy(user1).name,"");
        assertEq(battleWar.get_ownerArmy(user1).defenders,0);
        assertEq(battleWar.get_ownerArmy(user1).attackers,0);
        assertEq(battleWar.get_ownerArmy(user1).machines,0);
        assertEq(battleWar.get_ownerArmy(user1).raiders,0);
        assertEq(battleWar.get_ownerArmy(user1).health,0);
        assertEq(battleWar.get_ownerArmy(user1).lastAttackTime,0);
        assertEq(battleWar.get_ownerArmy(user1).lastTimeRewardCollected,0);
        vm.stopPrank();
    }

    function test_RevetsFotInsufficientBalance() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        vm.expectRevert(BattleWar.battleWar__NotEnoughMoney.selector);
        battleWar.buyArmy(100, 100, 100, 100, 100);
        vm.stopPrank();
    }

    function test_RevertsIfExceedOfMaximumPlayers() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        uint256 MAX_PLAYERS = battleWar.get_MAXIMUM_PLAYERS();
        vm.expectRevert(BattleWar.battleWar__ExceedAountOfPlayers.selector);
        battleWar.buyArmy(uint16(MAX_PLAYERS), 100, 100, 100, 100);
        vm.stopPrank();
    }

    function test_SuccessfullyBoughtArmy() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        uint256 beforeBalance = battleWar.get_balanceOfPlayer(user1);
        uint256 beforeDefenders = battleWar.get_ownerArmy(user1).defenders;
        uint256 beforeAttackers = battleWar.get_ownerArmy(user1).attackers;
        uint256 beforeMachines = battleWar.get_ownerArmy(user1).machines;
        uint256 beforeRaiders = battleWar.get_ownerArmy(user1).raiders;
        uint256 beforeHealth = battleWar.get_ownerArmy(user1).health;
        assert(battleWar.buyArmy(10,5,15,10,5));
        // (10*5) + (5*5) + (15*10) + (10*15) + (5+25) => 500
        uint256 afterBalance = battleWar.get_balanceOfPlayer(user1);
        uint256 afterDefenders = battleWar.get_ownerArmy(user1).defenders;
        uint256 afterAttackers = battleWar.get_ownerArmy(user1).attackers;
        uint256 afterMachines = battleWar.get_ownerArmy(user1).machines;
        uint256 afterRaiders = battleWar.get_ownerArmy(user1).raiders;
        uint256 afterHealth = battleWar.get_ownerArmy(user1).health;

        assertEq(beforeBalance, afterBalance + 500);
        assertEq(beforeDefenders + 10, afterDefenders);
        assertEq(beforeAttackers + 5, afterAttackers);
        assertEq(beforeMachines + 15, afterMachines);
        assertEq(beforeRaiders + 10, afterRaiders);
        assertEq(beforeHealth + 5, afterHealth);
        vm.stopPrank();
    }

    function skip_time() public {
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
        skip(2 days);
        battleWar.collectDailyRewards();
    }

    function test_BuyArmyInOffer() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        skip_time();
        uint256 beforeBalance = battleWar.get_balanceOfPlayer(user1); // 6000
        uint256 beforeDefenders = battleWar.get_ownerArmy(user1).defenders;
        uint256 beforeAttackers = battleWar.get_ownerArmy(user1).attackers;
        uint256 beforeMachines = battleWar.get_ownerArmy(user1).machines;
        uint256 beforeRaiders = battleWar.get_ownerArmy(user1).raiders;
        uint256 beforeHealth = battleWar.get_ownerArmy(user1).health;

        assert(battleWar.buyArmyInOffer());

        uint256 afterBalance = battleWar.get_balanceOfPlayer(user1);
        uint256 afterDefenders = battleWar.get_ownerArmy(user1).defenders;
        uint256 afterAttackers = battleWar.get_ownerArmy(user1).attackers;
        uint256 afterMachines = battleWar.get_ownerArmy(user1).machines;
        uint256 afterRaiders = battleWar.get_ownerArmy(user1).raiders;
        uint256 afterHealth = battleWar.get_ownerArmy(user1).health;

        uint256 qop = battleWar.get_QUANTITY_OF_PLAYERS();

        assertEq(beforeBalance, afterBalance + 5000);
        assertEq(beforeDefenders + qop, afterDefenders);
        assertEq(beforeAttackers + qop, afterAttackers);
        assertEq(beforeMachines + qop, afterMachines);
        assertEq(beforeRaiders + qop, afterRaiders);
        assertEq(beforeHealth + qop, afterHealth);
        vm.stopPrank();
    }

    function test_BuyArmyWithEthers() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        vm.deal(user1, 12 ether);  // sending 12 ethers
        assertEq(address(user1).balance, 12 ether);
        
        battleWar.buyArmyWithEthers{value: 10 ether}();
        assertEq(address(user1).balance, 2 ether);
        vm.stopPrank();
    }

    function test_RevertsForInsufficientBalance() public {
        vm.startPrank(user1);
        battleWar.createArmy("rama");
        vm.deal(user1, 12 ether);  // sending 12 ethers
        assertEq(address(user1).balance, 12 ether);
        
        vm.expectRevert(BattleWar.battleWar__NotEnoughMoney.selector);
        battleWar.buyArmyWithEthers{value: 1 ether}();
        vm.stopPrank();
    }

    // function test_count() public {
    //     vm.prank(user1);
    //     battleWar.createArmy("rama");
    //     vm.prank(user2);
    //     battleWar.createArmy("chandu");

    //     uint players = battleWar.get_playersList().length;
    //     assertEq(players, 2);
    //     vm.prank(user1);
    //     uint256 getCount = battleWar.getCount(user2);
    //     assertEq(getCount, 12);
    //     // if both army have same properties then there is probability of 60% to win for owner
    // }

    function test_AttackArmy() public {
        vm.prank(user1);
        battleWar.createArmy("rama");
        vm.prank(user2);
        battleWar.createArmy("chandu");

        vm.startPrank(user1);
        battleWar.buyArmy(2,2,2,2,2);
        skip(2 days);
        
        // data before attack of user-1
        uint256 user_1BeforeBalance = battleWar.get_balanceOfPlayer(user1);
        uint256 user_1BeforeDefenders = battleWar.get_ownerArmy(user1).defenders;
        uint256 user_1BeforeWinCount = battleWar.get_ownerArmy(user1).winCount;
        uint256 user_1BeforeLossCount = battleWar.get_ownerArmy(user1).lossCount;

        // data before attack of user-2
        uint256 user_2BeforeBalance = battleWar.get_balanceOfPlayer(user2);
        uint256 user_2BeforeWinCount = battleWar.get_ownerArmy(user2).winCount;
        uint256 user_2BeforeLossCount = battleWar.get_ownerArmy(user2).lossCount;

        address winner = battleWar.attackArmy(user2);
        uint256 attack_fee = battleWar.get_ATTACK_AMOUNT_FEE();
        uint256 winning_amount_for_owner = battleWar.get_WINNING_AMOUNT_FOR_OWNER();
        uint256 winning_amount_for_target = battleWar.get_WINNING_AMOUNT_FOR_TARGET__OWNER();

        // data after attack of user-1
        uint256 user_1AfterBalance = battleWar.get_balanceOfPlayer(user1);
        uint256 user_1AfterDefenders = battleWar.get_ownerArmy(user1).defenders;
        uint256 user_1AfterWinCount = battleWar.get_ownerArmy(user1).winCount;
        uint256 user_1AfterLossCount = battleWar.get_ownerArmy(user1).lossCount;

        // data after attack of user-2
        uint256 user_2AfterBalance = battleWar.get_balanceOfPlayer(user2);
        uint256 user_2AfterWinCount = battleWar.get_ownerArmy(user2).winCount;
        uint256 user_2AfterLossCount = battleWar.get_ownerArmy(user2).lossCount;

        if(winner == user1) {
            assertEq(user_1BeforeBalance - attack_fee + winning_amount_for_owner, user_1AfterBalance);
            assertEq(user_1BeforeDefenders, user_1AfterDefenders + 2);
            assertEq(user_1BeforeWinCount + 1, user_1AfterWinCount);
            assertEq(user_1BeforeLossCount, user_1AfterLossCount);

            assertEq(user_2BeforeBalance, user_2AfterBalance);
            assertEq(user_2BeforeWinCount, user_2AfterWinCount);
            assertEq(user_2BeforeLossCount + 1, user_2AfterLossCount);
        }
        else {
            assertEq(user_1BeforeBalance - attack_fee, user_1AfterBalance);
            assertEq(user_1BeforeDefenders, user_1AfterDefenders + 5);
            assertEq(user_1BeforeWinCount, user_1AfterWinCount);
            assertEq(user_1BeforeLossCount + 1, user_1AfterLossCount);

            assertEq(user_2BeforeBalance + winning_amount_for_target, user_2AfterBalance);
            assertEq(user_2BeforeWinCount + 1, user_2AfterWinCount);
            assertEq(user_2BeforeLossCount, user_2AfterLossCount);
        }
        vm.stopPrank();
    }
}