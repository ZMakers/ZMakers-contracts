import {nftAbi, nftAdd} from './contractInfo'

var Web3 = require('web3')
var web3 = new Web3("https://ropsten.infura.io/v3/a2816bc61057481188c0a772cee3134e") //节点
var testPriKey = "0x6c7117111a42dd5dfcff752ee0b32c3f85699192d6c18297fc23d473bf8089c9" // 测试私钥
var testAddress = "0x78C531c538A5013121E81BBA80cB9D3Bcee46962" // 测试地址，由私钥导出

function importWallet() {
    web3.eth.accounts.wallet.add({
        privateKey: testPriKey,
        address: testAddress
    })
}

importWallet()

var nftContract = new web3.eth.Contract(nftAbi, nftAdd)

async function getBalance(_address: string) {
    try {
        let res = await web3.eth.getBalance(_address)
        return web3.utils.fromWei(res, 'ether');
    } catch (error) {
        return error
    }
}


async function createCollection() {

    let _metadataPath = "https://ipfs.example.com"
    let res = await nftContract.methods.createCollection(_metadataPath).send({
        from: testAddress,
        gas: 1234567,
        gasPrice: '3000000000',
        value: 0
    })
    console.log(res)
    console.log(res.transactionHash)
}

async function createMedia() {
    let _totalSupply = 10
    let _collectionId = 1
    let _metadataPath = "https://ipfs.example.com"
    let res = await nftContract.methods.createDigitalMedia(_totalSupply, _collectionId, _metadataPath).send({
        from: testAddress,
        gas: 1234567,
        gasPrice: '3000000000',
        value: 0
    })
    console.log(res)
    console.log(res.transactionHash)
}

async function createDigitalMediaReleases() {
    let _digitalMediaId = 1;
    let _numReleases = 3;
    let res = await nftContract.methods.createDigitalMediaReleases(_digitalMediaId, _numReleases).send({
        from: testAddress,
        gas: 1234567,
        gasPrice: '3000000000',
        value: 0
    })
    console.log(res)
    console.log(res.transactionHash)
}


async function createDigitalMediaAndReleasesInNewCollection() {
    let _totalSupply = 10
    let _digitalMediaMetadataPath = "https://ipfs.example.cn"
    let _collectionMetadataPath = "https://ipfs.example.com"
    let _numReleases = 5
    let res = await nftContract.methods.createDigitalMediaAndReleasesInNewCollection(_totalSupply, _digitalMediaMetadataPath, _collectionMetadataPath, _numReleases).send({
        from: testAddress,
        gas: 1234567,
        gasPrice: '3000000000',
        value: 0
    })
    console.log(res)
    console.log(res.transactionHash)
}

// getBalance(testAddress)
// createCollection()
// createMedia()
// createDigitalMediaReleases()
createDigitalMediaAndReleasesInNewCollection()
