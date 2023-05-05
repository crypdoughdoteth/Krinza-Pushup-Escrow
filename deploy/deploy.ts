import { Wallet, utils } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script for the VoteEscrow contract`);

  // Initialize the wallet.
  const wallet = new Wallet(`${process.env.PRIVATE_KEY}`);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("VoteEscrow");

  // Estimate contract deployment fee
  const betAmount = 26e14;
  const validators =  2;
  const root = "0x11a1b6d19cd4d311fbab39f8ee9369f64ae3dfc22312f197f5d6274695490857";
  const URI = "String";
  const deploymentFee = await deployer.estimateDeployFee(artifact, [betAmount, validators, root, URI]);

  // OPTIONAL: Deposit funds to L2
  // Comment this block if you already have funds on zkSync.
//   const depositHandle = await deployer.zkWallet.deposit({
//     to: deployer.zkWallet.address,
//     token: utils.ETH_ADDRESS,
//     amount: deploymentFee.mul(2),
//   });
//   // Wait until the deposit is processed on zkSync
//   await depositHandle.wait();

  // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
  // `betAmount` is an argument for contract constructor.
  const parsedFee = ethers.utils.formatEther(deploymentFee.toString());
  console.log(`The deployment is estimated to cost ${parsedFee} ETH`);

  const escrowContract = await deployer.deploy(artifact, [betAmount, validators, root, URI]);

  //obtain the Constructor Arguments
  console.log("constructor args:" + escrowContract.interface.encodeDeploy([betAmount, validators, root, URI]));

  // Show the contract info.
  const contractAddress = escrowContract.address;
  console.log(`${artifact.contractName} was deployed to ${contractAddress}`);
}
