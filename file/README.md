# Reputation-Based Lending System

A decentralized lending platform built on Stacks blockchain that uses reputation scores to determine borrowing limits and loan terms.

## Overview

This system consists of two main contracts:
- **Reputation Lending Contract**: Core lending functionality with reputation-based borrowing
- **Reputation Oracle Contract**: External reputation verification and aggregation system

## Features

### Core Lending System
- **Reputation-Based Borrowing**: Loan limits based on user reputation scores
- **Dynamic Interest Rates**: Interest calculations based on loan amount and borrower reputation
- **Automated Loan Management**: Track active loans, due dates, and repayment status
- **Late Payment Penalties**: Additional fees for overdue loans
- **Comprehensive Borrower Profiles**: Track borrowing history, repayment patterns, and defaults

### Oracle Integration
- **Multi-Source Reputation**: Aggregate reputation data from multiple external sources
- **Weighted Scoring**: Configurable weights for different reputation providers
- **Data Freshness Validation**: Ensure reputation data is current and valid
- **Oracle Management**: Administrative controls for managing reputation sources

### Security Features
- **Emergency Pause**: Contract owner can pause operations in emergencies
- **Access Control**: Role-based permissions for critical functions
- **Input Validation**: Comprehensive checks for all user inputs
- **Overflow Protection**: Safe arithmetic operations throughout

## Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation
1. Clone the repository
2. Install dependencies: `clarinet requirements`
3. Run tests: `clarinet test`
4. Deploy locally: `clarinet console`

### Contract Deployment
```bash
# Deploy to devnet
clarinet deploy --devnet

# Deploy to testnet
clarinet deploy --testnet
```

## Usage

### For Borrowers

#### 1. Register as a Borrower
```clarity
(contract-call? .reputation-lending register-borrower 'SP1234...)
```

#### 2. Check Your Borrow Limit
```clarity
(contract-call? .reputation-lending get-borrow-limit 'SP1234...)
```

#### 3. Borrow Funds
```clarity
(contract-call? .reputation-lending borrow u500)
```

#### 4. Repay Loan
```clarity
(contract-call? .reputation-lending repay-loan)
```

### For Lenders

#### 1. Add Liquidity to Pool
```clarity
(contract-call? .reputation-lending lend-to-pool u10000)
```

#### 2. Check Pool Statistics
```clarity
(contract-call? .reputation-lending get-contract-stats)
```

### For Oracle Operators

#### 1. Register as Oracle (Owner Only)
```clarity
(contract-call? .reputation-oracle register-oracle "GitHub-Oracle" 'SP5678... u30)
```

#### 2. Submit Reputation Data
```clarity
(contract-call? .reputation-oracle submit-reputation 'SP1234... u1 u750 0x123...)
```

## Contract Architecture

### Data Structures

#### Borrower Data
- `reputation`: Current reputation score
- `debt`: Outstanding loan amount
- `total-borrowed`: Lifetime borrowing amount
- `total-repaid`: Lifetime repayment amount
- `loans-completed`: Number of successful loan completions
- `defaults`: Number of loan defaults

#### Active Loans
- `amount`: Principal loan amount
- `interest`: Calculated interest amount
- `due-block`: Block height when loan is due
- `loan-start`: Block height when loan was initiated

#### Oracle Data
- `oracle-name`: Human-readable oracle identifier
- `oracle-address`: Principal address of oracle operator
- `is-active`: Whether oracle is currently active
- `reputation-weight`: Weight in reputation calculations

### Key Functions

#### Lending Contract
- `register-borrower`: Register new borrower
- `borrow`: Request loan
- `repay-loan`: Repay active loan
- `lend-to-pool`: Add liquidity to lending pool
- `get-borrow-limit`: Calculate borrowing capacity
- `get-loan-details`: Get active loan information

#### Oracle Contract
- `register-oracle`: Add new reputation source
- `submit-reputation`: Submit reputation data
- `get-aggregated-reputation`: Get weighted reputation score
- `calculate-aggregated-reputation`: Compute final reputation

## Security Considerations

### Access Control
- Contract owner controls oracle registration and emergency functions
- Only registered oracles can submit reputation data
- Borrowers can only manage their own loans

### Data Validation
- All amounts must be positive
- Reputation scores capped at maximum values
- Loan limits respect available pool liquidity
- Oracle data includes freshness checks

### Emergency Measures
- Contract can be paused by owner
- Individual oracles can be deactivated
- Oracle weights can be adjusted for risk management

## Testing

Run the test suite:
```bash
clarinet test
```

Run specific test:
```bash
clarinet test tests/reputation-lending-test.ts
```

## Configuration

### Environment Variables
- `CLARINET_MODE`: Set to "development" or "production"
- `NETWORK`: Target network (devnet/testnet/mainnet)

### Contract Parameters
- `default-limit`: Base borrowing limit (1000 STX)
- `max-loan-duration`: Maximum loan duration (144 blocks)
- `interest-rate`: Base interest rate (5%)
- `late-fee-rate`: Late payment penalty (10%)
- `reputation-threshold`: Minimum reputation for enhanced limits

## Roadmap

### Phase 3 (Planned)
- [ ] Multi-asset lending support
- [ ] Liquidation mechanisms
- [ ] Governance token integration
- [ ] Advanced risk modeling
- [ ] Cross-chain reputation bridging

### Phase 4 (Future)
- [ ] Decentralized oracle network
- [ ] Insurance fund integration
- [ ] Automated market makers
- [ ] Mobile application
- [ ] Institutional lending features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Audit Status

⚠️ **Note**: These contracts have not been audited. Use at your own risk in production environments.

## Support

For questions and support:
- Create an issue in the repository
- Join our Discord community
- Check the documentation wiki

## Changelog

### Version 2.0.0 (Phase 2)
- **Fixed**: Proper error handling in borrower registration
- **Added**: Complete lending functionality with borrow/repay
- **Added**: Reputation oracle system for external data
- **Enhanced**: Security with emergency pause functionality
- **Enhanced**: Comprehensive borrower profiles and loan tracking
- **Updated**: Clarinet configuration with proper dependencies
- **Updated**: README with complete usage documentation

### Version 1.0.0 (Phase 1)
- Basic borrower registration
- Simple reputation tracking
- Borrow limit calculations
