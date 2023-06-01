// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC6932Receiver {
    struct ERC6932Subscription {
        address operator;
        uint256 amount;
        uint256 start;
        uint256 frequency;
        uint256 intervals;
        uint subscriberCount;
    }

    function onSubscription(
        address subscriber,
        uint256 amount,
        uint256 subscriptionId
    ) external returns (bool);

    function onUnsubscription(
        address subscriber,
        uint256 subscriptionId,
        uint256 totalAmount
    ) external returns (bool);

    function subscribe( address account ) external;

    function getSubscriptionInfo() external view returns ( ERC6932Subscription memory );
    function getSubscriberAt(uint idx) external view returns ( address );
}