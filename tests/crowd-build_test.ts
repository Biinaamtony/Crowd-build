
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Test Suite 1: Basic SIP-010 Token Functionality
Clarinet.test({
    name: "SIP-010: Get token name returns 'CrowdBuild Token'",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-name', [], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(ok "CrowdBuild Token")');
    },
});

Clarinet.test({
    name: "SIP-010: Get token symbol returns 'CBT'",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-symbol', [], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(ok "CBT")');
    },
});

Clarinet.test({
    name: "SIP-010: Get token decimals returns 6",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-decimals', [], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(ok u6)');
    },
});

Clarinet.test({
    name: "SIP-010: Initial total supply is zero",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-total-supply', [], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(ok u0)');
    },
});

Clarinet.test({
    name: "SIP-010: Initial user balance is zero",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-balance', [types.principal(wallet1.address)], deployer.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(ok u0)');
    },
});

// Test Suite 2: Investment Functionality
Clarinet.test({
    name: "Investment: User can invest STX and receive tokens",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const investAmount = 1000;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'invest', [types.uint(investAmount)], wallet1.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, `(ok u${investAmount})`);
        
        // Check token balance after investment
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-balance', [types.principal(wallet1.address)], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, `(ok u${investAmount})`);
    },
});

Clarinet.test({
    name: "Investment: Cannot invest with zero amount",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'invest', [types.uint(0)], wallet1.address)
        ]);
        
        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(err u403)'); // ERR-INVALID-AMOUNT
    },
});

Clarinet.test({
    name: "Investment: Multiple users can invest and receive proportional tokens",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const amount1 = 500;
        const amount2 = 1500;
        
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'invest', [types.uint(amount1)], wallet1.address),
            Tx.contractCall('crowd-build', 'invest', [types.uint(amount2)], wallet2.address)
        ]);
        
        assertEquals(block.receipts.length, 2);
        assertEquals(block.receipts[0].result, `(ok u${amount1})`);
        assertEquals(block.receipts[1].result, `(ok u${amount2})`);
        
        // Check total supply
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-total-supply', [], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, `(ok u${amount1 + amount2})`);
    },
});

Clarinet.test({
    name: "Investment: Investor becomes a holder after investment",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const investAmount = 1000;
        
        // Check holder status before investment
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'is-holder', [types.principal(wallet1.address)], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, 'false');
        
        // Invest
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'invest', [types.uint(investAmount)], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, `(ok u${investAmount})`);
        
        // Check holder status after investment
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'is-holder', [types.principal(wallet1.address)], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, 'true');
    },
});

// Test Suite 3: Token Transfer Functionality
Clarinet.test({
    name: "Transfer: Token holder can transfer tokens to another user",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const investAmount = 2000;
        const transferAmount = 500;
        
        // First invest to get tokens
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'invest', [types.uint(investAmount)], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, `(ok u${investAmount})`);
        
        // Transfer tokens
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'transfer', [
                types.uint(transferAmount),
                types.principal(wallet1.address),
                types.principal(wallet2.address),
                types.none()
            ], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, '(ok true)');
        
        // Check balances after transfer
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'get-balance', [types.principal(wallet1.address)], wallet1.address),
            Tx.contractCall('crowd-build', 'get-balance', [types.principal(wallet2.address)], wallet1.address)
        ]);
        
        assertEquals(block.receipts[0].result, `(ok u${investAmount - transferAmount})`);
        assertEquals(block.receipts[1].result, `(ok u${transferAmount})`);
    },
});

Clarinet.test({
    name: "Transfer: Cannot transfer tokens on behalf of another user",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const wallet3 = accounts.get('wallet_3')!;
        const investAmount = 1000;
        const transferAmount = 500;
        
        // wallet1 invests
        let block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'invest', [types.uint(investAmount)], wallet1.address)
        ]);
        
        // wallet2 tries to transfer wallet1's tokens
        block = chain.mineBlock([
            Tx.contractCall('crowd-build', 'transfer', [
                types.uint(transferAmount),
                types.principal(wallet1.address),
                types.principal(wallet3.address),
                types.none()
            ], wallet2.address)
        ]);
        
        assertEquals(block.receipts[0].result, '(err u401)'); // ERR-UNAUTHORIZED
    },
});
