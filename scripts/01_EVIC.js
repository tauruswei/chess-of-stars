require("dotenv").config();
const hre = require("hardhat");
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv'); // 导入 dotenv

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

// 我们建议这样的模式来能够在任何地方使用 async/await 并且正确处理错误。
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
