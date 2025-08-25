

;; CrowdBuild - Decentralized Real Estate Investment Contract
;; SIP-010 Fungible Token Implementation for Investment Shares

(define-fungible-token crowdbuild-token)

;; Contract owner
(define-constant contract-owner 'SP000000000000000000002Q6VF78)

;; Total rental income accrued
(define-data-var total-rental-income uint u0)

;; Mapping of address to unclaimed rental income
(define-map unclaimed-income ((address principal)) ((amount uint)))

;; Event: Rental income distributed
(define-event rental-income-distributed (recipient principal) (amount uint))

;; Invest function: Users send STX to receive tokens
(define-public (invest)
	(let ((amount (stx-get-transfer-amount)))
		(if (is-eq amount u0)
			(err u100) ;; Error: Must send STX
			(begin
				(ft-mint? crowdbuild-token amount tx-sender)
				(ok amount)
			)
		)
	)
)

;; Helper to get transfer amount (Clarinet test only)
(define-read-only (stx-get-transfer-amount) (ok u1000)) ;; Placeholder for testing
;; Deposit rental income (owner only)
(define-public (deposit-rental-income (amount uint))
	(begin
		(asserts! (is-eq tx-sender contract-owner) (err u401))
		(var-set total-rental-income (+ (var-get total-rental-income) amount))
		(ok (var-get total-rental-income))
	)
)

;; Distribute rental income to all token holders
(define-public (distribute-income)
	(begin
		(asserts! (is-eq tx-sender contract-owner) (err u401))
		;; For demo: distribute equally to all holders (real: proportional)
		;; Placeholder: distribute to tx-sender only for now
		(let ((holder tx-sender)
			  (income (var-get total-rental-income)))
			(map-set unclaimed-income ((address holder)) ((amount income)))
			(var-set total-rental-income u0)
			(ok income)
		)
	)
)

;; Claim rental income
(define-public (claim-income)
	(let ((income (default-to u0 (get amount (map-get? unclaimed-income ((address tx-sender)))))))
		(if (> income u0)
			(begin
				(map-set unclaimed-income ((address tx-sender)) ((amount u0)))
				(stx-transfer? income contract-owner tx-sender)
			)
			(err u404)
		)
	)
)

;; ...existing code...
