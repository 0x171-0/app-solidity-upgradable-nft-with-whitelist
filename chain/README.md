# Init

```bash
# 安裝 hardhat Installation (Prerequisite: node.js)
npm install --save-dev hardhat
# 開啟第一個測試專案 Quick Start
npx hardhat (> Create a Javascript project)
# 編譯合約
npx hardhat compile
# 部署合約
npx hardhat node (在另一個 terminal 跑一個本地測試節點)
npx hardhat run scripts/deploy.js --network localhost

# (Suggested: VS code + ethereum plug-in)

```
# Networks

```bash
# 設定 Naas 的 API key & 你的錢包 private key
# 可放多個，部署時指定
npx hardhat run scripts/deploy.js --network <network-name>
# ex : 部署到 goerli 上
npx hardhat run scripts/deploy.js --network goerli 
# solidity:指定特定 or 多個版本

# interact with specific networks
npx hardhat run scripts/interact.js --network goerli
```