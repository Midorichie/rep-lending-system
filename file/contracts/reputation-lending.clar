(define-map borrowers
  ((borrower principal))
  ((reputation uint) (debt uint)))

(define-constant default-limit u1000)

(define-public (register-borrower (borrower principal))
  (begin
    (map-set borrowers ((borrower borrower))
      ((reputation u0) (debt u0)))
    (ok true)))

(define-public (get-reputation (borrower principal))
  (match (map-get borrowers ((borrower borrower)))
    borrower-data
    (ok (get reputation borrower-data))
    (err u404)))

(define-public (get-borrow-limit (borrower principal))
  (match (map-get borrowers ((borrower borrower)))
    borrower-data
    (ok (+ default-limit (* (get reputation borrower-data) u10)))
    (err u404)))
