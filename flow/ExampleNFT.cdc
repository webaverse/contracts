// This is an example implementation of a Flow Non-Fungible Token
// It is not part of the official standard but it assumed to be
// very similar to how many NFTs would implement the core functionality.

import NonFungibleToken from NONFUNGIBLETOKENADDRESS

pub contract WebaverseNFT: NonFungibleToken {

    pub var totalSupply: UInt64
    pub var hashToIdMap: {String: UInt64}
    pub var idToHashMap: {UInt64: String}
    // pub var idToOwnerMap: {UInt64: Address}
    pub var hashToMetadata : {String: {String: String}}
    pub var hashToTotalSupply: {String: UInt64}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let quantity: UInt64

        // pub var metadata: {String: String}

        init(initID: UInt64, quantity: UInt64) {
            self.id = initID
            self.quantity = quantity
            // self.metadata = {}
        }
    }

    pub resource interface CollectionPublic {
      pub fun getBalance(id: UInt64) : UInt64
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        // access(self) var address : Address

        init () {
            self.ownedNFTs <- {}
            // self.address = 0x0
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let balance : UInt64 = self.getBalance(id: withdrawID)
            let token <- self.ownedNFTs.remove(key: withdrawID)
              ?? panic("missing NFT during withdraw")
            destroy token
            if (balance > UInt64(1)) {
                let oldToken <- self.ownedNFTs[withdrawID] <- create NFT(initID: withdrawID, quantity: balance - UInt64(1))
                destroy oldToken
            }

            // WebaverseNFT.idToOwnerMap.remove(key: withdrawID)

            emit Withdraw(id: withdrawID, from: self.owner?.address)

            return <- create NFT(initID: withdrawID, quantity: UInt64(1))
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @WebaverseNFT.NFT
            let id: UInt64 = token.id
            let quantity: UInt64 = token.quantity
            destroy token

            var oldQuantity = UInt64(0)
            if (self.ownedNFTs[id] != nil) {
                let oldToken <- self.ownedNFTs.remove(key: id)
                  ?? panic("failed to remove owned nft during deposit")
                let oldToken2 <- oldToken as! @WebaverseNFT.NFT
                oldQuantity = oldToken2.quantity
                destroy oldToken2
            }

            let newQuantity = oldQuantity + quantity

            // add the new token to the dictionary which removes the old one
            let oldToken2 <- self.ownedNFTs[id] <- create NFT(initID: id, quantity: newQuantity)
            destroy oldToken2

            // WebaverseNFT.idToOwnerMap[id] = self.address

            emit Deposit(id: id, to: self.owner?.address)
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun setMetadata(id: UInt64, key: String, value: String) {
            let nft = self.borrowNFT(id: id)
            let hash : String = WebaverseNFT.idToHashMap[id]!
            let balance : UInt64 = self.getBalance(id: id)
            let totalSupply : UInt64 = WebaverseNFT.hashToTotalSupply[hash] ?? UInt64(0)
            if (balance >= totalSupply) {
                let metadata : {String: String} = WebaverseNFT.hashToMetadata[hash] ?? {}
                metadata.insert(key: key, value)
                WebaverseNFT.hashToMetadata.insert(key: hash, metadata)
            } else {
                panic("cannot set metadata due to not owning entire supply")
            }
        }

        pub fun reMintNFT(id: UInt64, quantity: UInt64) {
            let nft = self.borrowNFT(id: id)
            let hash : String = WebaverseNFT.idToHashMap[id]!
            let balance : UInt64 = self.getBalance(id: id)
            let totalSupply : UInt64 = WebaverseNFT.hashToTotalSupply[hash] ?? UInt64(0)
            if (balance >= totalSupply) {
                var newNFT <- create NFT(initID: WebaverseNFT.totalSupply, quantity: quantity)
                self.deposit(token: <- newNFT)

                WebaverseNFT.hashToTotalSupply[hash] = (WebaverseNFT.hashToTotalSupply[hash] ?? UInt64(0)) + quantity
            } else {
                panic("cannot remint due to not owning entire supply")
            }
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        /* pub fun getAddress(): Address {
            return self.address
        }
        pub fun setAddress(account: AuthAccount) {
            self.address = account.address
            for id in self.ownedNFTs.keys {
                WebaverseNFT.idToOwnerMap[id] = account.address
            }
        } */

        pub fun getBalance(id: UInt64) : UInt64 {
            if (self.ownedNFTs[id] != nil) {
                let token = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                let token2 = token as! &WebaverseNFT.NFT
                return token2.quantity
            } else {
                return UInt64(0)
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource interface PublicNFTMinter {
        pub fun mintNFT(hash: String, filename: String, quantity: UInt64, recipient: &{NonFungibleToken.CollectionPublic})
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	pub resource NFTMinter : PublicNFTMinter {

		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		pub fun mintNFT(hash: String, filename: String, quantity: UInt64, recipient: &{NonFungibleToken.CollectionPublic}) {
            if (WebaverseNFT.hashToIdMap[hash] == nil) {
    			// create a new NFT
                var newNFT <- create NFT(initID: WebaverseNFT.totalSupply, quantity: quantity)
                let metadata : {String: String} = {}
                metadata.insert(key: "filename", filename)
                WebaverseNFT.hashToMetadata.insert(key: hash, metadata)

    			// deposit it in the recipient's account using their reference
    			recipient.deposit(token: <-newNFT)

                var id : UInt64 = 0
                if (WebaverseNFT.hashToIdMap[hash] != nil) {
                    id = WebaverseNFT.hashToIdMap[hash]!
                } else {
                    id = WebaverseNFT.totalSupply
                    WebaverseNFT.totalSupply = WebaverseNFT.totalSupply + UInt64(1)

                    WebaverseNFT.hashToIdMap[hash] = id
                    WebaverseNFT.idToHashMap[id] = hash
                }
                WebaverseNFT.hashToTotalSupply[hash] = (WebaverseNFT.hashToTotalSupply[hash] ?? UInt64(0)) + quantity
            } else {
                panic("hash already exists")
            }
		}
	}

    // public function that anyone can call to create a new empty collection
    pub fun getHash(id: UInt64): String {
        return WebaverseNFT.idToHashMap[id]!
    }

    pub fun getMetadata(id: UInt64, key: String) : String? {
        let hash : String = WebaverseNFT.idToHashMap[id]!
        let idMetadata = WebaverseNFT.hashToMetadata[hash]
        if (idMetadata != nil) {
            return idMetadata![key]
        } else {
            return nil
        }
    }

	init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.hashToIdMap = {}
        self.idToHashMap = {}
        // self.idToOwnerMap = {}
        self.hashToMetadata = {}
        self.hashToTotalSupply = {}

        let oldCollection <- self.account.load<@AnyResource>(from: /storage/NFTCollection)
        destroy oldCollection
        let oldMinter <- self.account.load<@AnyResource>(from: /storage/NFTMinter)
        destroy oldMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        // collection.setAddress(account: self.account)
        self.account.save(<-collection, to: /storage/NFTCollection)

        // create a public capability for the collection
        self.account.link<&{NonFungibleToken.CollectionPublic}>(
            /public/NFTCollection,
            target: /storage/NFTCollection
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: /storage/NFTMinter)
        self.account.link<&{PublicNFTMinter}>(/public/NFTMinter, target: /storage/NFTMinter)

        emit ContractInitialized()
	}
}