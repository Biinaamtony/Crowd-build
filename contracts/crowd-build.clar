

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

;; ...existing code...
