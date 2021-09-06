# Introduction
ZMakers NFT exchange smart contracts.

# Usages
## Setup
```
The following procedures are essential and prior to main logics.
```
* Deploy DigitalMediaStore.sol   // Contract managing didital media info
* Deploy DigitalMediaStoreV1     // 1st version of above mentioned contract
* Deploy ApprovedCreatorRegtistry.sol   // Contract that manges the token operators
* Deploy DigitalMediaCore   // main driver contract used to control and run the service
* DigitalMediaCore.unpause 
* DigitalMediaCore.setV1DigitalMediaStoreAddress



# CreateDigitalMedia
|参数|类型|备注|
|:---:|:---:|:---:|
|_totalSupply|uint32|该艺术品总共可对应多少枚币|
|_collectionId|uint256|该艺术品在哪个集合中|
|_metadataPath|string|在ipfs上的存储地址|

无返回，但会把以下信息插入日志：
|参数|类型|备注|
|:---:|:---:|:---:|
|newDigitalMediaId|uint|艺术品的id|
|address(currentDigitalMediaStore)|address|存储艺术品的合约地址|
|_creator|address|创建艺术品者|
|_totalSupply|uint32|艺术品token的totalSupply|
|printIndex|uint32|已经生产了多少枚|
|_collectionId|uint256|艺术品所属的集合（用户在此之前会创建collection，或者用已有的collection）|
|metadataPath|string|存储艺术品的ipfs地址|


# createDigitalMediaReleases
|参数|类型|备注|
|:---:|:---:|:---:|
|_digitalMediaId|uint256|艺术品id|
|_numReleases|uint32|该艺术品铸造多少枚token，不能超过之前规定的totalSupply|

日志：
每个token都会产生：
|参数|类型|备注|
|:---:|:---:|:---:|
|id|uint256|艺术品的id|
|owner|address|艺术品token的owner|
|printEdition|uint32|每个token的序号|
|tokenURI|string|ipfs地址|
|digitalMediaId|uint256|艺术品id|

只有一笔
|参数|类型|备注|
|:---:|:---:|:---:|
|digitalMediaId|uint256|艺术品id|
|printEdition|uint32|已经铸造的token的数量|

