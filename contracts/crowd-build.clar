

;; CrowdBuild - Decentralized Real Estate Investment Contract
;; SIP-010 Fungible Token Implementation for Investment Shares

(define-fungible-token crowdbuild-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-INVALID-AMOUNT (err u403))
(define-constant ERR-NO-INCOME (err u404))
(define-constant ERR-NO-TOKENS (err u405))

;; Data variables
(define-data-var total-rental-income uint u0)
(define-data-var property-value uint u1000000) ;; 1 million uSTX property value

;; Data maps
(define-map unclaimed-income principal uint)
(define-map holders principal bool)

;; SIP-010 trait implementation
(define-read-only (get-name)
    (ok "CrowdBuild Token")
)

(define-read-only (get-symbol)
    (ok "CBT")
)

(define-read-only (get-decimals)
    (ok u6)
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance crowdbuild-token who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply crowdbuild-token))
)

(define-read-only (get-token-uri)
    (ok none)
)

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (is-eq from tx-sender) ERR-UNAUTHORIZED)
        (try! (ft-transfer? crowdbuild-token amount from to))
        (map-set holders to true)
        (ok true)
    )
)
;; Investment function: Users invest STX to receive tokens
(define-public (invest (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (try! (ft-mint? crowdbuild-token amount tx-sender))
        (map-set holders tx-sender true)
        (ok amount)
    )
)

;; Deposit rental income (owner only)
(define-public (deposit-rental-income (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (var-set total-rental-income (+ (var-get total-rental-income) amount))
        (ok (var-get total-rental-income))
    )
)

;; Distribute rental income proportionally to all token holders
(define-public (distribute-income (recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (let ((total-supply (ft-get-supply crowdbuild-token))
              (income (var-get total-rental-income))
              (holder-balance (ft-get-balance crowdbuild-token recipient)))
            (asserts! (> total-supply u0) ERR-NO-TOKENS)
            (asserts! (> income u0) ERR-NO-INCOME)
            (let ((share (/ (* income holder-balance) total-supply)))
                (map-set unclaimed-income recipient 
                    (+ (default-to u0 (map-get? unclaimed-income recipient)) share))
                (ok share)
            )
        )
    )
)

;; Claim rental income
(define-public (claim-income)
    (let ((income (default-to u0 (map-get? unclaimed-income tx-sender))))
        (asserts! (> income u0) ERR-NO-INCOME)
        (map-delete unclaimed-income tx-sender)
        (try! (as-contract (stx-transfer? income tx-sender tx-sender)))
        (ok income)
    )
)

;; Read-only functions for querying contract state
(define-read-only (get-rental-income)
    (var-get total-rental-income)
)

(define-read-only (get-unclaimed-income (user principal))
    (default-to u0 (map-get? unclaimed-income user))
)

(define-read-only (get-property-value)
    (var-get property-value)
)

(define-read-only (is-holder (user principal))
    (default-to false (map-get? holders user))
)

;; Advanced features for commit 4

;; Update property value (owner only)
(define-public (update-property-value (new-value uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (> new-value u0) ERR-INVALID-AMOUNT)
        (var-set property-value new-value)
        (ok new-value)
    )
)

;; Emergency withdraw function (owner only)
(define-public (emergency-withdraw)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (let ((contract-balance (stx-get-balance (as-contract tx-sender))))
            (try! (as-contract (stx-transfer? contract-balance tx-sender contract-owner)))
            (ok contract-balance)
        )
    )
)

;; Burn tokens (reduce total supply)
(define-public (burn-tokens (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (ft-get-balance crowdbuild-token tx-sender) amount) ERR-INSUFFICIENT-BALANCE)
        (try! (ft-burn? crowdbuild-token amount tx-sender))
        (ok amount)
    )
)

;; Get contract STX balance
(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

;; Calculate token price based on property value and supply
(define-read-only (get-token-price)
    (let ((total-supply (ft-get-supply crowdbuild-token))
          (property-val (var-get property-value)))
        (if (is-eq total-supply u0)
            u1 ;; Default price of 1 uSTX per token
            (/ property-val total-supply)
        )
    )
)

;; Batch distribute income to multiple recipients
(define-public (batch-distribute-income (recipients (list 10 principal)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (let ((income (var-get total-rental-income)))
            (asserts! (> income u0) ERR-NO-INCOME)
            (ok (map distribute-to-holder recipients))
        )
    )
)

;; Helper function for batch distribution
(define-private (distribute-to-holder (recipient principal))
    (let ((total-supply (ft-get-supply crowdbuild-token))
          (income (var-get total-rental-income))
          (holder-balance (ft-get-balance crowdbuild-token recipient)))
        (if (and (> total-supply u0) (> holder-balance u0))
            (let ((share (/ (* income holder-balance) total-supply)))
                (map-set unclaimed-income recipient 
                    (+ (default-to u0 (map-get? unclaimed-income recipient)) share))
                share
            )
            u0
        )
    )
)

;; Final commit features: Advanced contract management

;; Voting mechanism for property decisions
(define-map property-votes principal uint)
(define-data-var current-proposal (string-ascii 256) "")
(define-data-var voting-deadline uint u0)

;; Submit a property proposal (owner only)
(define-public (submit-proposal (proposal (string-ascii 256)) (deadline uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (> deadline block-height) ERR-INVALID-AMOUNT)
        (var-set current-proposal proposal)
        (var-set voting-deadline deadline)
        (ok true)
    )
)

;; Vote on current proposal (token holders only)
(define-public (vote (support bool))
    (begin
        (asserts! (> (ft-get-balance crowdbuild-token tx-sender) u0) ERR-NO-TOKENS)
        (asserts! (<= block-height (var-get voting-deadline)) ERR-INVALID-AMOUNT)
        (let ((vote-weight (ft-get-balance crowdbuild-token tx-sender)))
            (map-set property-votes tx-sender (if support vote-weight u0))
            (ok vote-weight)
        )
    )
)

;; Get proposal information
(define-read-only (get-current-proposal)
    (ok (var-get current-proposal))
)

;; Get voting deadline
(define-read-only (get-voting-deadline)
    (var-get voting-deadline)
)

;; Property maintenance fund
(define-data-var maintenance-fund uint u0)

;; Contribute to maintenance fund
(define-public (contribute-to-maintenance (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set maintenance-fund (+ (var-get maintenance-fund) amount))
        (ok (var-get maintenance-fund))
    )
)

;; Use maintenance fund (owner only)
(define-public (use-maintenance-fund (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (>= (var-get maintenance-fund) amount) ERR-INSUFFICIENT-BALANCE)
        (var-set maintenance-fund (- (var-get maintenance-fund) amount))
        (try! (as-contract (stx-transfer? amount tx-sender recipient)))
        (ok amount)
    )
)

;; Get maintenance fund balance
(define-read-only (get-maintenance-fund)
    (var-get maintenance-fund)
)

;; Property metrics tracking
(define-data-var total-properties uint u1)
(define-data-var occupancy-rate uint u100) ;; Percentage (0-100)

;; Update property metrics (owner only)
(define-public (update-property-metrics (properties uint) (occupancy uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (> properties u0) ERR-INVALID-AMOUNT)
        (asserts! (<= occupancy u100) ERR-INVALID-AMOUNT)
        (var-set total-properties properties)
        (var-set occupancy-rate occupancy)
        (ok true)
    )
)

;; Get property metrics
(define-read-only (get-property-metrics)
    (ok {
        total-properties: (var-get total-properties),
        occupancy-rate: (var-get occupancy-rate),
        property-value: (var-get property-value)
    })
)

;; Calculate expected annual return based on occupancy
(define-read-only (get-expected-return)
    (let ((annual-rent (/ (* (var-get property-value) u8) u100)) ;; 8% of property value
          (occupancy (var-get occupancy-rate)))
        (/ (* annual-rent occupancy) u100)
    )
)

;; Token holder dividend history
(define-map dividend-history principal (list 10 uint))

;; Record dividend payment
(define-private (record-dividend (recipient principal) (amount uint))
    (let ((history (default-to (list) (map-get? dividend-history recipient))))
        (map-set dividend-history recipient (unwrap-panic (as-max-len? (append history amount) u10)))
        amount
    )
)

;; Get dividend history for a user
(define-read-only (get-dividend-history (user principal))
    (default-to (list) (map-get? dividend-history user))
)

;; Contract statistics
(define-read-only (get-contract-stats)
    (ok {
        total-token-supply: (ft-get-supply crowdbuild-token),
        total-holders: u1, ;; Simplified - would need iterator in real implementation
        contract-balance: (stx-get-balance (as-contract tx-sender)),
        rental-income: (var-get total-rental-income),
        maintenance-fund: (var-get maintenance-fund),
        property-value: (var-get property-value)
    })
)
