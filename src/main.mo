import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Canistergeek "mo:canistergeek/canistergeek";
import Cap "mo:cap/Cap";

import Assets "CanisterAssets";
import AssetsTypes "CanisterAssets/types";
import Buffer "./buffer";
import EXT "Ext";
import EXTTypes "Ext/types";
import ExtCore "./toniq-labs/ext/Core";
import Http "Http";
import HttpTypes "Http/types";
import Marketplace "Marketplace";
import MarketplaceTypes "Marketplace/types";
import Sale "Sale";
import SaleTypes "Sale/types";
import Shuffle "Shuffle";
import ShuffleTypes "Shuffle/types";
import TokenTypes "Tokens/types";
import Tokens "Tokens";
import Utils "./utils";

shared ({ caller = init_minter }) actor class Canister(cid : Principal) = myCanister {

  /*********
  * TYPES *
  *********/
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type AccountBalanceArgs = { account : AccountIdentifier };
  type ICPTs = { e8s : Nat64 };
  type SendArgs = {
    memo : Nat64;
    amount : ICPTs;
    fee : ICPTs;
    from_subaccount : ?SubAccount;
    to : AccountIdentifier;
    created_at_time : ?Time.Time;
  };

  /****************
  * STABLE STATE *
  ****************/

  // Tokens
  private stable var _tokenState : TokenTypes.StableState = TokenTypes.newStableState();

  // Sale
  private stable var _saleState : SaleTypes.StableState = SaleTypes.newStableState();

  // Marketplace
  private stable var _marketplaceState : MarketplaceTypes.StableState = MarketplaceTypes.newStableState();

  // Assets
  private stable var _assetsState : AssetsTypes.StableState = AssetsTypes.newStableState();

  // Shuffle
  private stable var _shuffleState : ShuffleTypes.StableState = ShuffleTypes.newStableState();

  // Cap
  private stable var rootBucketId : ?Text = null;

  // Canistergeek
  stable var _canistergeekMonitorUD : ?Canistergeek.UpgradeData = null;

  //State functions
  system func preupgrade() {
    // Tokens
    _tokenState := _Tokens.toStable();

    // Sale
    _saleState := _Sale.toStable();

    // Marketplace
    _marketplaceState := _Marketplace.toStable();

    // Assets
    _assetsState := _Assets.toStable();

    // Shuffle
    _shuffleState := _Shuffle.toStable();

    // Canistergeek
    _canistergeekMonitorUD := ?canistergeekMonitor.preupgrade();
  };

  system func postupgrade() {
    // Tokens
    _tokenState := TokenTypes.newStableState();

    // Sale
    _saleState := SaleTypes.newStableState();

    // Marketplace
    _marketplaceState := MarketplaceTypes.newStableState();

    // Assets
    _assetsState := AssetsTypes.newStableState();

    // Shuffle
    _shuffleState := ShuffleTypes.newStableState();

    // Canistergeek
    canistergeekMonitor.postupgrade(_canistergeekMonitorUD);
    _canistergeekMonitorUD := null;
  };

  /*************
  * CONSTANTS *
  *************/

  let LEDGER_CANISTER = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : actor {
    account_balance_dfx : shared query AccountBalanceArgs -> async ICPTs;
    send_dfx : shared SendArgs -> async Nat64;
  };
  let CREATION_CYCLES : Nat = 1_000_000_000_000;

  /***********
  * CLASSES *
  ***********/

  // Canistergeek
  private let canistergeekMonitor = Canistergeek.Monitor();

  /**
  * Returns collected data based on passed parameters.
  * Called from browser.
  */
  public query ({ caller }) func getCanisterMetrics(parameters : Canistergeek.GetMetricsParameters) : async ?Canistergeek.CanisterMetrics {
    validateCaller(caller);
    canistergeekMonitor.getMetrics(parameters);
  };

  /**
  * Force collecting the data at current time.
  * Called from browser or any canister "update" method.
  */
  public shared ({ caller }) func collectCanisterMetrics() : async () {
    validateCaller(caller);
    canistergeekMonitor.collectMetrics();
  };

  private func validateCaller(principal : Principal) : () {
    assert (principal == Principal.fromText("ikywv-z7xvl-xavcg-ve6kg-dbbtx-wy3gy-qbtwp-7ylai-yl4lc-lwetg-kqe"));
  };

  // Cap
  let _Cap = Cap.Cap(null, rootBucketId);

  public shared (msg) func initCap() : async Result.Result<(), Text> {
    canistergeekMonitor.collectMetrics();
    assert (msg.caller == init_minter);
    let pid = Principal.fromActor(myCanister);
    let tokenContractId = Principal.toText(pid);

    try {
      rootBucketId := await _Cap.handshake(
        tokenContractId,
        CREATION_CYCLES,
      );

      return #ok();
    } catch e {
      throw e;
    };
  };

  // Tokens
  let _Tokens = Tokens.Factory(
    cid,
    _tokenState,
    {
      minter = init_minter;
    },
  );

  // queries
  public query func balance(request : TokenTypes.BalanceRequest) : async TokenTypes.BalanceResponse {
    _Tokens.balance(request);
  };

  public query func bearer(token : TokenTypes.TokenIdentifier) : async Result.Result<TokenTypes.AccountIdentifier, TokenTypes.CommonError> {
    _Tokens.bearer(token);
  };

  // Marketplace
  let _Marketplace = Marketplace.Factory(
    cid,
    _marketplaceState,
    {
      _Tokens;
      _Cap;
    },
    {
      LEDGER_CANISTER;
    },
  );

  // updates
  public shared (msg) func lock(tokenid : MarketplaceTypes.TokenIdentifier, price : Nat64, address : MarketplaceTypes.AccountIdentifier, subaccount : MarketplaceTypes.SubAccount) : async Result.Result<MarketplaceTypes.AccountIdentifier, MarketplaceTypes.CommonError> {
    canistergeekMonitor.collectMetrics();
    await _Marketplace.lock(msg.caller, tokenid, price, address, subaccount);
  };

  public shared (msg) func settle(tokenid : MarketplaceTypes.TokenIdentifier) : async Result.Result<(), MarketplaceTypes.CommonError> {
    canistergeekMonitor.collectMetrics();
    await _Marketplace.settle(msg.caller, tokenid);
  };

  public shared (msg) func list(request : MarketplaceTypes.ListRequest) : async Result.Result<(), MarketplaceTypes.CommonError> {
    canistergeekMonitor.collectMetrics();
    await _Marketplace.list(msg.caller, request);
  };

  public shared (msg) func cronDisbursements() : async () {
    canistergeekMonitor.collectMetrics();
    await _Marketplace.cronDisbursements();
  };

  public shared (msg) func cronSettlements() : async () {
    canistergeekMonitor.collectMetrics();
    await _Marketplace.cronSettlements(msg.caller);
  };

  // queries
  public query func details(token : MarketplaceTypes.TokenIdentifier) : async Result.Result<(MarketplaceTypes.AccountIdentifier, ?MarketplaceTypes.Listing), MarketplaceTypes.CommonError> {
    _Marketplace.details(token);
  };

  public query func transactions() : async [MarketplaceTypes.Transaction] {
    _Marketplace.transactions();
  };

  public query func settlements() : async [(MarketplaceTypes.TokenIndex, MarketplaceTypes.AccountIdentifier, Nat64)] {
    _Marketplace.settlements();
  };

  public query func listings() : async [(MarketplaceTypes.TokenIndex, MarketplaceTypes.Listing, MarketplaceTypes.Metadata)] {
    _Marketplace.listings();
  };

  public query (msg) func allSettlements() : async [(MarketplaceTypes.TokenIndex, MarketplaceTypes.Settlement)] {
    _Marketplace.allSettlements();
  };

  public query func stats() : async (Nat64, Nat64, Nat64, Nat64, Nat, Nat, Nat) {
    _Marketplace.stats();
  };

  public query func viewDisbursements() : async [(MarketplaceTypes.TokenIndex, MarketplaceTypes.AccountIdentifier, MarketplaceTypes.SubAccount, Nat64)] {
    _Marketplace.viewDisbursements();
  };

  public query func pendingCronJobs() : async [Nat] {
    _Marketplace.pendingCronJobs();
  };

  public query func toAddress(p : Text, sa : Nat) : async AccountIdentifier {
    _Marketplace.toAddress(p, sa);
  };

  // Assets
  let _Assets = Assets.Factory(
    _assetsState,
    {
      _Tokens;
    },
    {
      minter = init_minter;
    },
  );

  public shared (msg) func streamAsset(id : Nat, isThumb : Bool, payload : Blob) : async () {
    canistergeekMonitor.collectMetrics();
    _Assets.streamAsset(msg.caller, id, isThumb, payload);
  };

  public shared (msg) func updateThumb(name : Text, file : AssetsTypes.File) : async ?Nat {
    canistergeekMonitor.collectMetrics();
    _Assets.updateThumb(msg.caller, name, file);
  };

  public shared (msg) func addAsset(asset : AssetsTypes.Asset) : async Nat {
    canistergeekMonitor.collectMetrics();
    _Assets.addAsset(msg.caller, asset);
  };

  // Shuffle
  let _Shuffle = Shuffle.Factory(
    _shuffleState,
    {
      _Assets;
      _Tokens;
    },
    {
      minter = init_minter;
    },
  );

  public shared (msg) func shuffleAssets() : async () {
    canistergeekMonitor.collectMetrics();
    await _Shuffle.shuffleAssets(msg.caller);
  };

  //Sale
  let _Sale = Sale.Factory(
    cid,
    _saleState,
    {
      _Cap;
      _Marketplace;
      _Shuffle;
      _Tokens;
    },
    {
      LEDGER_CANISTER;
      minter = init_minter;
    },
  );

  // updates
  public shared (msg) func initMint(addresses : [Text]) : async () {
    canistergeekMonitor.collectMetrics();
    await _Sale.initMint(msg.caller, addresses);
  };

  public shared (msg) func shuffleTokensForSale() : async () {
    canistergeekMonitor.collectMetrics();
    await _Sale.shuffleTokensForSale(msg.caller);
  };

  public shared (msg) func airdropTokens(startIndex : Nat) : async () {
    canistergeekMonitor.collectMetrics();
    _Sale.airdropTokens(msg.caller, startIndex);
  };

  public shared (msg) func setTotalToSell() : async Nat {
    canistergeekMonitor.collectMetrics();
    _Sale.setTotalToSell(msg.caller);
  };

  public shared (msg) func reserve(amount : Nat64, quantity : Nat64, address : SaleTypes.AccountIdentifier, _subaccountNOTUSED : SaleTypes.SubAccount) : async Result.Result<(SaleTypes.AccountIdentifier, Nat64), Text> {
    canistergeekMonitor.collectMetrics();
    _Sale.reserve(amount, quantity, address, _subaccountNOTUSED);
  };

  public shared (msg) func retreive(paymentaddress : SaleTypes.AccountIdentifier) : async Result.Result<(), Text> {
    canistergeekMonitor.collectMetrics();
    await _Sale.retreive(msg.caller, paymentaddress);
  };

  public shared (msg) func cronSalesSettlements() : async () {
    canistergeekMonitor.collectMetrics();
    await _Sale.cronSalesSettlements(msg.caller);
  };

  public shared (msg) func cronFailedSales() : async () {
    canistergeekMonitor.collectMetrics();
    await _Sale.cronFailedSales(msg.caller);
  };

  // queries
  public query func salesSettlements() : async [(SaleTypes.AccountIdentifier, SaleTypes.Sale)] {
    _Sale.salesSettlements();
  };

  public query func failedSales() : async [(SaleTypes.AccountIdentifier, SaleTypes.SubAccount)] {
    _Sale.failedSales();
  };

  public query (msg) func saleTransactions() : async [SaleTypes.SaleTransaction] {
    _Sale.saleTransactions();
  };

  public query (msg) func salesSettings(address : AccountIdentifier) : async SaleTypes.SaleSettings {
    _Sale.salesSettings(address);
  };

  // EXT
  let _EXT = EXT.Factory(
    cid,
    {
      _Tokens;
      _Assets;
      _Marketplace;
      _Cap;
    },
    {
      minter = init_minter;
    },
  );
  // updates
  public shared (msg) func transfer(request : EXTTypes.TransferRequest) : async EXTTypes.TransferResponse {
    canistergeekMonitor.collectMetrics();
    await _EXT.transfer(msg.caller, request);
  };

  // queries
  public query func getMinter() : async Principal {
    _EXT.getMinter();
  };

  public query func extensions() : async [EXTTypes.Extension] {
    _EXT.extensions();
  };

  public query func supply() : async Result.Result<EXTTypes.Balance, EXTTypes.CommonError> {
    _EXT.supply();
  };

  public query func getRegistry() : async [(EXTTypes.TokenIndex, EXTTypes.AccountIdentifier)] {
    _EXT.getRegistry();
  };

  public query func getTokens() : async [(EXTTypes.TokenIndex, EXTTypes.Metadata)] {
    _EXT.getTokens();
  };

  public query func getTokenToAssetMapping() : async [(EXTTypes.TokenIndex, Text)] {
    _EXT.getTokenToAssetMapping();
  };

  public query func tokens(aid : EXTTypes.AccountIdentifier) : async Result.Result<[EXTTypes.TokenIndex], EXTTypes.CommonError> {
    _EXT.tokens(aid);
  };

  public query func tokens_ext(aid : EXTTypes.AccountIdentifier) : async Result.Result<[(EXTTypes.TokenIndex, ?MarketplaceTypes.Listing, ?Blob)], EXTTypes.CommonError> {
    _EXT.tokens_ext(aid);
  };

  public query func metadata(token : EXTTypes.TokenIdentifier) : async Result.Result<EXTTypes.Metadata, EXTTypes.CommonError> {
    _EXT.metadata(token);
  };

  // Http
  let _HttpHandler = Http.HttpHandler(
    cid,
    {
      _Assets;
      _Marketplace;
      _Shuffle;
      _Tokens;
      _Sale;
    },
    {
      minter = init_minter;
    },
  );

  // queries
  public query func http_request(request : HttpTypes.HttpRequest) : async HttpTypes.HttpResponse {
    _HttpHandler.http_request(request);
  };

  public query func http_request_streaming_callback(token : HttpTypes.HttpStreamingCallbackToken) : async HttpTypes.HttpStreamingCallbackResponse {
    _HttpHandler.http_request_streaming_callback(token);
  };

  // cycles
  public func acceptCycles() : async () {
    canistergeekMonitor.collectMetrics();
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };

  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };

};
