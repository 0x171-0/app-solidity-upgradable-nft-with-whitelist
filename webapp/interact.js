const whiteListAddressed = ["0x1f06fea9CFb3dDB16756FB2880e63ADDE1aF827d"];
import contract from "./AppWorks.js";
const contractAddress = "0x9A2C6CFcBd5295169dc527C38A77728f6E6C39ba";

let account;
let tree;
let merkleRoot;
let contractInstance;
let merkleUtil;
let balance;

window.addEventListener("load", function () {
  connectMetaMask();
  initEvent();
  setInterval((e) => {
    if (!window.ethereum) {
      getCurrentWalletConnected();
    }
  }, 3000);
});

class SchoolContract {
  constructor() {
    this.contract = new web3.eth.Contract(contract.abi, contractAddress);
    this.getBalance();
    this.getMerkleRoot();
  }
  async getMerkleRoot() {
    merkleRoot = await this.contract.methods.merkleRoot().call();
    if (
      merkleRoot !==
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    ) {
      document.getElementById("merkle-root").innerHTML = merkleRoot;
    }
  }
  async getBalance() {
    balance = await this.contract.methods.balance(account).call();
    document.getElementById("balance").innerHTML = balance;
  }

  async setMerkleRoot() {
    if (
      merkleRoot !==
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    ) {
      console.log("merkleRoot ==>", merkleRoot);
      await this.contract.methods
        .setMerkleRoot("0x" + merkleRoot)
        .send({ from: account });
    }
  }

  async earlyMint() {
    if (!window.ethereum || account === null) {
      alert(
        "💡 Connect your MetaMask wallet to update the message on the blockchain."
      );
    }
    const { leaf, proof } = merkleUtil.getMerkleProof(account);
    console.log("proof==>\n", proof);

    document.getElementById("merkle-proof").innerText = proof;
    getBalance();

    // const transactionParameters = {
    //   to: contractAddress,
    //   from: account,
    //   data: this.contract.methods.earlyMint(proof, 1).encodeABI(),
    //   value: web3.utils.toWei("0.01", "ether"),
    // };
    try {
      // const txHash = await window.ethereum.request({
      //   method: "eth_sendTransaction",
      //   params: [transactionParameters],
      // });
      const txHash = await this.contract.methods.earlyMint(proof, 1).send({
        from: account,
        value: web3.utils.toWei("0.01", "ether"),
      });
      alert("⭐️ Mint txHash" + txHash);
    } catch (error) {
      alert("😥 " + error.message);
    }
  }
}

class MerkleUtil {
  constructor() {
    this.getNewMerkleRoot(account);
  }
  verifyProof(address) {
    const { leaf, proof } = this.getMerkleProof(address);
    return tree.verify(proof, leaf, merkleRoot);
  }

  getMerkleProof(address) {
    const leaf = keccak256(address);
    const proof = this.tree.getHexProof(leaf);
    return { leaf, proof };
  }

  getNewMerkleRoot(address) {
    const leaves = [...whiteListAddressed, address].map((x) => keccak256(x));
    console.log("leaves ===>\n", leaves);
    this.tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    // 印出樹狀結構的 Merkle Tree
    console.log("Merkle Tree Structure ==>\n", this.tree.toString());
    merkleRoot = this.tree.getRoot().toString("hex");
    document.getElementById("merkle-root").innerHTML = merkleRoot;
    return merkleRoot;
  }
}

function initEvent() {
  document.getElementById("btn1").addEventListener("click", () => {
    connectMetaMask();
  });
  document.getElementById("btn2").addEventListener("click", async () => {
    await contractInstance.getMerkleRoot();
  });
  document.getElementById("btn3").addEventListener("click", async () => {
    await contractInstance.earlyMint();
  });
  document.getElementById("btn4").addEventListener("click", async () => {
    await contractInstance.setMerkleRoot();
  });
  document.getElementById("btn5").addEventListener("click", async () => {
    await contractInstance.getBalance();
  });
}

function connectMetaMask() {
  if (window.ethereum) {
    window.web3 = new Web3(ethereum);
    ethereum
      .enable()
      .then(async () => {
        console.log("✅ Ethereum enabled...");
        setAccount();
      })
      .catch((err) => {
        console.warn("🔥 User didn't allow access to accounts.", err);
      });
  } else {
    console.log(
      "🔥 Non-Ethereum browser detected. You should consider installing MetaMask 🦊."
    );
  }
}

export async function getCurrentWalletConnected() {
  if (window.ethereum) {
    setAccount();
  } else {
    connectMetaMask();
  }
}

export function setAccount() {
  web3.eth.getAccounts(function (err, acc) {
    if (err != null) {
      self.setStatus("🔥 There was an error fetching your accounts");
      return;
    }
    if (acc.length > 0) {
      console.log("✅ account list...", acc);
      account = acc[0];
      whiteListAddressed.push(account);
      contractInstance = new SchoolContract(contractAddress);
      merkleUtil = new MerkleUtil();
    }
  });
}

// mystery box image:
// https://www.etsy.com/listing/952392416/adult-mystery-box
