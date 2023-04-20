import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  async function beforeEachFunction() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, thirdAccount, fourthAccount, fifthAccount] =
      await ethers.getSigners();

    const betAmount = ethers.utils.parseEther("1");
    const validatorCount = 1;
    const nftURI: any = "NFT string"; // fix that
    const root =
      "0x5953f6bf40295df057e07ef118f739fc49b2fdb8aa8aa78567858b2ebec71f57";
    const proof = [
      "0x1353b521f4d4677111dc2223972696fb560c95f95ade5c12c1ebccb9c05e411e",
      "0xb5ebcd87af258e16d3af0534ba5194c29eb309c90fcc461d5ae02506f6607f39",
      "0x1a2d749de4218afc05fb7f3c51a190e098e730fa52157d4d25eba94e921557b4",
    ];

    const Escrow = await ethers.getContractFactory("VoteEscrow");
    const escrow = await Escrow.deploy(betAmount, validatorCount, root, nftURI);

    return {
      escrow,
      owner,
      otherAccount,
      thirdAccount,
      fourthAccount,
      fifthAccount,
      root,
      proof,
    };
  }

  // xdescribe("Deployment", function () {
  //   it("Should set the right owner", async function () {
  //     const { escrow, owner } = await loadFixture(beforeEachFunction);
  //     console.log("owner: " , owner.address);

  //     expect(await escrow.owner()).to.equal(owner.address);
  //   });
  // });

  describe("Deposit Vote", function () {
    it("Let me Bid", async function () {
      const { escrow, otherAccount, owner, thirdAccount } = await loadFixture(
        beforeEachFunction
      );

      await escrow
        .connect(otherAccount)
        .depositVote(true, { value: ethers.utils.parseEther("1") });

      // console.log("Balance of auctionCreator:", await nftContract.balanceOf(auctionCreator.address))
      expect(await escrow.totalValue()).to.equal(ethers.utils.parseEther("1"));
      expect(await escrow.countLove()).to.equal(1);
      expect(await escrow.countHate()).to.equal(0);
      expect(await escrow.voted(otherAccount.address)).to.equal(true);

      //wallet can't vote twice
      await expect(
        escrow
          .connect(otherAccount)
          .depositVote(true, { value: ethers.utils.parseEther("1") })
      ).to.be.rejectedWith();
    });

    it("Let me vote on outcome", async function () {
      const { escrow, otherAccount, owner, thirdAccount, root, proof } =
        await loadFixture(beforeEachFunction);

      // await escrow.setState(root);  // root set in constructor
      await escrow.depositVote(true, { value: ethers.utils.parseEther("1") });
      await escrow.lockBets(proof, 0);
      await escrow.voteOutcome(proof, 0, true);
    });

    it("Collect Payout", async function () {
      const {
        escrow,
        otherAccount,
        owner,
        thirdAccount,
        root,
        proof,
        fourthAccount,
      } = await loadFixture(beforeEachFunction);

      await escrow.depositVote(true, { value: ethers.utils.parseEther("1") });
      await escrow
        .connect(otherAccount)
        .depositVote(false, { value: ethers.utils.parseEther("1") });
      await escrow
        .connect(thirdAccount)
        .depositVote(false, { value: ethers.utils.parseEther("1") });
      // lock before vote
      await escrow.lockBets(proof, 0);
      await escrow.voteOutcome(proof, 0, true);
      await expect(
        escrow.connect(otherAccount).voteOutcome(proof, 0, false)
      ).to.be.revertedWith("failed to verify proof");
      let contractBalance = await escrow.totalValue();
      console.log(
        `Contract balance: ${ethers.utils.formatEther(contractBalance)}`
      );

      expect(await escrow.totalValue()).to.equal(ethers.utils.parseEther("3"));
      let balance = await owner.getBalance();
      console.log(`Wallet balance: ${ethers.utils.formatEther(balance)}`);

      await escrow.endGame(proof, 0);
      //console.log("Passed endGame");
      await escrow.collectPayout();
      balance = await owner.getBalance();
      console.log(`Wallet balance after: ${ethers.utils.formatEther(balance)}`);
      //Try to collect again
      await expect(escrow.collectPayout()).to.be.revertedWith("already paid");
      //Try to collect with wrong vote
      await expect(
        escrow.connect(otherAccount).collectPayout()
      ).to.be.revertedWith("you voted wrong");
      //Try to collect without playing the game
      await expect(
        escrow.connect(fourthAccount).collectPayout()
      ).to.be.revertedWith("you voted wrong"); //Doesn't get to you didn't vote
    });

    it("Lock Vote and End Game Check", async function () {
      const {
        escrow,
        otherAccount,
        owner,
        thirdAccount,
        root,
        proof,
        fourthAccount,
        fifthAccount,
      } = await loadFixture(beforeEachFunction);

      //place bets
      await escrow.depositVote(true, { value: ethers.utils.parseEther("1") });
      await escrow
        .connect(otherAccount)
        .depositVote(true, { value: ethers.utils.parseEther("1") });
      await escrow
        .connect(thirdAccount)
        .depositVote(false, { value: ethers.utils.parseEther("1") });
      await escrow
        .connect(fourthAccount)
        .depositVote(true, { value: ethers.utils.parseEther("1") });
      
      await expect(escrow.collectPayout()).to.be.revertedWith("game not over");

      // lock before vote
      await escrow.lockBets(proof, 0);
      // try to vote after lock 
      await expect(escrow.connect(fifthAccount).depositVote(true, { value: ethers.utils.parseEther("1") })).to.be.revertedWith("bets locked");
      //only allow list can vote
      await escrow.voteOutcome(proof, 0, true);
      // non allow list can't vote
      await expect(
        escrow.connect(otherAccount).voteOutcome(proof, 0, false)
      ).to.be.revertedWith("failed to verify proof");

      // check balances
      let contractBalance = await escrow.totalValue();
      console.log(
        `Contract balance: ${ethers.utils.formatEther(contractBalance)}`
      );
      expect(await escrow.totalValue()).to.equal(ethers.utils.parseEther("4"));

      let balance = await owner.getBalance();
      console.log(`Wallet balance: ${ethers.utils.formatEther(balance)}`);
      await expect(escrow.collectPayout()).to.be.revertedWith("game not over");
       await escrow.endGame(proof, 0);
       await escrow.collectPayout();
       await escrow.connect(otherAccount).collectPayout();
       await escrow.connect(fourthAccount).collectPayout();
       balance = await owner.getBalance();
       console.log(`Wallet balance after: ${ethers.utils.formatEther(balance)}`);
       let otherBalance = await otherAccount.getBalance();
        console.log(`Other Wallet balance after: ${ethers.utils.formatEther(otherBalance)}`);
        let fourthBalance = await fourthAccount.getBalance();
        console.log(`Fourth Wallet balance after: ${ethers.utils.formatEther(fourthBalance)}`);

      //Try to collect again
      await expect(escrow.collectPayout()).to.be.revertedWith("already paid");
      //Try to collect with wrong vote
      await expect(escrow.connect(thirdAccount).collectPayout()).to.be.revertedWith("you voted wrong");
      // //Try to collect without playing the game
       await expect(escrow.connect(fifthAccount).collectPayout()).to.be.revertedWith("you voted wrong"); //Doesn't get to you didn't vote
    });
  });
});
