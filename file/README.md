# Reputation-Scored Lending System

### Overview
This is a basic Clarity smart contract on the Stacks blockchain. It allows borrowers to register and maintains a credit reputation score. Future borrowing limits depend on the reputation accumulated through repayments.

### Project Setup
```bash
# Install Clarinet
curl -sSL https://get.clarinet.systems/install.sh | bash

# Create the project
clarinet new rep-lending-system
cd rep-lending-system

# Add contract
mkdir contracts
# Paste the contents of reputation-lending.clar into contracts/reputation-lending.clar

# Run tests (to be added later)
clarinet test
```

### Contract Features
- **Register Borrower:** Adds a borrower with default values.
- **Get Reputation:** Reads the borrower’s reputation score.
- **Get Borrow Limit:** Calculates allowed borrow limit based on reputation.

### Next Steps
- Implement `borrow` and `repay` logic
- Track repayments and penalties
- Introduce slashing for defaults or late payments
- Write unit tests in TypeScript

### License
MIT
