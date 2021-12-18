import { NFTStorage, File } from 'nft.storage'

const apiKey = 'zjjTest'
const client = new NFTStorage({ token: apiKey })

async function store(){
    const metadata = await client.store({
        name: 'Pinpie',
        description: 'Pin is not delicious beef!',
        image: new File([/* data */], 'pinpie.jpg', { type: 'image/jpg' })
    })
    console.log(metadata.url)
// ipfs://bafyreib4pff766vhpbxbhjbqqnsh5emeznvujayjj4z2iu533cprgbz23m/metadata.json

}

store()