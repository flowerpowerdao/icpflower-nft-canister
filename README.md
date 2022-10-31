![photo_2022-08-04 23 41 19](https://user-images.githubusercontent.com/32162112/182957869-8479f309-283d-4d81-af9f-2d34acbac27e.jpeg)

# pineapple punks nft 🌼

> :warning: **If you use this for another NFT project**: MAKE SURE YOU DELETE THE `canister_ids.json` FIRST!

# TO-DOs

## pre launch

-   ~~check all addresses and parameters in `deploy.zsh`~~
-   ~~adapt `Env/lib.mo` to your needs~~
-   ~~send royalties to respective addresses instead of accumulating them~~
-   ~~add common holder snapshot and fpdao member snapshot to env~~
-   ~~add canister to DAB~~
-   ~~send collection details to entrepot via form~~
-   ~~top canister up with cycles~~
-   ~~add canister to tip jar~~
-   run off chain backup script with mainnet canister id
-   run disburse script with mainnet canister id

## launch

-   run `make deploy-production-ic-full`
-   check if all assets uploaded correctly by calling the canisters `getTokenToAssetMapping()` method (give this some time until all the messages sent from uploading the assets have been executed)
-   call `shuffleAssets` at desired time (usually 24 hours after market opens)

## structure

-   the `main` branch contains the logic that is currently deployed on mainnet

## quick deploy 🏃‍♀️

-   To quickly reinstall (**WIPES ALL STATE**) the NFT staging canister locally run `dfx deploy staging --mode reinstall`

## sophisticated deploy 📚

-   use `make` to run the standard local deploy, use `make deploy-staging-ic` to deploy the staging canister to the mainnet, by default it deploys the NFT staging canister locally and uses `assets/output.mp4` and `metadata.json` as file paths
-   the weird looking `sed` when uploading the metadata is escaping `"` characters and the variable `$j` is needed for the correct index (`j=$i-1`)

## caveats 🕳

-   The canister code is written in a way that the seed animation _ALWAYS_ has to be the first asset uploaded to the canister.
-   The seed animation video needs to be encoded in a way that it can be played on iOS devices, use `HandBrake` for that or `ffmpeg`
-   `metadata.json` **MUST NOT** contain a mint number! (use `cat mymetadata.json| sed '/mint/ d' > metadata.json` to remove the mint number)
-   note that you need [ext](#ext) installed
-   The `deploy.zsh` adds another oracle to the NFT canister because the script in the source SVG won't be executed the way it's currently structured. Make sure you use the correct API endpoint there as well!
    -   note: this script is not allowed to contain any `&` or `>` characters! [this](https://www.freeformatter.com/xml-escape.html) can help escaping
    -   make sure you change the asset canister url and the currency fetched from the oracle
-   make sure you create and `assets` folder and provide the `output.mp4` file and the `metadata.json` file and specify their names in the script accordingly

## vessel 🚢

-   Run `vessel verify --version 0.6.28` to verify everything still builds correctly after adding a new depdenceny
-   To use `vessels`s moc version when deploying, use `DFX_MOC_PATH="$(vessel bin)/moc" dfx deploy`

## shuffle 🔀

-   The shuffle uses the random beacon to derive a random seed for the PRNG
-   It basically shuffles all the assets in the `assets` stable variable
-   The link inside the canister is

```
tokenIndex -> assetIndex
assetIndex -> NFT
```

-   initially the `tokenIndex` matches the `assetIndex` (`assetIndex` = `tokenIndex+1`)
-   after the shuffle the `assetIndex` and the `NFT` mint number pairs will be different
-   so the token at `tokenIndex` still points to the same asset at `assetIndex`, but this asset no longer has the same `NFT` mint number
-   we can always retrieve the `NFT` mint number from the `_asset[index].name` property which we specify when adding an asset to the canister

## off-chain backup ⛓

We use the `getRegistry` (`tokenIndex -> AccountIdentifier`) and `getTokenToAssetMapping` (`tokenIndex -> NFT`) canister methods to backup state offchain. Therefore we simply use a script that queries the afore mentioned methods every 60 minutes and saves the responses on a server. You can find the script in `state_backup`. We are also submitting every transaction to `CAP`, which again offers off-chain backups of their data.

Note that the indices of the json outputs represent the indices of the internal storage. E.g. index `0` means it is the first item in the array. In the UI (entrepot or stoic wallet) those indices are incremented by one, so they start with `1` and not with `0`.

To have the same token identifiers for the same tokens, it is important to keep the order of the minting when reinstantiating the canister.

So when executing `mintNFT`, the `to` address is taken from `registry.json` and the `asset` is taken from `tokens.json`. It's important here that the uploading of the assets is on order (start with flower 1, end with flower 2009) and that the `assets` index 0 is used by something other than an NFT asset (before it was the seed animation)! It's also crucial to remove `shuffleAssets` functionality from the canister!

**NOTE**

you can also use `http://127.0.0.1:8000/?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai&asset=0` or `http://127.0.0.1:8000/1.svg?canisterId=rrkah-fqaaa-aaaaa-aaaaq-cai&asset=0` locally

<h2 id="ext">ext-cli 🔌</h2>

to get the tokenid from the canister and index do the following

1. clone https://github.com/Toniq-Labs/ext-cli and https://github.com/Toniq-Labs/ext-js in the same directory
2. run `npm i -g` from within `ext-cli`
3. run `ext token <canister_id> <index>`

## settlements

-   if there's a settlement that didn't work, we can call the `settlements` query method and then `settle` using the index to settle the transaction

-   if there a salesSettelemnts that didnt work, we call the `salesSettlements` query method and then `retrieve` using the address to settle the transaction
