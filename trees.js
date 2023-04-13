const { MerkleTree } = require('merkletreejs')
const SHA256 = require('keccak256')


const leaves = ['0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', '0xD0e61aaE436Be77460190a937c1e4b3452F27576', '0xCBD6832Ebc203e49E2B771897067fce3c58575ac', '0x636CcE2Dd66320b16219631BA054B5D8c962b848', '0x154421b5abFd5FC12b16715E91d564AA47c8DDee'].map(v => SHA256(v))
const tree = new MerkleTree(leaves, SHA256, {sort : false})
const root = tree.getHexRoot()

const leaf = SHA256('0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266')
const proof = tree.getHexProof(leaf)
console.log(tree.toString())
console.log(tree.getHexRoot())
console.log(proof)

