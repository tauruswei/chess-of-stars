require("dotenv").config();
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv'); // 导入 dotenv
const {
    ethers,
    upgrades
} = require("hardhat");


const PROXY = process.env.FUND_POOLS_ADDRESS_PROXY || "0x";;//代理合约的地址

async function main() {
    const mV2 = await ethers.getContractFactory("FundsMUltiPoolUpgradeERC20V2");
    console.log("Upgrading FundsMUltiPoolUpgradeERC20V2...");
    var m = await upgrades.upgradeProxy(PROXY, mV2);
    await m.waitForDeployment();
    console.log("FundsMUltiPoolUpgradeERC20V2 upgraded successfully", m.target);
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(
        m.target
    )
    console.log("Implementation Address:", implementationAddress);
    updateENV('FUND_POOLS_ADDRESS', implementationAddress)
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
