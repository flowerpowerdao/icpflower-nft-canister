import Time "mo:base/Time";

import ExtCommon "../toniq-labs/ext/Common";
import ExtCore "../toniq-labs/ext/Core";

module {

  public func newStableState() : StableState {
    return {
      _tokenMetadataState : [(TokenIndex, Metadata)] = [];
      _ownersState : [(AccountIdentifier, [TokenIndex])] = [];
      _registryState : [(TokenIndex, AccountIdentifier)] = [];
      _nextTokenIdState : TokenIndex = 0;
      _supplyState : Balance = 0;
    };
  };

  public type TokenIdentifier = ExtCore.TokenIdentifier;

  public type TokenIndex = ExtCore.TokenIndex;

  public type Metadata = ExtCommon.Metadata;

  public type AccountIdentifier = ExtCore.AccountIdentifier;

  public type Balance = ExtCore.Balance;

  public type BalanceRequest = ExtCore.BalanceRequest;

  public type BalanceResponse = ExtCore.BalanceResponse;

  public type Listing = {
    seller : Principal;
    price : Nat64;
    locked : ?Time;
  };

  public type Time = Time.Time;

  public type SubAccount = ExtCore.SubAccount;

  public type CommonError = ExtCore.CommonError;

  public type ICPTs = { e8s : Nat64 };

  public type StableState = {
    _tokenMetadataState : [(TokenIndex, Metadata)];
    _ownersState : [(AccountIdentifier, [TokenIndex])];
    _registryState : [(TokenIndex, AccountIdentifier)];
    _nextTokenIdState : TokenIndex;
    _supplyState : Balance;
  };

  public type Constants = {
    minter : Principal;
  }
};
