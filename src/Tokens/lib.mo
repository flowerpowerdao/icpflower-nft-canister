import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";

import AID "../toniq-labs/util/AccountIdentifier";
import Buffer "../buffer";
import ExtCore "../toniq-labs/ext/Core";
import Types "types";
import Utils "../utils";

module {
  public class Factory(this : Principal, state : Types.StableState, consts : Types.Constants) {

    /*********
    * STATE *
    *********/

    private var _tokenMetadata : TrieMap.TrieMap<Types.TokenIndex, Types.Metadata> = TrieMap.fromEntries(state._tokenMetadataState.vals(), ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
    private var _owners : TrieMap.TrieMap<Types.AccountIdentifier, Buffer.Buffer<Types.TokenIndex>> = Utils.bufferTrieMapFromIter(state._ownersState.vals(), AID.equal, AID.hash);
    private var _registry : TrieMap.TrieMap<Types.TokenIndex, Types.AccountIdentifier> = TrieMap.fromEntries(state._registryState.vals(), ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
    private var _nextTokenId : Types.TokenIndex = state._nextTokenIdState;
    private var _supply : Types.Balance = state._supplyState;

    public func toStable() : Types.StableState {
      return {
        _tokenMetadataState = Iter.toArray(_tokenMetadata.entries());
        _ownersState = Iter.toArray(
          Iter.map<(Types.AccountIdentifier, Buffer.Buffer<Types.TokenIndex>), (Types.AccountIdentifier, [Types.TokenIndex])>(
            _owners.entries(),
            func(owner) {
              return (owner.0, owner.1.toArray());
            },
          ),
        );
        _registryState = Iter.toArray(_registry.entries());
        _nextTokenIdState = _nextTokenId;
        _supplyState = _supply;
      };
    };

    //*** ** ** ** ** ** ** ** ** * * PUBLIC INTERFACE * ** ** ** ** ** ** ** ** ** ** /

    public func balance(request : Types.BalanceRequest) : Types.BalanceResponse {
      if (ExtCore.TokenIdentifier.isPrincipal(request.token, this) == false) {
        return #err(#InvalidToken(request.token));
      };
      let token = ExtCore.TokenIdentifier.getIndex(request.token);
      let aid = ExtCore.User.toAID(request.user);
      switch (_registry.get(token)) {
        case (?token_owner) {
          if (AID.equal(aid, token_owner) == true) {
            return #ok(1);
          } else {
            return #ok(0);
          };
        };
        case (_) {
          return #err(#InvalidToken(request.token));
        };
      };
    };

    public func bearer(token : Types.TokenIdentifier) : Result.Result<Types.AccountIdentifier, Types.CommonError> {
      if (ExtCore.TokenIdentifier.isPrincipal(token, this) == false) {
        return #err(#InvalidToken(token));
      };
      let tokenind = ExtCore.TokenIdentifier.getIndex(token);
      switch (getBearer(tokenind)) {
        case (?token_owner) {
          return #ok(token_owner);
        };
        case (_) {
          return #err(#InvalidToken(token));
        };
      };
    };

    /*******************
    * INTERNAL METHODS *
    *******************/

    public func getOwnerFromRegistry(tokenIndex : Types.TokenIndex) : ?Types.AccountIdentifier {
      return _registry.get(tokenIndex);
    };

    public func getTokensFromOwner(aid : Types.AccountIdentifier) : ?Buffer.Buffer<Types.TokenIndex> {
      _owners.get(aid);
    };

    public func registrySize() : Nat {
      return _registry.size();
    };

    public func getNextTokenId() : Types.TokenIndex {
      return _nextTokenId;
    };

    public func incrementNextTokenId() {
      _nextTokenId := _nextTokenId + 1;
    };

    public func incrementSupply() {
      _supply := _supply + 1;
    };

    public func getSupply() : Types.Balance {
      _supply;
    };

    public func getRegistry() : TrieMap.TrieMap<Types.TokenIndex, Types.AccountIdentifier> {
      _registry;
    };

    public func getTokenMetadata() : TrieMap.TrieMap<Types.TokenIndex, Types.Metadata> {
      _tokenMetadata;
    };

    public func getMetadataFromTokenMetadata(tokenIndex : Types.TokenIndex) : ?Types.Metadata {
      _tokenMetadata.get(tokenIndex);
    };

    public func putTokenMetadata(index : Types.TokenIndex, metadata : Types.Metadata) {
      _tokenMetadata.put(index, metadata);
    };

    public func getTokenDataFromIndex(tokenind : Nat32) : ?Blob {
      switch (_tokenMetadata.get(tokenind)) {
        case (?token_metadata) {
          switch (token_metadata) {
            case (#fungible data) return null;
            case (#nonfungible data) return data.metadata;
          };
        };
        case (_) {
          return null;
        };
      };
      return null;
    };

    public func getTokenData(token : Text) : ?Blob {
      if (ExtCore.TokenIdentifier.isPrincipal(token, this) == false) {
        return null;
      };
      let tokenind = ExtCore.TokenIdentifier.getIndex(token);
      switch (_tokenMetadata.get(tokenind)) {
        case (?token_metadata) {
          switch (token_metadata) {
            case (#fungible data) return null;
            case (#nonfungible data) return data.metadata;
          };
        };
        case (_) {
          return null;
        };
      };
      return null;
    };

    public func transferTokenToUser(tindex : Types.TokenIndex, receiver : Types.AccountIdentifier) : () {
      let owner : ?Types.AccountIdentifier = getBearer(tindex); // who owns the token (no one if mint)
      _registry.put(tindex, receiver); // transfer the token to the new owner
      switch (owner) {
        case (?o) removeFromUserTokens(tindex, o);
        case (_) {};
      };
      addToUserTokens(tindex, receiver);
    };

    public func removeTokenFromUser(tindex : Types.TokenIndex) : () {
      let owner : ?Types.AccountIdentifier = getBearer(tindex);
      _registry.delete(tindex);
      switch (owner) {
        case (?o) removeFromUserTokens(tindex, o);
        case (_) {};
      };
    };

    public func removeFromUserTokens(tindex : Types.TokenIndex, owner : Types.AccountIdentifier) : () {
      switch (_owners.get(owner)) {
        case (?ownersTokens) _owners.put(owner, ownersTokens.filter(func(a : Types.TokenIndex) : Bool { (a != tindex) }));
        case (_)();
      };
    };

    public func addToUserTokens(tindex : Types.TokenIndex, receiver : Types.AccountIdentifier) : () {
      let ownersTokensNew : Buffer.Buffer<Types.TokenIndex> = switch (_owners.get(receiver)) {
        case (?ownersTokens) { ownersTokens.add(tindex); ownersTokens };
        case (_) Utils.bufferFromArray([tindex]);
      };
      _owners.put(receiver, ownersTokensNew);
    };

    public func getBearer(tindex : Types.TokenIndex) : ?Types.AccountIdentifier {
      _registry.get(tindex);
    };
  };
};
