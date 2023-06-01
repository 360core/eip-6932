// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC6932Receiver.sol";

contract ERC6932Receiver is IERC6932Receiver {

    ERC6932Subscription public info;
    mapping ( uint => address ) public subscribers;

    function onSubscription(
        address subscriber,
        uint256 amount,
        uint256 subscriptionId
    ) external override returns (bool) {
        return true;
    }

    function onUnsubscription(
        address subscriber,
        uint256 subscriptionId,
        uint256 totalAmount
    ) external override returns (bool) {
        return true;
    }

    function subscribe( address account ) external override {
        subscribers[info.subscriberCount] = account;
        info.subscriberCount += 1;
    }

    function getSubscriptionInfo() external view returns ( ERC6932Subscription memory ) {
        return info;
    }

    function getSubscriberAt(uint idx) external override view returns ( address ) {
        return subscribers[idx];
    }
}