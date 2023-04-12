pragma solidity 0.8.19; 
contract VoteEscrow {
    
    uint immutable wager; 
    mapping (address => bool) public addyToVote;
    uint countLove;
    uint countHate;
    bool locked;
    address owner;
    uint trueAttestation;
    uint falseAttestation;
    bytes32 state; 

    constructor(uint betAmount) {
        wager = betAmount;
        owner == msg.sender;
    }

    function lockBets() external {
        require(msg.sender == owner);
        locked = true;
    }
    //in native asset of chain
    function depositVote(bool vote) external payable {
        require(!locked);
        require(msg.value >= wager);
        addyToVote[msg.sender] = vote;
        if (vote == true){
            ++countLove;
        }
        else{
            ++countHate;
        }
    } 

    function voteOutcome(bytes32[] calldata proof, uint index, bool decision) external {
        require(verifyProof(proof, index, msg.sender));
        if (decision == true){
            ++trueAttestation;
        }
        else {
            ++falseAttestation;
        }
    }

    function collectPayout() external {
        bool outcome = deliverOutcome();
        require(addyToVote[msg.sender] == outcome);
        uint payout = calculatePayout();
        (bool sent,) = (msg.sender).call{value: payout}("");
        require (sent);
    }
    function calculatePayout() internal view returns (uint) {
        require(locked);
        bool oc = deliverOutcome();
        if (oc == true) {
            //split by true vote
            return wager * (countHate + countLove) / countLove;
        }
        else {
            //split by false vote
            return wager * (countHate + countLove) / countHate; 
        }
    }
    function deliverOutcome() internal view returns (bool){
        if (trueAttestation > falseAttestation){
            return true;
        } else {
            return false;
        }
    }

    function setState(bytes32 root) external  {
        require (msg.sender == owner);
        state = root; 

    }

    function verifyProof(bytes32[] calldata proof, uint index, address leafAddy) public view returns (bool) {
        bytes32 addyHash = keccak256(abi.encodePacked(leafAddy));
        for (uint i = 0; i < proof.length - 1; ++i){
            bytes32 proofElement = proof[i];
            if (index % 2 == 0) {
                addyHash = keccak256(abi.encodePacked(addyHash, proofElement));
            } else {
                addyHash = keccak256(abi.encodePacked(proofElement, addyHash));
            }

            index = index / 2;
        }
        return addyHash == state;
    } 

}
