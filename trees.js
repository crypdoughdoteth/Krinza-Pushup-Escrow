const { MerkleTree } = require('merkletreejs')
const SHA256 = require('keccak256')


const leaves = ['0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38', '0xD0e61aaE436Be77460190a937c1e4b3452F27576', '0xCBD6832Ebc203e49E2B771897067fce3c58575ac'].map(v => SHA256(v))
const tree = new MerkleTree(leaves, SHA256, {sort : false})
const root = tree.getHexRoot()

const leaf = SHA256('0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38')
const proof = tree.getHexProof(leaf)
console.log(tree.toString())
console.log(tree.getHexRoot())
console.log(proof)


//Hardhat wallet
//0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

//Foundry Wallet
// //0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
//  root = 0x8105e4bfc32133bb21f02a967af16a94f24158434c51f2aba115b6856d85ea7c
//  index= 0
//  proof = [
//   '0x1353b521f4d4677111dc2223972696fb560c95f95ade5c12c1ebccb9c05e411e',
//   '0xdd8bcb48f3721a782a5b92e5e52f3e272683acf506ae930613244355c4fd0048'
// ]