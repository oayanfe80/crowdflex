;; --------------------------------------------------
;; Contract: CrowdFlex
;; Purpose: Flexible decentralized crowdfunding with enhanced controls
;; --------------------------------------------------

;; Error codes
(define-constant ERR_DEADLINE_PASSED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_GOAL_NOT_MET (err u103))
(define-constant ERR_ALREADY_CLAIMED (err u104))
(define-constant ERR_NOTHING_TO_REFUND (err u105))

(define-data-var next-campaign-id uint u0)
(define-data-var contract-admin principal tx-sender)

(define-map campaigns
  uint
  (tuple
    (creator principal)
    (goal uint)
    (deadline uint)
    (raised uint)
    (claimed bool)
    (active bool)
  )
)

(define-map contributions
  (tuple (campaign-id uint) (user principal))
  uint
)

;; === Create campaign ===
(define-public (create-campaign (goal uint) (duration uint))
  (let ((id (var-get next-campaign-id))
        (deadline (+ stacks-block-height duration)))
    (begin
      (map-set campaigns id {
        creator: tx-sender,
        goal: goal,
        deadline: deadline,
        raised: u0,
        claimed: false,
        active: true
      })
      (var-set next-campaign-id (+ id u1))
      (ok id)
    )
  )
)

;; === Contribute ===
(define-public (contribute (id uint) (amount uint))
  (match (map-get? campaigns id)
    c
    (begin
      (asserts! (get active c) (err u106))
      (asserts! (< stacks-block-height (get deadline c)) ERR_DEADLINE_PASSED)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (let ((prev (default-to u0 (map-get? contributions { campaign-id: id, user: tx-sender }))))
        (map-set contributions { campaign-id: id, user: tx-sender } (+ prev amount))
        (map-set campaigns id (merge c { raised: (+ (get raised c) amount) }))
        (ok true)
      )
    )
    ERR_NOT_FOUND
  )
)

;; === Claim funds ===
(define-public (claim-funds (id uint))
  (match (map-get? campaigns id)
    c
    (begin
      (asserts! (is-eq tx-sender (get creator c)) ERR_UNAUTHORIZED)
      (asserts! (>= (get raised c) (get goal c)) ERR_GOAL_NOT_MET)
      (asserts! (not (get claimed c)) ERR_ALREADY_CLAIMED)
      (map-set campaigns id (merge c { claimed: true }))
      (stx-transfer? (get raised c) (as-contract tx-sender) (get creator c))
    )
    ERR_NOT_FOUND
  )
)

;; === Refund ===
(define-public (get-refund (id uint))
  (match (map-get? campaigns id)
    c
    (begin
      (asserts! (>= stacks-block-height (get deadline c)) ERR_DEADLINE_PASSED)
      (asserts! (< (get raised c) (get goal c)) ERR_GOAL_NOT_MET)
      (let ((amt (default-to u0 (map-get? contributions { campaign-id: id, user: tx-sender }))))
        (asserts! (> amt u0) ERR_NOTHING_TO_REFUND)
        (map-delete contributions { campaign-id: id, user: tx-sender })
        (stx-transfer? amt (as-contract tx-sender) tx-sender)
      )
    )
    ERR_NOT_FOUND
  )
)

;; === Cancel campaign ===
(define-public (cancel-campaign (id uint))
  (match (map-get? campaigns id)
    c
    (begin
      (asserts! (is-eq tx-sender (get creator c)) ERR_UNAUTHORIZED)
      (asserts! (get active c) (err u107))
      (map-set campaigns id (merge c { active: false }))
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; === Extend campaign ===
(define-public (extend-deadline (id uint) (extra uint))
  (match (map-get? campaigns id)
    c
    (begin
      (asserts! (is-eq tx-sender (get creator c)) ERR_UNAUTHORIZED)
      (asserts! (get active c) (err u107))
      (map-set campaigns id (merge c { deadline: (+ (get deadline c) extra) }))
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; === Admin remove ===
(define-public (admin-remove (id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (map-delete campaigns id)
    (ok true)
  )
)

;; === Admin transfer ===
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

;; === Get campaign ===
(define-read-only (get-campaign (id uint))
  (ok (map-get? campaigns id))
)

;; === Get contribution ===
(define-read-only (get-contribution (id uint) (user principal))
  (ok (map-get? contributions { campaign-id: id, user: user }))
)

;; === Get campaign count ===
(define-read-only (get-campaign-count)
  (ok (var-get next-campaign-id))
)
