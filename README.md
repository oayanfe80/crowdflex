# CrowdFlex - Decentralized Crowdfunding Contract

## Overview

CrowdFlex is a flexible, decentralized crowdfunding smart contract built on the Stacks blockchain. It enables creators to launch campaigns with configurable goals and deadlines, while providing contributors with transparent fund management and automatic refund mechanisms.

## Features

 **Campaign Management**
- Create campaigns with custom funding goals and deadlines
- Extend campaign deadlines for additional fundraising time
- Cancel campaigns before contributions are claimed

 **Contribution System**
- Track individual contributions per user
- Multiple contributions supported per user per campaign
- Secure STX fund transfers using the contract as escrow

 **Fund Claiming**
- Creators claim funds only when goal is met
- One-time claim per campaign (prevents double-claiming)
- Automatic fund transfer to creator upon successful claim

 **Refund Mechanism**
- Automatic refunds for failed campaigns (goal not met by deadline)
- Users can claim refunds after deadline passes
- Per-user contribution tracking for accurate refund amounts

 **Admin Controls**
- Transfer admin privileges to new addresses
- Remove problematic campaigns from contract state
- Centralized governance for contract maintenance

## Contract Functions

### Public Functions

| Function | Parameters | Description |
|----------|-----------|-------------|
| `create-campaign` | `goal: uint`, `duration: uint` | Create a new funding campaign |
| `contribute` | `id: uint`, `amount: uint` | Contribute STX to a campaign |
| `claim-funds` | `id: uint` | Claim raised funds (creator only, goal must be met) |
| `get-refund` | `id: uint` | Request refund (deadline passed, goal not met) |
| `cancel-campaign` | `id: uint` | Cancel campaign (creator only) |
| `extend-deadline` | `id: uint`, `extra: uint` | Extend campaign deadline (creator only) |
| `admin-remove` | `id: uint` | Remove campaign (admin only) |
| `transfer-admin` | `new-admin: principal` | Transfer admin role (admin only) |

### Read-Only Functions

| Function | Parameters | Returns |
|----------|-----------|---------|
| `get-campaign` | `id: uint` | Campaign details or none |
| `get-contribution` | `id: uint`, `user: principal` | User's contribution amount or none |
| `get-campaign-count` | None | Total number of campaigns created |

## Error Codes

| Code | Constant | Reason |
|------|----------|--------|
| u100 | `ERR_DEADLINE_PASSED` | Cannot contribute after deadline |
| u101 | `ERR_NOT_FOUND` | Campaign does not exist |
| u102 | `ERR_UNAUTHORIZED` | Caller lacks required permissions |
| u103 | `ERR_GOAL_NOT_MET` | Funding goal not achieved |
| u104 | `ERR_ALREADY_CLAIMED` | Funds already claimed |
| u105 | `ERR_NOTHING_TO_REFUND` | No contribution to refund |
| u106 | Custom error | Campaign is not active |
| u107 | Custom error | Campaign is not active (for operations requiring active state) |

## Usage Examples

### Create a Campaign
```clarity
(contract-call? .crowdflex create-campaign u1000000 u50400)
;; Creates a campaign with 1,000,000 microSTX goal, 50,400 block duration (~2 weeks)
```

### Contribute to a Campaign
```clarity
(contract-call? .crowdflex contribute u0 u50000)
;; Contribute 50,000 microSTX to campaign 0
```

### Claim Funds (as Creator)
```clarity
(contract-call? .crowdflex claim-funds u0)
;; Claim funds from campaign 0 (only if goal met)
```

### Request Refund
```clarity
(contract-call? .crowdflex get-refund u0)
;; Get refund from failed campaign 0
```

## Data Structures

### Campaign Tuple
```clarity
{
  creator: principal,      ;; Campaign creator address
  goal: uint,              ;; Funding goal in microSTX
  deadline: uint,          ;; Block height deadline
  raised: uint,            ;; Total amount raised
  claimed: bool,           ;; Whether funds were claimed
  active: bool             ;; Campaign active status
}
```

### Contribution Map
Maps `{ campaign-id: uint, user: principal }` to contribution amount (uint)

## Security Considerations

-  Only campaign creators can claim funds or modify their campaigns
-  Admin-only functions protected by admin authorization checks
-  Funds held in contract escrow until claim or refund
-  Contribution tracking prevents double-refunding
-  Deadline enforcement prevents post-deadline contributions
-  Goal verification prevents claiming on failed campaigns

## File Location

crowdflex.clar
