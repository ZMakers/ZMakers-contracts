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
