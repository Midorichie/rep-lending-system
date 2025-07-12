;; Reputation Oracle Contract
;; External reputation verification and cross-platform integration

;; Error constants
(define-constant err-unauthorized u403)
(define-constant err-not-found u404)
(define-constant err-invalid-score u405)
(define-constant err-oracle-exists u406)
(define-constant err-stale-data u407)

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant max-reputation u1000)
(define-constant data-validity-period u1008) ;; ~1 week in blocks

;; Oracle data sources
(define-map reputation-oracles
  ((oracle-id uint))
  ((oracle-name (string-ascii 50))
   (oracle-address principal)
   (is-active bool)
   (reputation-weight uint))) ;; Weight in final reputation calculation

(define-map external-reputations
  ((user principal) (oracle-id uint))
  ((reputation-score uint)
   (last-updated uint)
   (verification-count uint)
   (data-hash (buff 32))))

(define-map aggregated-reputation
  ((user principal))
  ((weighted-score uint)
   (last-calculated uint)
   (source-count uint)))

;; Oracle management
(define-data-var next-oracle-id uint u1)
(define-data-var total-oracles uint u0)

;; Public functions

;; Register a new oracle (owner only) - Fixed: Proper structure
(define-public (register-oracle (oracle-name (string-ascii 50)) (oracle-address principal) (weight uint))
  (begin
    (if (is-eq tx-sender contract-owner)
      (if (<= weight u100)
        (let ((oracle-id (var-get next-oracle-id)))
          (map-set reputation-oracles ((oracle-id oracle-id))
            ((oracle-name oracle-name)
             (oracle-address oracle-address)
             (is-active true)
             (reputation-weight weight)))
          
          (var-set next-oracle-id (+ oracle-id u1))
          (var-set total-oracles (+ (var-get total-oracles) u1))
          
          (ok oracle-id))
        (err err-invalid-score))
      (err err-unauthorized))))

;; Submit reputation data (oracle only)
(define-public (submit-reputation (user principal) (oracle-id uint) (score uint) (data-hash (buff 32)))
  (match (map-get? reputation-oracles ((oracle-id oracle-id)))
    oracle-data
    (if (is-eq tx-sender (get oracle-address oracle-data))
      (if (get is-active oracle-data)
        (if (<= score max-reputation)
          (begin
            (map-set external-reputations ((user user) (oracle-id oracle-id))
              ((reputation-score score)
               (last-updated block-height)
               (verification-count (+ u1 (default-to u0 (get verification-count (map-get? external-reputations ((user user) (oracle-id oracle-id)))))))
               (data-hash data-hash)))
            
            (try! (calculate-aggregated-reputation user))
            (ok true))
          (err err-invalid-score))
        (err err-unauthorized))
      (err err-unauthorized))
    (err err-not-found)))

;; Calculate weighted reputation score
(define-private (calculate-aggregated-reputation (user principal))
  (let ((oracle-count (var-get total-oracles)))
    (if (> oracle-count u0)
      (begin
        (let ((weighted-sum (fold calculate-weighted-score-for-user (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) {user: user, acc: u0}))
              (total-weight (fold get-oracle-weight (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0))
              (final-score (if (> total-weight u0) (/ (get acc weighted-sum) total-weight) u0)))
          
          (map-set aggregated-reputation ((user user))
            ((weighted-score final-score)
             (last-calculated block-height)
             (source-count oracle-count)))
          
          (ok final-score)))
      (ok u0))))

;; Helper function for weighted score calculation
(define-private (calculate-weighted-score-for-user (oracle-id uint) (data {user: principal, acc: uint}))
  (let ((user (get user data))
        (acc (get acc data)))
    (match (map-get? reputation-oracles ((oracle-id oracle-id)))
      oracle-data
      (if (get is-active oracle-data)
        (match (map-get? external-reputations ((user user) (oracle-id oracle-id)))
          reputation-data
          (if (< (- block-height (get last-updated reputation-data)) data-validity-period)
            {user: user, acc: (+ acc (* (get reputation-score reputation-data) (get reputation-weight oracle-data)))}
            {user: user, acc: acc})
          {user: user, acc: acc})
        {user: user, acc: acc})
      {user: user, acc: acc})))

;; Helper function for total weight calculation
(define-private (get-oracle-weight (oracle-id uint) (acc uint))
  (match (map-get? reputation-oracles ((oracle-id oracle-id)))
    oracle-data
    (if (get is-active oracle-data)
      (+ acc (get reputation-weight oracle-data))
      acc)
    acc))

;; Read-only functions

;; Get aggregated reputation
(define-read-only (get-aggregated-reputation (user principal))
  (match (map-get? aggregated-reputation ((user user)))
    reputation-data
    (if (< (- block-height (get last-calculated reputation-data)) data-validity-period)
      (ok (get weighted-score reputation-data))
      (err err-stale-data))
    (err err-not-found)))

;; Get oracle reputation data
(define-read-only (get-oracle-reputation (user principal) (oracle-id uint))
  (match (map-get? external-reputations ((user user) (oracle-id oracle-id)))
    reputation-data
    (ok reputation-data)
    (err err-not-found)))

;; Get oracle info
(define-read-only (get-oracle-info (oracle-id uint))
  (match (map-get? reputation-oracles ((oracle-id oracle-id)))
    oracle-data
    (ok oracle-data)
    (err err-not-found)))

;; List all active oracles
(define-read-only (get-active-oracles)
  (ok (var-get total-oracles)))

;; Admin functions

;; Deactivate oracle
(define-public (deactivate-oracle (oracle-id uint))
  (if (is-eq tx-sender contract-owner)
    (match (map-get? reputation-oracles ((oracle-id oracle-id)))
      oracle-data
      (begin
        (map-set reputation-oracles ((oracle-id oracle-id))
          (merge oracle-data ((is-active false))))
        (ok true))
      (err err-not-found))
    (err err-unauthorized)))

;; Update oracle weight
(define-public (update-oracle-weight (oracle-id uint) (new-weight uint))
  (if (is-eq tx-sender contract-owner)
    (if (<= new-weight u100)
      (match (map-get? reputation-oracles ((oracle-id oracle-id)))
        oracle-data
        (begin
          (map-set reputation-oracles ((oracle-id oracle-id))
            (merge oracle-data ((reputation-weight new-weight))))
          (ok true))
        (err err-not-found))
      (err err-invalid-score))
    (err err-unauthorized)))
