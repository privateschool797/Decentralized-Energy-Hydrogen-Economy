;; Hydrogen Producer Verification Contract
;; Validates and manages hydrogen generation facilities

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CAPACITY (err u103))

;; Data structures
(define-map producers
  { producer-id: principal }
  {
    facility-name: (string-ascii 64),
    location: (string-ascii 128),
    capacity-kg-per-day: uint,
    technology-type: (string-ascii 32),
    verified: bool,
    certification-date: uint,
    verifier: principal
  }
)

(define-map verifiers
  { verifier-id: principal }
  { authorized: bool, verification-count: uint }
)

;; Authorization functions
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set verifiers { verifier-id: verifier } { authorized: true, verification-count: u0 }))
  )
)

;; Producer registration
(define-public (register-producer
  (facility-name (string-ascii 64))
  (location (string-ascii 128))
  (capacity-kg-per-day uint)
  (technology-type (string-ascii 32))
)
  (begin
    (asserts! (> capacity-kg-per-day u0) ERR_INVALID_CAPACITY)
    (asserts! (is-none (map-get? producers { producer-id: tx-sender })) ERR_ALREADY_VERIFIED)
    (ok (map-set producers
      { producer-id: tx-sender }
      {
        facility-name: facility-name,
        location: location,
        capacity-kg-per-day: capacity-kg-per-day,
        technology-type: technology-type,
        verified: false,
        certification-date: u0,
        verifier: CONTRACT_OWNER
      }
    ))
  )
)

;; Verification process
(define-public (verify-producer (producer principal))
  (let (
    (verifier-info (unwrap! (map-get? verifiers { verifier-id: tx-sender }) ERR_UNAUTHORIZED))
    (producer-info (unwrap! (map-get? producers { producer-id: producer }) ERR_NOT_FOUND))
  )
    (asserts! (get authorized verifier-info) ERR_UNAUTHORIZED)
    (map-set producers
      { producer-id: producer }
      (merge producer-info {
        verified: true,
        certification-date: block-height,
        verifier: tx-sender
      })
    )
    (map-set verifiers
      { verifier-id: tx-sender }
      (merge verifier-info { verification-count: (+ (get verification-count verifier-info) u1) })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-producer-info (producer principal))
  (map-get? producers { producer-id: producer })
)

(define-read-only (is-verified-producer (producer principal))
  (match (map-get? producers { producer-id: producer })
    producer-data (get verified producer-data)
    false
  )
)

(define-read-only (get-verifier-info (verifier principal))
  (map-get? verifiers { verifier-id: verifier })
)
