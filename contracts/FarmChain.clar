;; FarmChain: Decentralized Agricultural Supply Chain Platform
;; Version: 1.0.0

(define-data-var supply-coordinator principal tx-sender)
(define-data-var harvest-inventory uint u0)
(define-data-var quality-score-rate uint u85) ;; quality points per harvest cycle
(define-data-var last-quality-assessment uint u0) ;; last block when quality was assessed

(define-map farmer-harvests principal uint)

;; Helper function to ensure only the supply coordinator can perform certain actions
(define-private (is-coordinator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get supply-coordinator)) (err u300))
    (ok true)))

;; Initialize the agricultural supply platform
(define-public (establish-supply-chain (coordinator principal))
  (begin
    (asserts! (is-none (map-get? farmer-harvests coordinator)) (err u301))
    (var-set supply-coordinator coordinator)
    (ok "FarmChain supply network established")))

;; Record harvest production
(define-public (record-harvest (bushels uint))
  (begin
    (asserts! (> bushels u0) (err u302))
    (let ((current-harvest (default-to u0 (map-get? farmer-harvests tx-sender))))
      (map-set farmer-harvests tx-sender (+ current-harvest bushels))
      (var-set harvest-inventory (+ (var-get harvest-inventory) bushels))
      (ok (+ current-harvest bushels)))))

;; Assess quality scores for all farmers
(define-public (assess-crop-quality)
  (begin
    (try! (is-coordinator tx-sender))
    (let ((current-block stacks-block-height)
          (previous-assessment (var-get last-quality-assessment)))
      (asserts! (> current-block previous-assessment) (err u303))
      ;; Calculate quality based on blocks elapsed
      (let ((elapsed (- current-block previous-assessment))
            (total-quality (* elapsed (var-get quality-score-rate))))
        (var-set last-quality-assessment current-block)
        (var-set harvest-inventory (+ (var-get harvest-inventory) total-quality))
        (ok total-quality)))))

;; Distribute harvest and claim quality premiums
(define-public (distribute-harvest-premium)
  (begin
    (let ((farmer-production (default-to u0 (map-get? farmer-harvests tx-sender))))
      (asserts! (> farmer-production u0) (err u304))
      (let ((total-inventory (var-get harvest-inventory))
            (new-quality (* (var-get quality-score-rate) (- stacks-block-height (var-get last-quality-assessment))))
            (production-ratio (/ (* farmer-production u100000) total-inventory)))
        ;; Calculate premium based on production ratio
        (let ((premium-amount (/ (* production-ratio new-quality) u100000)))
          (map-delete farmer-harvests tx-sender)
          (var-set harvest-inventory (- (var-get harvest-inventory) farmer-production))
          (ok (+ farmer-production premium-amount)))))))

;; Read-only functions
(define-read-only (get-farmer-harvest (farmer principal))
  (default-to u0 (map-get? farmer-harvests farmer)))

(define-read-only (get-supply-stats)
  {
    coordinator: (var-get supply-coordinator),
    total-inventory: (var-get harvest-inventory),
    quality-rate: (var-get quality-score-rate),
    last-assessment: (var-get last-quality-assessment)
  })

(define-read-only (get-harvest-inventory)
  (var-get harvest-inventory))