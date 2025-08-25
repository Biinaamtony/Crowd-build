# CrowdBuild - Decentralized Real Estate Investment Platform

A comprehensive smart contract built on Stacks blockchain using Clarity that enables decentralized real estate investment and rental income distribution.

## 🏢 Overview

CrowdBuild allows multiple investors to collectively invest in real estate properties and receive proportional rental income distributions through blockchain-based tokenization. The contract implements the SIP-010 fungible token standard to represent ownership shares in real estate assets.

## 🚀 Features

### Core Investment Features
- **Token-Based Ownership**: SIP-010 compliant fungible tokens representing property shares
- **STX Investment**: Invest Stacks (STX) to receive CrowdBuild Tokens (CBT)
- **Proportional Returns**: Rental income distributed based on token holdings
- **Flexible Claims**: Token holders can claim their rental income at any time

### Advanced Management Features
- **Voting System**: Token holders vote on property decisions with weight-based voting
- **Maintenance Fund**: Separate fund for property upkeep and improvements
- **Property Metrics**: Track occupancy rates and property values
- **Emergency Controls**: Owner emergency withdraw functionality
- **Batch Operations**: Efficient distribution to multiple token holders

### Analytics & Reporting
- **Expected Returns**: Calculate projected annual returns
- **Dividend History**: Track historical dividend payments
- **Contract Statistics**: Comprehensive metrics for monitoring
- **Dynamic Pricing**: Token price calculation based on property value

## 📋 Contract Functions

### Investment Functions
```clarity
(invest (amount uint))                          ;; Invest STX to receive tokens
(transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
(burn-tokens (amount uint))                     ;; Burn tokens to reduce supply
```

### Income Distribution
```clarity
(deposit-rental-income (amount uint))           ;; Owner deposits rental income
(distribute-income (recipient principal))       ;; Distribute to specific holder
(batch-distribute-income (recipients (list 10 principal))) ;; Batch distribution
(claim-income)                                  ;; Claim accumulated income
```

### Governance
```clarity
(submit-proposal (proposal (string-ascii 256)) (deadline uint)) ;; Submit proposal
(vote (support bool))                           ;; Vote on active proposal
```

### Property Management
```clarity
(update-property-value (new-value uint))        ;; Update property valuation
(update-property-metrics (properties uint) (occupancy uint)) ;; Update metrics
(contribute-to-maintenance (amount uint))       ;; Add to maintenance fund
(use-maintenance-fund (amount uint) (recipient principal)) ;; Use maintenance funds
```

### Read-Only Functions
```clarity
(get-balance (who principal))                   ;; Get token balance
(get-total-supply)                              ;; Get total token supply
(get-rental-income)                             ;; Get total rental income
(get-unclaimed-income (user principal))         ;; Get user's unclaimed income
(get-property-metrics)                          ;; Get property statistics
(get-expected-return)                           ;; Get expected annual return
(get-contract-stats)                            ;; Get comprehensive stats
```

## 🛠 Technical Specifications

- **Language**: Clarity Smart Contract Language
- **Blockchain**: Stacks (Bitcoin Layer 2)
- **Token Standard**: SIP-010 Fungible Token
- **Development Tool**: Clarinet
- **Total Lines**: 327 lines of code
- **Gas Optimization**: Efficient batch operations and minimal storage usage

## 🏗 Architecture

The contract is structured with the following components:

1. **Token Management**: SIP-010 compliant token with minting, burning, and transfer capabilities
2. **Investment Logic**: STX-to-token conversion with holder tracking
3. **Income Distribution**: Proportional rental income distribution system
4. **Governance Layer**: Voting mechanism for property-related decisions
5. **Maintenance System**: Dedicated fund management for property upkeep
6. **Analytics Engine**: Comprehensive reporting and metrics calculation

## 📊 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 401 | ERR-UNAUTHORIZED | Caller not authorized for this action |
| 402 | ERR-INSUFFICIENT-BALANCE | Insufficient token or STX balance |
| 403 | ERR-INVALID-AMOUNT | Invalid amount provided |
| 404 | ERR-NO-INCOME | No income available to claim |
| 405 | ERR-NO-TOKENS | No tokens in circulation |

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet (for testnet/mainnet deployment)

### Local Development
```bash
# Clone the repository
git clone https://github.com/Biinaamtony/Crowd-build.git
cd crowd-build

# Check contract syntax
clarinet check

# Run tests
clarinet test

# Deploy to local testnet
clarinet integrate
```

### Testing
The contract includes comprehensive TypeScript tests in the `tests/` directory:
```bash
npm test
```

## 🔒 Security Features

- **Owner-only functions** protected with authorization checks
- **Input validation** on all public functions  
- **Integer overflow protection** using safe arithmetic
- **Emergency withdraw** capability for contract owner
- **Unchecked data warnings** addressed with proper validation

## 📈 Use Cases

1. **Real Estate Crowdfunding**: Multiple investors pool funds for property acquisition
2. **Rental Income Distribution**: Automated distribution of rental payments
3. **Property Management**: Decentralized decision-making for property improvements
4. **Fractional Ownership**: Tokenized representation of real estate ownership
5. **Investment Analytics**: Transparent reporting of property performance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [SIP-010 Standard](https://github.com/stacksgov/sips/blob/main/sips/sip-010/sip-010-fungible-token-standard.md)
- [Clarinet Documentation](https://docs.hiro.so/smart-contracts/clarinet)

## 👥 Team

Built with ❤️ by the CrowdBuild development team.

---

**Disclaimer**: This smart contract is for educational and demonstration purposes. Always conduct thorough security audits before deploying to mainnet with real funds.
