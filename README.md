# EIP-6932 - auto-deduct subscription based erc20 token

a working implementation of an [EIP-6932](https://github.com/ethereum/EIPs/pull/6933) token, the auto deduction of a subscription to a subscriber will be calculated in `balanceOf` function.

subscription can check for an active subscription of a subscriber using `isSubscribedTo` function.

ERC6932 uses `effectiveBalance` and `lockedBalance` for calculating the token balance of an address, using these variables, total subscribed amount will be calculated and substracted from the `effectiveBalance`
#
# scenarios
## when user subscribes
initially the `subscription.amount` will be deducted from the user, updating the `effectiveBalance`, a timestamp will be stored, and further calculations will be evaluated, also stores subscriber info to the subscription
## when user cancel subscription
`effectiveBalance` will be updated for both the subscribers and subscription, cancel the user info from the subscription

## when user renews the subscription
same as subscribe, starts from the timestamp for renewal

## user does not have balance, then how?
in ERC-6932, subscription amount will be considered in a FIFD ( first-in-first-debit ) pattern, if the total deduction reaches a subscription `s1`, where user `balanceOf` is less than the amount or zero, the subscription `s1` to subscriber will be considered as void, `all evaluation will be in view modifier`

#
## files overview
this repo contains: [ERC6932.sol](https://github.com/360core/eip-6932/blob/master/contracts/ERC6932.sol), [ERC6932Receiver.sol](https://github.com/360core/eip-6932/blob/master/contracts/ERC6932Receiver.sol) and [IERC6932Receiver.sol](https://github.com/360core/eip-6932/blob/master/contracts/IERC6932Receiver.sol)

#

## usage
### install

```bash
npm i
// or
yarn install
```
### compile
```bash
npm compile
// or
yarn compile
```

# contributions
you can contribute any changes or issues regarding eip-6932 files or concept
