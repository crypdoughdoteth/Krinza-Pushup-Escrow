import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  
  async function beforeEachFunction() {
    
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, thirdAccount ] = await ethers.getSigners();

    const betAmount = ethers.utils.parseEther("1");
    const hash = '0x5953f6bf40295df057e07ef118f739fc49b2fdb8aa8aa78567858b2ebec71f57';
    const proof = [
      '0x1353b521f4d4677111dc2223972696fb560c95f95ade5c12c1ebccb9c05e411e',
      '0xb5ebcd87af258e16d3af0534ba5194c29eb309c90fcc461d5ae02506f6607f39',
      '0x1a2d749de4218afc05fb7f3c51a190e098e730fa52157d4d25eba94e921557b4'
    ]

    const Escrow = await ethers.getContractFactory("VoteEscrow");
    const escrow = await Escrow.deploy(betAmount);

    return { escrow, owner, otherAccount, thirdAccount, hash, proof };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { escrow, owner } = await loadFixture(beforeEachFunction);
      console.log("owner: " , owner.address);
   
      expect(await escrow.owner()).to.equal(owner.address);
    });
  });

  describe("Deposit Vote", function () {
    it("Let me Bid", async function () {
      const { escrow, otherAccount, owner, thirdAccount } = await loadFixture(
        beforeEachFunction
      );
      
      

      await escrow.connect(otherAccount).depositVote(true, {value: ethers.utils.parseEther("1")});
      
      // console.log("Balance of auctionCreator:", await nftContract.balanceOf(auctionCreator.address))
      expect(await escrow.totalValue()).to.equal(ethers.utils.parseEther("1"));
      expect(await escrow.countLove()).to.equal(1);
      expect(await escrow.countHate()).to.equal(0);
      expect(await escrow.voted(otherAccount.address)).to.equal(true);

      await expect(escrow.connect(otherAccount).depositVote(true, {value: ethers.utils.parseEther("1")})).to.be.rejectedWith();
    });

    it("Let me vote on outcome", async function () {
      const { escrow, otherAccount, owner, thirdAccount, hash, proof } = await loadFixture(
        beforeEachFunction
      );

      await escrow.setState(hash);
      await escrow.depositVote(true, {value: ethers.utils.parseEther("1")});
      await escrow.voteOutcome(proof, 0, true);
      
      // console.log("Balance of auctionCreator:", await nftContract.balanceOf(auctionCreator.address))
      // expect(await escrow.totalValue()).to.equal(ethers.utils.parseEther("1"));
      // expect(await escrow.countLove()).to.equal(1);
      // expect(await escrow.countHate()).to.equal(0);
      // expect(await escrow.voted(otherAccount.address)).to.equal(true);

      // await expect(escrow.connect(otherAccount).depositVote(true, {value: ethers.utils.parseEther("1")})).to.be.rejectedWith();
    });

  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
