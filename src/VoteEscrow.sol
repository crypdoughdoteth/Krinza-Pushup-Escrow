pragma solidity 0.8.19;

contract VoteEscrow {
    uint immutable wager;
    mapping(address => bool) public addyToVote;
    mapping(address => bool) public voted;
    mapping(address => bool) public outcomeVoted;
    uint public countLove;
    uint public countHate;
    bool locked;
    address public owner;
    uint trueAttestation;
    uint falseAttestation;
    bytes32 state;

    //temp to delet
    uint public totalValue;

    constructor(uint betAmount) {
        wager = betAmount;
        owner = msg.sender;
    }

    function lockBets() external {
        require(msg.sender == owner);
        locked = true;
    }

    //in native asset of chain
    function depositVote(bool vote) external payable {
        require(!locked);
        require(msg.value >= wager);
        require(!voted[msg.sender]);
        addyToVote[msg.sender] = vote;
        voted[msg.sender] = true;
        totalValue += msg.value;
        if (vote == true) {
            ++countLove;
        } else {
            ++countHate;
        }
    }

    // Vote after the time lock
    // function voteOutcome(bytes32[] calldata proof, uint index, bool decision) external {
    //     require(verifyProof(proof, index, msg.sender), "failed to verify proof");
    //     require(!outcomeVoted[msg.sender]);
    //     outcomeVoted[msg.sender] = true;
    //     if (decision == true){
    //         ++trueAttestation;
    //     }
    //     else {
    //         ++falseAttestation;
    //     }
    // }
    function voteOutcome(
        bytes32[] calldata proof,
        uint index,
        bool decision
    ) external {
        require(verifyProof(state, proof, msg.sender, index), "failed to verify proof");
        if (decision == true) {
            ++trueAttestation;
        } else {
            ++falseAttestation;
        }
    }

    //Put a time lock in here somewhere
    function collectPayout() external {
        bool outcome = deliverOutcome();
        require(addyToVote[msg.sender] == outcome);
        require(voted[msg.sender]);
        uint payout = calculatePayout();
        (bool sent, ) = (msg.sender).call{value: payout}("");
        require(sent);
    }

    function calculatePayout() internal view returns (uint) {
        require(locked);
        bool oc = deliverOutcome();
        if (oc == true) {
            //split by true vote
            return (wager * (countHate + countLove)) / countLove;
        } else {
            //split by false vote
            return (wager * (countHate + countLove)) / countHate;
        }
    }

    function deliverOutcome() internal view returns (bool) {
        if (trueAttestation > falseAttestation) {
            return true;
        } else {
            return false;
        }
    }

    function setState(bytes32 root) external {
        require(msg.sender == owner);
        state = root;
    }

    function verifyProof(
        bytes32 root,
        bytes32[] memory proof,
        address leaf,
        uint index
    ) public pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(leaf));

        for (uint i = 0; i < proof.length; i++) {
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

    // function verifyProof(bytes32[] calldata proof, uint index, address leafAddy) public view returns (bool) {
    //     bytes32 addyHash = keccak256(abi.encodePacked(leafAddy));
    //     for (uint i = 0; i < proof.length - 1; ++i){
    //         bytes32 proofElement = proof[i];
    //         if (index % 2 == 0) {
    //             addyHash = keccak256(abi.encodePacked(addyHash, proofElement));
    //         } else {
    //             addyHash = keccak256(abi.encodePacked(proofElement, addyHash));
    //         }

    //         index = index / 2;
    //     }
    //     return addyHash == state;
    // }
}
