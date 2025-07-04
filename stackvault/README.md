# StackVault Protocol

**Revolutionary Bitcoin-Native Portfolio DeFi Protocol**

[![Stacks](https://img.shields.io/badge/Built%20on-Stacks-5546FF?style=for-the-badge&logo=stacks)](https://stacks.co)
[![Bitcoin](https://img.shields.io/badge/Secured%20by-Bitcoin-F7931A?style=for-the-badge&logo=bitcoin)](https://bitcoin.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

## Overview

StackVault transforms traditional portfolio management by bringing Wall Street-level sophistication to Bitcoin DeFi. Built on Stacks Layer 2, the protocol enables users to construct diversified cryptocurrency portfolios with mathematical precision, automated rebalancing algorithms, and gas-efficient operations that scale with Bitcoin's security model.

### Key Features

- 🎯 **Dynamic Multi-Asset Portfolios** - Create sophisticated portfolios with up to 10 different tokens
- ⚡ **Automated Rebalancing** - Smart contract-driven portfolio rebalancing with configurable intervals
- 📊 **Institutional-Grade Precision** - Basis point allocation management for professional-grade control
- 🔒 **Bitcoin Security** - Inherits Bitcoin's security model through Stacks Layer 2
- 💰 **Gas Optimized** - Minimal on-chain storage footprint with efficient operations
- 🏦 **Multi-Portfolio Management** - Manage up to 20 portfolios per user with granular controls
- 🔌 **SIP-010 Compatible** - Seamless integration with Stacks DeFi ecosystem

## System Overview

### Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                    StackVault Protocol                     │
├─────────────────────────────────────────────────────────────┤
│  Portfolio Management Layer                                 │
│  ├── Portfolio Creation Engine                             │
│  ├── Rebalancing Algorithm                                 │
│  └── Allocation Management System                          │
├─────────────────────────────────────────────────────────────┤
│  Data Storage Layer                                         │
│  ├── Portfolio Metadata (Portfolios Map)                   │
│  ├── Asset Allocations (PortfolioAssets Map)               │
│  └── User Registry (UserPortfolios Map)                    │
├─────────────────────────────────────────────────────────────┤
│  Protocol Infrastructure                                    │
│  ├── Validation & Security Layer                           │
│  ├── Error Handling System                                 │
│  └── Admin & Governance Controls                           │
└─────────────────────────────────────────────────────────────┘
```

### Core Data Structures

#### Portfolio Metadata

```clarity
{
  owner: principal,
  created-at: uint,
  last-rebalanced: uint,
  total-value: uint,
  active: bool,
  token-count: uint
}
```

#### Asset Allocation

```clarity
{
  target-percentage: uint,    // Basis points (10000 = 100%)
  current-amount: uint,       // Token quantity held
  token-address: principal    // SIP-010 token contract
}
```

## Contract Architecture

### State Management

The protocol employs a three-tier state management system:

1. **Portfolio Registry** - Core portfolio metadata indexed by unique IDs
2. **Asset Mapping** - Individual token allocations within portfolios
3. **User Relations** - Multi-portfolio ownership tracking per user

### Key Design Patterns

- **Composite Key Mapping** - Portfolio assets use composite keys for efficient lookups
- **Basis Point Precision** - All percentages use 10,000 basis points for institutional accuracy
- **Immutable Configuration** - Protocol constants prevent runtime manipulation
- **Fail-Safe Validation** - Comprehensive input validation with structured error codes

## Data Flow

### Portfolio Creation Flow

```
User Input → Validation → Portfolio Creation → Asset Initialization → User Registry Update
    ↓              ↓              ↓                    ↓                     ↓
Token List    Length Check   Metadata Store    Asset Allocation     Portfolio List
Percentages   Sum Validation   Counter Inc.     Map Population      Append & Store
```

### Rebalancing Flow

```
Rebalance Request → Authorization → Portfolio Validation → Timestamp Update → Success
        ↓               ↓                ↓                      ↓             ↓
   Portfolio ID    Owner Check     Active Status        Block Height    Return OK
   User Context    Permission      Portfolio State      Last Rebalanced  Emit Event
```

### Allocation Update Flow

```
Update Request → Multi-Layer Validation → Asset Update → State Persistence
      ↓               ↓                        ↓              ↓
  New Percentage  Owner + Token + Range    Map Merge     Storage Commit
  Target Asset    Authorization Check      New Values    Return Success
```

## Installation & Deployment

### Prerequisites

- Stacks CLI (`stx`)
- Node.js 16+
- Clarinet (for local development)

### Local Development

```bash
# Clone the repository
git clone https://github.com/your-org/stackvault-protocol
cd stackvault-protocol

# Install dependencies
npm install

# Start local development environment
clarinet console

# Deploy to local testnet
clarinet deploy --testnet
```

### Mainnet Deployment

```bash
# Deploy to Stacks mainnet
stx deploy_contract stackvault-protocol stackvault.clar --testnet
```

## Usage Examples

### Creating a Portfolio

```clarity
;; Create a balanced BTC/STX portfolio
(contract-call? .stackvault-protocol create-portfolio
  (list 'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.wrapped-bitcoin
        'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.wstx-token)
  (list u5000 u5000))  ;; 50% each in basis points
```

### Rebalancing a Portfolio

```clarity
;; Rebalance portfolio ID 1
(contract-call? .stackvault-protocol rebalance-portfolio u1)
```

### Updating Allocations

```clarity
;; Update token 0 allocation to 60%
(contract-call? .stackvault-protocol update-portfolio-allocation
  u1    ;; Portfolio ID
  u0    ;; Token ID
  u6000 ;; 60% in basis points
)
```

## Security Features

### Access Control

- **Owner-Only Operations** - Portfolio modifications restricted to owners
- **Principal-Based Authentication** - Stacks native identity system
- **Multi-Level Validation** - Input sanitization and boundary checks

### Economic Security

- **Basis Point Precision** - Prevents rounding errors in large portfolios
- **Gas Optimization** - Minimal storage footprint reduces transaction costs
- **Protocol Fees** - Sustainable economic model with configurable fee structure

### Operational Security

- **Comprehensive Error Handling** - Structured error codes for debugging
- **State Validation** - Portfolio status checks before operations
- **Immutable Constants** - Protocol parameters resist runtime manipulation

## API Reference

### Read-Only Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get-portfolio` | Retrieve portfolio metadata | `portfolio-id: uint` | `Portfolio` or `none` |
| `get-portfolio-asset` | Get asset allocation details | `portfolio-id: uint, token-id: uint` | `Asset` or `none` |
| `get-user-portfolios` | List user's portfolios | `user: principal` | `(list 20 uint)` |
| `calculate-rebalance-amounts` | Rebalancing recommendations | `portfolio-id: uint` | `RebalanceData` |

### Public Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `create-portfolio` | Create new portfolio | `tokens: (list 10 principal), percentages: (list 10 uint)` | `uint` (portfolio ID) |
| `rebalance-portfolio` | Execute rebalancing | `portfolio-id: uint` | `bool` |
| `update-portfolio-allocation` | Modify asset allocation | `portfolio-id: uint, token-id: uint, new-percentage: uint` | `bool` |

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-NOT-AUTHORIZED` | User lacks required permissions |
| 101 | `ERR-INVALID-PORTFOLIO` | Portfolio doesn't exist or inactive |
| 102 | `ERR-INSUFFICIENT-BALANCE` | Insufficient token balance |
| 103 | `ERR-INVALID-TOKEN` | Invalid token contract |
| 104 | `ERR-REBALANCE-FAILED` | Rebalancing operation failed |
| 105 | `ERR-PORTFOLIO-EXISTS` | Portfolio already exists |
| 106 | `ERR-INVALID-PERCENTAGE` | Invalid allocation percentage |
| 107 | `ERR-MAX-TOKENS-EXCEEDED` | Too many tokens in portfolio |
| 108 | `ERR-LENGTH-MISMATCH` | Array length mismatch |
| 109 | `ERR-USER-STORAGE-FAILED` | User storage operation failed |
| 110 | `ERR-INVALID-TOKEN-ID` | Invalid token identifier |

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
