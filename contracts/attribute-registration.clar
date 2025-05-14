;; Attribute Registration Contract
;; Records identity claims

(define-data-var admin principal tx-sender)

;; Structure for identity attributes
(define-map identity-attributes
  { owner: principal, attribute-id: (string-ascii 64) }
  {
    issuer: principal,
    value-hash: (buff 32),
    timestamp: uint,
    expiration: uint
  }
)

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-attribute-exists (err u102))
(define-constant err-attribute-not-found (err u103))

;; Register a new attribute
(define-public (register-attribute
    (owner principal)
    (attribute-id (string-ascii 64))
    (value-hash (buff 32))
    (expiration uint))
  (let ((key { owner: owner, attribute-id: attribute-id }))
    (begin
      ;; Only the owner or an admin can register attributes
      (asserts! (or (is-eq tx-sender owner) (is-eq tx-sender (var-get admin))) err-not-authorized)
      (asserts! (is-none (map-get? identity-attributes key)) err-attribute-exists)
      (ok (map-set identity-attributes
        key
        {
          issuer: tx-sender,
          value-hash: value-hash,
          timestamp: block-height,
          expiration: expiration
        }
      ))
    )
  )
)

;; Update an existing attribute
(define-public (update-attribute
    (owner principal)
    (attribute-id (string-ascii 64))
    (value-hash (buff 32))
    (expiration uint))
  (let ((key { owner: owner, attribute-id: attribute-id }))
    (begin
      ;; Only the owner or an admin can update attributes
      (asserts! (or (is-eq tx-sender owner) (is-eq tx-sender (var-get admin))) err-not-authorized)
      (asserts! (is-some (map-get? identity-attributes key)) err-attribute-not-found)
      (ok (map-set identity-attributes
        key
        {
          issuer: tx-sender,
          value-hash: value-hash,
          timestamp: block-height,
          expiration: expiration
        }
      ))
    )
  )
)

;; Get attribute details
(define-read-only (get-attribute (owner principal) (attribute-id (string-ascii 64)))
  (map-get? identity-attributes { owner: owner, attribute-id: attribute-id }))

;; Check if attribute is valid (not expired)
(define-read-only (is-attribute-valid (owner principal) (attribute-id (string-ascii 64)))
  (match (map-get? identity-attributes { owner: owner, attribute-id: attribute-id })
    attribute (< block-height (get expiration attribute))
    false
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (ok (var-set admin new-admin))))
