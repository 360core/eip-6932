// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC6932Receiver.sol";
import "./ERC6932Receiver.sol";

contract ERC6932 is ERC20 {

    enum IsSubscribed { No, Yes }

    event Subscribed(address indexed subscriber, uint256 indexed amount, uint256 indexed subscriptionId);
    event Unsubscribed(address indexed subscriber, uint256 indexed subscriptionId, uint256 indexed totalAmount);

    struct SubInfo {
        IsSubscribed isSubscribed;
        uint idx;
    }

    mapping (address => mapping( uint => IERC6932Receiver.ERC6932Subscription )) public subscribed;
    mapping (address => mapping( address => SubInfo ) ) public subInfo;
    mapping (address => uint) public subscriptionCount;
    mapping (address => bool) public isRegistered;

    mapping (address => uint256) public effectiveBalance;
    bytes public EIP6932ByteCode;

    constructor() ERC20("CoreToken", "T360") {
        _mint(msg.sender, 100 ether);
        ERC6932Receiver oracleSubscription = new ERC6932Receiver();
        EIP6932ByteCode = codeAt(address(oracleSubscription));
    }

    // override functions
    function _transfer( address sender, address recipient, uint256 amount ) internal override {
        super._transfer( sender, recipient, amount );
        
        effectiveBalance[sender] = balanceOf( sender ) - amount;
        effectiveBalance[recipient] = balanceOf( recipient ) + amount;
    }

    function verifyEIP6932(address _tokenContract) public view returns (bool) {
        bytes memory fetchedTokenByteCode = codeAt(_tokenContract);

        if (fetchedTokenByteCode.length != EIP6932ByteCode.length) {
            return false; //clear mismatch
        }

      //starting iterating through it if lengths match
        for (uint i = 0; i < fetchedTokenByteCode.length; i++) {
            if (fetchedTokenByteCode[i] != EIP6932ByteCode[i]) {
                return false;
            }
        }
        return true;
    }

    function subscribe( address subscription ) external {
        require( verifyEIP6932(subscription), "ERC6932: invalid subscription" );
        IERC6932Receiver.ERC6932Subscription memory info;
        try IERC6932Receiver( subscription ).getSubscriptionInfo() returns ( IERC6932Receiver.ERC6932Subscription memory _info ) {
            info = _info;
        } catch {
            revert("ERC6932: invalid subscription");
        }

        uint256 totalAmount = info.amount * info.intervals;
        require( totalAmount > 0, "ERC6932: invalid subscription amount" );

        uint subscriptionId = subscriptionCount[msg.sender];
        subscribed[msg.sender][subscriptionId] = info;
        subscriptionCount[msg.sender]++;
        IERC6932Receiver( subscription ).subscribe( msg.sender );
        
        require( !( subInfo[msg.sender][subscription].isSubscribed == IsSubscribed.Yes ), "ERC6932: already subscribed" );
        subInfo[msg.sender][subscription] = SubInfo(IsSubscribed.Yes, subscriptionId);
    }

    function _lockedBalance( address account ) internal view returns ( uint256 ) {
        uint256 totalAmount = 0;
        for( uint i = 0; i < subscriptionCount[account]; i++ ) {
            IERC6932Receiver.ERC6932Subscription memory info = subscribed[account][i];

            uint256 intervals = ( block.timestamp - info.start ) / info.frequency;
            uint256 amount = info.amount * intervals;

            uint256 localEffectiveBalance = effectiveBalance[account];

            if ( (totalAmount + amount) > localEffectiveBalance ) {
                amount = localEffectiveBalance;
            }

            totalAmount += ( localEffectiveBalance - amount );
        }

        return totalAmount;
    }

    function balanceOf( address account ) public view override returns ( uint256 ) {
        return isContract(account) ? 0 : _lockedBalance( account );
    }

    function _getIsSubscribed( address account, uint _idx ) internal view returns ( bool ) {
        uint256 totalAmount = 0;
        bool isSubscribed = true;
        for( uint i = 0; i < subscriptionCount[account]; i++ ) {
            IERC6932Receiver.ERC6932Subscription memory info = subscribed[account][i];

            uint256 intervals = ( block.timestamp - info.start ) / info.frequency;
            uint256 amount = info.amount * intervals;

            uint256 localEffectiveBalance = effectiveBalance[account];

            if ( ((totalAmount + amount) > localEffectiveBalance && i == _idx) ) {
                isSubscribed = false;
                break;
            }
        }

        return false;
    }

    function _getBalanceOfReceiver( address receiver ) internal view returns ( uint256 totalAmount ) {
        IERC6932Receiver.ERC6932Subscription memory info = IERC6932Receiver(receiver).getSubscriptionInfo();

        for ( uint i = 0; i < info.subscriberCount; i ++ ) {
            address subscriber = IERC6932Receiver(receiver).getSubscriberAt( i );
            if ( isSubscribedTo( subscriber, receiver ) ) {
                totalAmount += info.amount;
            }
        }
    }

    function isSubscribedTo( address account, address operator ) public view returns ( bool ) {
        uint idx = subInfo[account][operator].idx;

        return _getIsSubscribed( account, idx );
    }

    function isContract( address account ) internal view returns ( bool ) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function codeAt(address _addr) internal view returns (bytes memory outputCode) {
        assembly {
            let size := extcodesize(_addr)
            outputCode := mload(0x40)
            mstore(0x40, add(outputCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(outputCode, size)
            extcodecopy(_addr, add(outputCode, 0x20), 0, size)
        }
    }
}