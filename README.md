# Sample Hardhat Project

部署 FundPools 合约 和 代理合约
```shell
npx hardhat run scripts/01_FundsMUltiPoolUpgradeERC20.js --network bsctestnet
```
将合约上传到 bsc 浏览器
```shell
# 0x12790044f39198a9615951377256c477e208e384 是代理合约地址
npx hardhat verify --network bsctestnet --contract contracts/01_FundsMUltiPoolUpgradeERC20.sol:FundsMUltiPoolUpgradeERC20 0x12790044f39198a9615951377256c477e208e384
```
升级合约
```shell
npx hardhat run scripts/02_FundsMUltiPoolUpgradeERC20.js --network bsctestnet
```

将新合约上传到 bsc 浏览器
```shell
#  0x12790044f39198a9615951377256c477e208e384 是代理合约地址
npx hardhat verify --network bsctestnet --contract contracts/02_FundsMUltiPoolUpgradeERC20.sol:FundsMUltiPoolUpgradeERC20V2 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

部署代币交换合约
```shell
npx hardhat run scripts/01_TokenExchange.js --network bsctestnet
```
将合约上传到 bsc 浏览器
```shell
# 0x06154cBc3871d6ad96066b0331F13f14eE8BC913 是代理合约地址
npx hardhat verify --network bsctestnet --contract contracts/01_TokenExchange.sol:TokenExchangeContract 0x06154cBc3871d6ad96066b0331F13f14eE8BC913
```

