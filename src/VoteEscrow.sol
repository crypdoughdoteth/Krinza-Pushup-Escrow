// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title An escrow contract where the community verifies the outcome of an event that triggers a payout.
/// @custom:experimental This is an experimental contract.

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract VoteEscrow is ERC1155 {
    event deposit(uint256 amount, bool believer);
    event winnerPayout(uint256 amount);
    event votedOutcome(bool);
    event lock(uint256 num);
    event gameEnded(uint256 num);

    uint256 immutable wager;
    //tracks who voted for what
    mapping(address => bool) public addyToVote;
    //prevents double voting in the contest
    mapping(address => bool) public voted;
    //tracks which judges already voted for the success or failure of krinza's pushups
    mapping(address => bool) public outcomeVoted;
    mapping(address => bool) public votedToLock;
    mapping(address => bool) public votedToEndGame;
    mapping(address => bool) public paid;
    uint32 public countLove;
    uint32 public countHate;
    uint256 locked;
    uint256 gameOver;
    uint32 immutable validatorCount;
    uint32 trueAttestation;
    uint32 falseAttestation;
    bytes32 immutable state;
    uint256 prizeShareSize;
    string public tokenURI;

    //temp to delet
    uint256 public totalValue;

    constructor(uint256 betAmount, uint32 validators, bytes32 root, string memory URI) ERC1155("") {
        wager = betAmount;
        validatorCount = validators;
        state = root;
        tokenURI = URI;
    }

    /// @dev Only wallets set on offchain merkle tree can call this function to stops bets
    function lockBets(bytes32[] calldata proof, uint256 index) external {
        require(verifyProof(state, proof, msg.sender, index), "failed to verify proof");
        require(!votedToLock[msg.sender]);
        votedToLock[msg.sender] = true;
        locked += 1e18;
        emit lock(locked);
    }

    /// @dev Only wallets set on offchain merkle tree can call this function to end the game
    function endGame(bytes32[] calldata proof, uint256 index) external {
        //at least half of the validators must have voted
        require((trueAttestation + falseAttestation) * 10 ** 18 >= (validatorCount * 10 ** 18) / 2);
        //bets must have been locked first
        require(locked >= (validatorCount * 10 ** 18) / 2);
        require(verifyProof(state, proof, msg.sender, index), "failed to verify proof");
        require(!votedToEndGame[msg.sender]);
        votedToEndGame[msg.sender] = true;
        gameOver += 1e18;
        emit gameEnded(gameOver);
    }

    /// @dev In native asset to cast vote and recieve NFT
    function depositVote(bool vote) external payable {
        require((locked < (validatorCount * 10 ** 18) / 2), "bets locked");
        require((msg.value == wager), "wrong amount");
        require(!voted[msg.sender], "already voted");
        addyToVote[msg.sender] = vote;
        voted[msg.sender] = true;
        //don't forget to delete line below
        totalValue += msg.value;
        if (vote) {
            ++countLove;
            _mint(msg.sender, 0, 1, "");
        } else {
            ++countHate;
            _mint(msg.sender, 1, 1, "");
        }
        emit deposit(msg.value, vote);
    }

    /// @dev Vote after bets lock
    function voteOutcome(bytes32[] calldata proof, uint256 index, bool decision) external {
        require(verifyProof(state, proof, msg.sender, index), "failed to verify proof");
        //bets must be locked
        require((locked >= (validatorCount * 10 ** 18) / 2), "bets not locked");
        //no double voting
        require(!outcomeVoted[msg.sender]);
        outcomeVoted[msg.sender] = true;
        if (decision) {
            ++trueAttestation;
        } else {
            ++falseAttestation;
        }
        emit votedOutcome(decision);
    }

    function collectPayout() external {
        require((gameOver >= (validatorCount * 10 ** 18) / 2), "game not over");
        require(!paid[msg.sender], "already paid");
        bool outcome = deliverOutcome();
        require(addyToVote[msg.sender] == outcome, "you voted wrong");
        require(voted[msg.sender], "you didn't vote");
        paid[msg.sender] = true;
        uint256 payout = calculatePayout(outcome);
        (bool sent,) = (msg.sender).call{value: payout}("");
        require(sent, "Failed to send Ether");
        emit winnerPayout(prizeShareSize);
    }

    function calculatePayout(bool oc) internal returns (uint256) {
        // condition is only true the first time it runs, so state is set only then, the rest simply returns prizeShareSize
        if (prizeShareSize == 0) {
            if (oc == true) {
                //split by true vote
                prizeShareSize = address(this).balance / uint256(countLove);
            } else {
                //split by false vote
                prizeShareSize = address(this).balance / uint256(countHate);
            }
        }
        return prizeShareSize;
    }

    function deliverOutcome() internal view returns (bool) {
        if (trueAttestation > falseAttestation) {
            return true;
        } else {
            return false;
        }
    }

    function verifyProof(bytes32 root, bytes32[] memory proof, address leaf, uint256 index)
        public
        pure
        returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(leaf));

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == root;
    }

    /// @dev implementing 1155 functions for the NFT
    function name() public pure returns (string memory) {
        return "Krinza Push Up";
    }

    function symbol() public pure returns (string memory) {
        return "PUSH";
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(tokenURI, Strings.toString(_tokenId)));
    }
}
