pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";

import "../src/VoteEscrow.sol";
//Need this because when test from contract, this contract will recieve an 1155 token. So needs to have a the reciever function
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ContractTest is Test, ERC1155Holder {
    VoteEscrow public escrow;
    address alice = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
    //Proof we recieved from running trees.js with allowlist of 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
    //odd reason - need to typecast each value
    bytes32[] proof = [
        bytes32(0x1353b521f4d4677111dc2223972696fb560c95f95ade5c12c1ebccb9c05e411e),
        bytes32(0xdd8bcb48f3721a782a5b92e5e52f3e272683acf506ae930613244355c4fd0048)
    ];
    uint256 deposit;

    function setUp(uint256 depositValue) public {
        //fuzzing
        // can use variable twice
        vm.assume(depositValue < 100); //if this condition is fasle, value discarded
        vm.assume(depositValue > 100e18);
        deposit = depositValue;
        vm.deal(msg.sender, 100e18);
        // escrow = new VoteEscrow(1e18, 1, 0x8105e4bfc32133bb21f02a967af16a94f24158434c51f2aba115b6856d85ea7c, "");
        escrow = new VoteEscrow(depositValue, 1, 0x8105e4bfc32133bb21f02a967af16a94f24158434c51f2aba115b6856d85ea7c, "");
        //console.log("escrow address: ", address(escrow));
    }

    function test_ableToVote() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");
    }

    function testFail_ToVote_NotEnough() public {
        vm.expectRevert("wrong amount");
        (bool sent, bytes memory data) =
            address(escrow).call{value: 1e17, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");
    }

    function testFail_ToVoteTwice() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.expectRevert("already voted");
        (bool sentagain, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sentagain, "Failed to send Ether");
    }

    function test_ToVoteMany() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");
        vm.startPrank(address(0x1));
        vm.deal(address(0x1), 100e18);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();
        vm.startPrank(address(0x2));
        vm.deal(address(0x2), 100e18);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();
        uint256 total = deposit * 3;
        console.log("total: ", total);
        // uint tempToal = escrow.totalValue();
        // console.log("tempToal: ", tempToal);
        //  assertEq(escrow.totalValue(), total);
    }

    function testFail_ToVoteAfterLock() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.startPrank(address(0x1));
        vm.deal(address(0x1), 100e18);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        vm.deal(address(0x2), 100e18);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(alice);
        escrow.lockBets(proof, 0);
        vm.stopPrank();

        vm.startPrank(address(0x4));
        vm.deal(address(0x4), 100e18);
        (bool sent4, bytes memory data4) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent4, "Failed to send Ether");
        vm.stopPrank();
    }

    // Not working with fuzz testing
    function test_WithdrawWinning() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.startPrank(address(0x32C9c98aBD1215f01b1E6056D6BFc84FD975508d));
        vm.deal(address(0x32C9c98aBD1215f01b1E6056D6BFc84FD975508d), deposit);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5));
        vm.deal(address(0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5), deposit);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x58bb47a89A329305cbD63960C3F544cfA4584db9));
        vm.deal(address(0x58bb47a89A329305cbD63960C3F544cfA4584db9), deposit);
        (bool sent4, bytes memory data4) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent4, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(alice);
        escrow.lockBets(proof, 0);

        //vote outcome
        escrow.voteOutcome(proof, 0, true);
        //end game
        escrow.endGame(proof, 0);
        vm.stopPrank();
        //collect
        escrow.collectPayout();

        vm.startPrank(address(0x4));
        escrow.collectPayout();
        vm.stopPrank();
    }

    function testFail_WithdrawLosing() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.startPrank(address(0x1));
        vm.deal(address(0x1), deposit);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        vm.deal(address(0x2), 100e18);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x4));
        vm.deal(address(0x4), 100e18);
        (bool sent4, bytes memory data4) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent4, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(alice);
        escrow.lockBets(proof, 0);

        //vote outcome
        escrow.voteOutcome(proof, 0, false);
        //end game
        escrow.endGame(proof, 0);
        vm.stopPrank();

        // winners collect
        vm.startPrank(address(0x1));
        escrow.collectPayout();
        vm.stopPrank();

        vm.startPrank(address(0x2));
        escrow.collectPayout();
        vm.stopPrank();

        //collect non winners
        escrow.collectPayout();

        vm.startPrank(address(0x4));
        escrow.collectPayout();
        vm.stopPrank();
    }

    function testFail_WithdrawTwice() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.startPrank(address(0x1));
        vm.deal(address(0x1), 100e18);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        vm.deal(address(0x2), 100e18);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x4));
        vm.deal(address(0x4), 100e18);
        (bool sent4, bytes memory data4) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent4, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(alice);
        escrow.lockBets(proof, 0);

        //vote outcome
        escrow.voteOutcome(proof, 0, true);
        //end game
        escrow.endGame(proof, 0);
        vm.stopPrank();
        //collect non winners
        escrow.collectPayout();
        //try to collect again - should fail
        escrow.collectPayout();
        vm.stopPrank();
    }

    function testFail_NoAllowLockBet() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.startPrank(address(0x1));
        vm.deal(address(0x1), 100e18);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        vm.deal(address(0x2), 100e18);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x4));
        vm.deal(address(0x4), 100e18);
        (bool sent4, bytes memory data4) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent4, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        escrow.lockBets(proof, 0);
        vm.stopPrank();
    }

    function testFail_WithdrawBeforeGameOver() public {
        (bool sent, bytes memory data) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent, "Failed to send Ether");

        vm.startPrank(address(0x1));
        vm.deal(address(0x1), 100e18);
        (bool sent2, bytes memory data2) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent2, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x2));
        vm.deal(address(0x2), 100e18);
        (bool sent3, bytes memory data3) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", false));
        require(sent3, "Failed to send Ether");
        vm.stopPrank();

        vm.startPrank(address(0x4));
        vm.deal(address(0x4), 100e18);
        (bool sent4, bytes memory data4) =
            address(escrow).call{value: deposit, gas: 200000}(abi.encodeWithSignature("depositVote(bool)", true));
        require(sent4, "Failed to send Ether");
        vm.stopPrank();

        escrow.collectPayout();
    }

    // need this to receive payout from escrow contract
    fallback() external payable {
        //console.log("fallback called");
    }

    receive() external payable {}
}
