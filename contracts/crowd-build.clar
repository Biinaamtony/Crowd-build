

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
