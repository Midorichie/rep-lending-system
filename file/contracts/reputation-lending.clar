;; Enhanced Reputation-Based Lending System
;; Fixes bugs and adds comprehensive lending functionality with security enhancements

;; Error constants
(define-constant err-not-found u404)
(define-constant err-insufficient-funds u400)
(define-constant err-loan-exists u401)
(define-constant err-no-active-loan u402)
(define-constant err-unauthorized u403)
(define-constant err-invalid-amount u405)
(define-constant err-loan-overdue u406)
(define-constant err-reputation-too-low u407)

;; Contract constants
(define-constant default-limit u1000)
(define-constant max-loan-duration u144) ;; blocks (~24 hours)
(define-constant reputation-threshold u10)
(define-constant interest-rate u5) ;; 5% per loan period
(define-constant late-fee-rate u10) ;; 10% penalty for late payments

;; Contract owner
(define-constant contract-owner tx-sender)

;; Data structures
(define-map borrowers
  ((borrower principal))
  ((reputation uint) 
   (debt uint) 
   (total-borrowed uint) 
   (total-repaid uint)
   (loans-completed uint)
   (defaults uint)))

(define-map active-loans
  ((borrower principal))
  ((amount uint) 
   (interest uint)
   (due-block uint)
   (loan-start uint)))

(define-map lenders
  ((lender principal))
  ((total-lent uint)
   (total-earned uint)
   (active-loans uint)))

;; Contract balance tracking
(define-data-var total-pool uint u0)
(define-data-var total-outstanding uint u0)

;; Public functions

;; Register a new borrower (Fixed: Proper structure)
(define-public (register-borrower (borrower principal))
  (begin
    (let ((existing-borrower (map-get? borrowers ((borrower borrower)))))
      (if (is-none existing-borrower)
        (begin
          (map-set borrowers ((borrower borrower))
            ((reputation u0) 
             (debt u0)
             (total-borrowed u0)
             (total-repaid u0)
             (loans-completed u0)
             (defaults u0)))
          (ok true))
        (err err-loan-exists)))))

;; Get borrower reputation (Fixed: Proper error handling)
(define-read-only (get-reputation (borrower principal))
  (match (map-get? borrowers ((borrower borrower)))
    borrower-data (ok (get reputation borrower-data))
    (err err-not-found)))

;; Get borrow limit (Enhanced: More sophisticated calculation)
(define-read-only (get-borrow-limit (borrower principal))
  (match (map-get? borrowers ((borrower borrower)))
    borrower-data
    (let ((reputation (get reputation borrower-data))
          (current-debt (get debt borrower-data)))
      (if (>= reputation reputation-threshold)
        (ok (- (+ default-limit (* reputation u50)) current-debt))
        (ok (- default-limit current-debt))))
    (err err-not-found)))

;; NEW: Lend money to the pool
(define-public (lend-to-pool (amount uint))
  (let ((lender tx-sender))
    (asserts! (> amount u0) (err err-invalid-amount))
    (try! (stx-transfer? amount lender (as-contract tx-sender)))
    (var-set total-pool (+ (var-get total-pool) amount))
    (map-set lenders ((lender lender))
      (merge (default-to 
        ((total-lent u0) (total-earned u0) (active-loans u0))
        (map-get? lenders ((lender lender))))
        ((total-lent (+ (default-to u0 (get total-lent (map-get? lenders ((lender lender))))) amount)))))
    (ok true)))

;; NEW: Borrow money
(define-public (borrow (amount uint))
  (let ((borrower tx-sender))
    (asserts! (> amount u0) (err err-invalid-amount))
    (asserts! (is-none (map-get? active-loans ((borrower borrower)))) (err err-loan-exists))
    
    ;; Check if borrower is registered
    (match (map-get? borrowers ((borrower borrower)))
      borrower-data
      (let ((borrow-limit (unwrap! (get-borrow-limit borrower) (err err-not-found)))
            (interest (/ (* amount interest-rate) u100))
            (due-block (+ block-height max-loan-duration)))
        
        (asserts! (<= amount borrow-limit) (err err-insufficient-funds))
        (asserts! (<= amount (var-get total-pool)) (err err-insufficient-funds))
        
        ;; Transfer funds to borrower
        (try! (as-contract (stx-transfer? amount tx-sender borrower)))
        
        ;; Update contract state
        (var-set total-pool (- (var-get total-pool) amount))
        (var-set total-outstanding (+ (var-get total-outstanding) amount))
        
        ;; Record active loan
        (map-set active-loans ((borrower borrower))
          ((amount amount)
           (interest interest)
           (due-block due-block)
           (loan-start block-height)))
        
        ;; Update borrower data
        (map-set borrowers ((borrower borrower))
          (merge borrower-data
            ((debt (+ (get debt borrower-data) amount))
             (total-borrowed (+ (get total-borrowed borrower-data) amount)))))
        
        (ok amount))
      (err err-not-found))))

;; NEW: Repay loan
(define-public (repay-loan)
  (let ((borrower tx-sender))
    (match (map-get? active-loans ((borrower borrower)))
      loan-data
      (let ((total-owed (+ (get amount loan-data) (get interest loan-data)))
            (is-overdue (> block-height (get due-block loan-data)))
            (late-fee (if is-overdue (/ (* total-owed late-fee-rate) u100) u0))
            (final-amount (+ total-owed late-fee)))
        
        ;; Transfer repayment
        (try! (stx-transfer? final-amount borrower (as-contract tx-sender)))
        
        ;; Update contract state
        (var-set total-pool (+ (var-get total-pool) final-amount))
        (var-set total-outstanding (- (var-get total-outstanding) (get amount loan-data)))
        
        ;; Update borrower reputation and data
        (match (map-get? borrowers ((borrower borrower)))
          borrower-data
          (let ((reputation-change (if is-overdue (- u0 u5) u10)))
            (map-set borrowers ((borrower borrower))
              (merge borrower-data
                ((reputation (+ (get reputation borrower-data) reputation-change))
                 (debt (- (get debt borrower-data) (get amount loan-data)))
                 (total-repaid (+ (get total-repaid borrower-data) final-amount))
                 (loans-completed (+ (get loans-completed borrower-data) u1))
                 (defaults (if is-overdue (+ (get defaults borrower-data) u1) (get defaults borrower-data)))))))
          (err err-not-found))
        
        ;; Remove active loan
        (map-delete active-loans ((borrower borrower)))
        
        (ok final-amount))
      (err err-no-active-loan))))

;; NEW: Get loan details
(define-read-only (get-loan-details (borrower principal))
  (match (map-get? active-loans ((borrower borrower)))
    loan-data
    (let ((is-overdue (> block-height (get due-block loan-data)))
          (total-owed (+ (get amount loan-data) (get interest loan-data)))
          (late-fee (if is-overdue (/ (* total-owed late-fee-rate) u100) u0)))
      (ok {
        amount: (get amount loan-data),
        interest: (get interest loan-data),
        due-block: (get due-block loan-data),
        is-overdue: is-overdue,
        late-fee: late-fee,
        total-owed: (+ total-owed late-fee)
      }))
    (err err-no-active-loan)))

;; NEW: Get borrower profile
(define-read-only (get-borrower-profile (borrower principal))
  (match (map-get? borrowers ((borrower borrower)))
    borrower-data
    (ok {
      reputation: (get reputation borrower-data),
      debt: (get debt borrower-data),
      total-borrowed: (get total-borrowed borrower-data),
      total-repaid: (get total-repaid borrower-data),
      loans-completed: (get loans-completed borrower-data),
      defaults: (get defaults borrower-data),
      borrow-limit: (unwrap-panic (get-borrow-limit borrower))
    })
    (err err-not-found)))

;; NEW: Get contract statistics
(define-read-only (get-contract-stats)
  (ok {
    total-pool: (var-get total-pool),
    total-outstanding: (var-get total-outstanding),
    available-liquidity: (var-get total-pool)
  }))

;; SECURITY: Emergency pause (only contract owner)
(define-data-var contract-paused bool false)

(define-public (pause-contract)
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set contract-paused true)
      (ok true))
    (err err-unauthorized)))

(define-public (unpause-contract)
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set contract-paused false)
      (ok true))
    (err err-unauthorized)))

;; SECURITY: Check if contract is paused
(define-read-only (is-paused)
  (var-get contract-paused))
