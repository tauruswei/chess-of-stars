const fs = require('fs');
const path = require('path');
require("dotenv").config({ path: MY_ENV_PATH });

const {
    ethers,
    upgrades
} = require("hardhat");

const PROXY = process.env.TOKEN_EXCHANGE_ADDRESS_PROXY || "0x";

async function main() {
    const mV2 = await ethers.getContractFactory("TokenExchangeContractV2");
    console.log("Upgrading TokenExchangeContractV2...");
    var m = await upgrades.upgradeProxy(PROXY, mV2);
    await m.waitForDeployment();
    console.log("TokenExchangeContractV2 upgraded successfully", m.target);
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(
        m.target
    )
    console.log("Implementation Address:", implementationAddress);
    updateENV('TOKEN_EXCHANGE_ADDRESS', implementationAddress)
}
function updateENV(key, value) {
    const envPath = MY_ENV_PATH || path.join(__dirname, '.env');

    // 读取 .env 文件内容
    const envConfig = fs.readFileSync(envPath, 'utf-8')
        .split('\n')
        .filter(line => line.trim())
        .reduce((acc, line) => {
            let [key, value] = line.split('=');
            acc[key.trim()] = value.trim();
            return acc;
        }, {});

    envConfig[key] = value;

    let updatedEnvContent = '';
    for (const [key, value] of Object.entries(envConfig)) {
        updatedEnvContent += `${key}=${value}\n`;
    }
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
