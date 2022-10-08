// interact.js

const API_KEY = process.env.API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
// https://www.npmjs.com/package/merkletreejs
const { MerkleTree } = require("merkletreejs");
// https://www.npmjs.com/package/keccak256
const keccak256 = require("keccak256");

const contract = require("../artifacts/contracts/AppWorksErc721.sol/AppWorks.json");
// console.log(JSON.stringify(contract.abi));

// interact.js

// Provider
const alchemyProvider = new ethers.providers.AlchemyProvider(
  (network = "goerli"),
  API_KEY
);

// Signer
const signer = new ethers.Wallet(
  PRIVATE_KEY,
  alchemyProvider || new ethers.providers.Web3Provider(network.provider)
);

// Contract
const helloWorldContract = new ethers.Contract(
  CONTRACT_ADDRESS,
  contract.abi,
  signer
);

async function main() {
  const whiteListAddressed = ["a", "b", "c"];
  const leaves = whiteListAddressed.map((x) => keccak256(x));

  // [ ] 👁 OpenZeplin 貌似規定 sortPairs 要是 True 待查證
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  // 印出樹狀結構的 Merkle Tree
  console.log("Merkle Tree Structure ==>\n", tree.toString());

  const root = tree.getRoot().toString("hex");

  const merkleRoot = await helloWorldContract.setMerkleRoot(root);
  console.log("The message is: " + merkleRoot);

  console.log("Updating the message...");

  // const tx = await helloWorldContract.update("This is the new message.");
  // await tx.wait();

  /* 
  we make a call to .wait() on the returned transaction object. 
  This ensures that our script waits for the transaction to get mined on the blockchain before exiting the function. If the .wait() call isn't included, the script may not see the updated message value in the contract.
   */
}

main();

// function buildMerkleTree() {
//   const whiteListAddressed = ["a", "b", "c"];
//   const leaves = whiteListAddressed.map((x) => keccak256(x));

//   // [ ] 👁 OpenZeplin 貌似規定 sortPairs 要是 True 待查證
//   const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

//   // 印出樹狀結構的 Merkle Tree
//   console.log("Merkle Tree Structure ==>\n", tree.toString());

//   const root = tree.getRoot().toString("hex");

//   const leaf = keccak256("a");
//   const proof = tree.getProof(leaf);

//   // const hexProof = MerkleTree.getHexProof(leaf)
//   console.log("hexProof-->", proof);

//   console.log(tree.verify(proof, leaf, root)); // true

//   // 含有假資料的葉資訊
//   const badLeaves = ["a", "x", "c"].map((x) => keccak256(x));
//   // 含有鉀資料的 Tree
//   const badTree = new MerkleTree(badLeaves, keccak256);

//   // 假資料葉節點
//   const badLeaf = keccak256("x");
//   // 使用假資料的葉節點產生的 Proof
//   const badProof = tree.getProof(badLeaf);

//   // 💥 使用錯的 Proof、正確的葉節點、正確的 root 驗證會錯
//   console.log(tree.verify(badProof, leaf, root)); // false

//   // mystery box image:
//   // https://www.etsy.com/listing/952392416/adult-mystery-box
// }
