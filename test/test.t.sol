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
    address alice = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public {
    vm.deal(msg.sender, 100e18);
    escrow = new VoteEscrow(1e18, 1, 0xb1e6c0c42f8fb97d163dbe3c1f0f6eefe163079b563207a4b8c3ff302ee16b34, "");
    console.log("escrow address: ", address(escrow));
    
    
    
    }

    // function setUp() public {
    //     bytes32 root = 0x5953f6bf40295df057e07ef118f739fc49b2fdb8aa8aa78567858b2ebec71f57;
    //     string memory URI = "nft";
    //     escrow = new VoteEscrow(1e18, 1, root, URI);
    //     vm.deal(bob, 10 ether);
    //     // log_uint256(bob.balance);
    //     vm.prank(bob);
    // }


    function test_ableToVote() public {
      
        (bool sent, bytes memory data) = address(escrow).call{value: 1e18, gas: 200000}(abi.encodeWithSignature("depositVote(bool)",true));
        require(sent, "Failed to send Ether");
        
    }

}