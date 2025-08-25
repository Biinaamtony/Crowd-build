

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
