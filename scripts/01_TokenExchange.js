require("dotenv").config();

const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv'); // 导入 dotenv

const {
    ethers,
    upgrades
} = require("hardhat");


async function main() {
    const TokenExchangeContract = await ethers.getContractFactory("TokenExchangeContract");

    console.log("Deploying TokenExchangeContract...");
    const [owner] = await ethers.getSigners();
    const tokenAddress = process.env.EVIC_ADDRESS || "0x";
    const busdAddress = process.env.BUSD_ADDRESS || "0x";
    const exchangeRate = 100;


    const m = await upgrades.deployProxy(TokenExchangeContract,[owner.address, busdAddress,tokenAddress,exchangeRate],  {
        initializer: "initialize", // 设置一个不同的初始化函数来调用
        kind: "uups",
    });
    await m.waitForDeployment();

    console.log("TokenExchangeContract deployed to:", m.target);
    updateENV('TOKEN_EXCHANGE_ADDRESS_PROXY', m.target)
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(
        m.target
    )
    console.log("Implementation Address:", implementationAddress);
    updateENV('TOKEN_EXCHANGE_ADDRESS', implementationAddress)
}


function updateENV(key, value) {
    // const envPath = path.join(__dirname, '.env');
    const envPath = path.join(path.dirname(__dirname), '.env');

    // 读取 .env 文件
    const envConfig = dotenv.parse(fs.readFileSync(envPath));

    // 更新或添加 FUND_POOLS_ADDRESS
    envConfig[key] = value;

    // 将更新后的配置写回 .env 文件
    let updatedEnvContent = '';
    Object.keys(envConfig).forEach(key => {
        updatedEnvContent += `${key}=${envConfig[key]}\n`;
    });
    fs.writeFileSync(envPath, updatedEnvContent);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
