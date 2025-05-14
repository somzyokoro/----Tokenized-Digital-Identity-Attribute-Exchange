;; Consent Management Contract
;; Controls data sharing

(define-data-var admin principal tx-sender)

;; Structure for consent records
(define-map consent-records
  { owner: principal, accessor: principal, attribute-id: (string-ascii 64) }
  {
    granted: bool,
    expiration: uint,
    timestamp: uint
  }
)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-not-authorized (err u101))

;; Grant consent for an attribute
(define-public (grant-consent
    (accessor principal)
    (attribute-id (string-ascii 64))
    (expiration uint))
  (let ((key { owner: tx-sender, accessor: accessor, attribute-id: attribute-id }))
    (ok (map-set consent-records
      key
      {
        granted: true,
        expiration: expiration,
        timestamp: block-height
      }
    ))
  )
)

;; Revoke consent for an attribute
(define-public (revoke-consent
    (accessor principal)
    (attribute-id (string-ascii 64)))
  (let ((key { owner: tx-sender, accessor: accessor, attribute-id: attribute-id }))
    (ok (map-set consent-records
      key
      {
        granted: false,
        expiration: u0,
        timestamp: block-height
      }
    ))
  )
)

;; Check if consent is granted
(define-read-only (check-consent (owner principal) (accessor principal) (attribute-id (string-ascii 64)))
  (match (map-get? consent-records { owner: owner, accessor: accessor, attribute-id: attribute-id })
    consent (and (get granted consent) (> (get expiration consent) block-height))
    false
  )
)

;; Get consent details
(define-read-only (get-consent (owner principal) (accessor principal) (attribute-id (string-ascii 64)))
  (map-get? consent-records { owner: owner, accessor: accessor, attribute-id: attribute-id }))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (ok (var-set admin new-admin))))
