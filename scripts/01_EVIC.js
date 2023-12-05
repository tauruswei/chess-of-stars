require("dotenv").config({ path: MY_ENV_PATH || '.env' });
const hre = require("hardhat");
const fs = require('fs');
const path = require('path');


async function main() {
    // 获取合约工厂
    const BEP20Token = await hre.ethers.getContractFactory("BEP20Token");

    // 部署合约
    const token = await BEP20Token.deploy();

    // 等待部署完成
    await token.waitForDeployment();
    console.log("BEP20Token deployed to:", token.target);
    updateENV('EVIC_ADDRESS', token.target)

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

// 我们建议这样的模式来能够在任何地方使用 async/await 并且正确处理错误。
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
