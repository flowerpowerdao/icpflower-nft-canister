import Time "mo:base/Time";

import Cap "mo:cap/Cap";

import Assets "../CanisterAssets";
import ExtCore "../toniq-labs/ext/Core";
import Marketplace "../Marketplace";
import Shuffle "../Shuffle";
import Tokens "../Tokens";

module {

  public func newStableState() : StableState {
    return {
      _saleTransactionsState : [SaleTransaction] = [];
      _salesSettlementsState : [(AccountIdentifier, Sale)] = [];
      _failedSalesState : [(AccountIdentifier, SubAccount)] = [];
      _tokensForSaleState : [TokenIndex] = [];
      _soldIcpState : Nat64 = 0;
    };
  };

  public type StableState = {
    _saleTransactionsState : [SaleTransaction];
    _salesSettlementsState : [(AccountIdentifier, Sale)];
    _failedSalesState : [(AccountIdentifier, SubAccount)];
    _tokensForSaleState : [TokenIndex];
    _soldIcpState : Nat64;
  };

  public type Dependencies = {
    _Cap : Cap.Cap;
    _Tokens : Tokens.Factory;
    _Marketplace : Marketplace.Factory;
    _Shuffle : Shuffle.Factory;
  };

  type SendArgs = {
    memo : Nat64;
    amount : ICPTs;
    fee : ICPTs;
    from_subaccount : ?SubAccount;
    to : AccountIdentifier;
    created_at_time : ?Time.Time;
  };

  public type Constants = {
    LEDGER_CANISTER : actor {
      account_balance_dfx : shared query AccountBalanceArgs -> async ICPTs;
      send_dfx : shared SendArgs -> async Nat64;
    };
    minter : Principal;
  };

  public type AccountIdentifier = ExtCore.AccountIdentifier;

  public type Time = Time.Time;

  public type TokenIdentifier = ExtCore.TokenIdentifier;

  public type SubAccount = ExtCore.SubAccount;

  public type CommonError = ExtCore.CommonError;

  public type TokenIndex = ExtCore.TokenIndex;

  public type ICPTs = { e8s : Nat64 };

  public type AccountBalanceArgs = { account : AccountIdentifier };

  public type Sale = {
    tokens : [TokenIndex];
    price : Nat64;
    subaccount : SubAccount;
    buyer : AccountIdentifier;
    expires : Time;
  };

  public type SaleTransaction = {
    tokens : [TokenIndex];
    seller : Principal;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };
  public type SaleSettings = {
    price : Nat64;
    salePrice : Nat64;
    sold : Nat;
    remaining : Nat;
    startTime : Time;
    whitelistTime : Time;
    whitelist : Bool;
    totalToSell : Nat;
    bulkPricing : [(Nat64, Nat64)];
  };
};
