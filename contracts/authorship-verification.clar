;; Authorship Verification Contract for Versebit
;; Proof-of-authorship verification, content hashing, and dispute resolution

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_VERIFICATION_NOT_FOUND (err u201))
(define-constant ERR_VERIFICATION_ALREADY_EXISTS (err u202))
(define-constant ERR_INVALID_CONTENT_HASH (err u203))
(define-constant ERR_INVALID_PROOF_TYPE (err u204))
(define-constant ERR_VERIFICATION_EXPIRED (err u205))
(define-constant ERR_DISPUTE_NOT_FOUND (err u206))
(define-constant ERR_DISPUTE_ALREADY_EXISTS (err u207))
(define-constant ERR_INVALID_DISPUTE_STATUS (err u208))
(define-constant ERR_NOT_AUTHORIZED_VALIDATOR (err u209))
(define-constant ERR_PLAGIARISM_DETECTED (err u210))
(define-constant ERR_INVALID_TIMESTAMP (err u211))

;; Data Variables
(define-data-var verification-paused bool false)
(define-data-var total-verifications uint u0)
(define-data-var total-disputes uint u0)
(define-data-var verification-fee uint u500000) ;; 0.5 STX in microSTX
(define-data-var verification-validity-period uint u8640000) ;; 100 days in blocks
(define-data-var minimum-proof-score uint u70)

;; Data Maps
;; Content verification records
(define-map content-verifications (buff 32) {
    content-hash: (buff 32),
    author: principal,
    verification-timestamp: uint,
    proof-type: (string-ascii 30),
    verification-score: uint,
    status: (string-ascii 20),
    expiry-timestamp: uint,
    metadata-hash: (buff 32),
    validator: principal,
    verification-method: (string-ascii 50)
})

;; Plagiarism detection records
(define-map plagiarism-reports uint {
    reported-content-hash: (buff 32),
    original-content-hash: (buff 32),
    reporter: principal,
    accused-author: principal,
    original-author: principal,
    report-timestamp: uint,
    similarity-score: uint,
    status: (string-ascii 20),
    evidence-uri: (optional (string-ascii 200)),
    resolution-notes: (string-ascii 500)
})

;; Authorized validators
(define-map authorized-validators principal {
    active: bool,
    specialization: (string-ascii 100),
    validation-count: uint,
    reputation-score: uint,
    authorization-timestamp: uint,
    validator-type: (string-ascii 30)
})

;; Authorship disputes
(define-map authorship-disputes uint {
    content-hash: (buff 32),
    claimant: principal,
    disputed-author: principal,
    dispute-reason: (string-ascii 300),
    submitted-timestamp: uint,
    dispute-status: (string-ascii 20),
    evidence-hash: (buff 32),
    resolver: (optional principal),
    resolution-timestamp: (optional uint),
    resolution-outcome: (string-ascii 100)
})

;; Content authenticity scores
(define-map authenticity-scores (buff 32) {
    base-score: uint,
    timestamp-score: uint,
    validator-score: uint,
    community-score: uint,
    final-score: uint,
    last-updated: uint
})

;; Proof submission history
(define-map proof-submissions principal {
    total-submissions: uint,
    verified-submissions: uint,
    disputed-submissions: uint,
    reputation-impact: uint,
    last-submission: uint
})

;; Admin permissions
(define-map admins principal bool)

;; Content hash collision tracking
(define-map hash-registry (buff 32) {
    first-submission: uint,
    first-author: principal,
    collision-count: uint,
    flagged-for-review: bool
})

;; Initialize contract
(map-set admins CONTRACT_OWNER true)

;; Read-only functions
(define-read-only (get-content-verification (content-hash (buff 32)))
    (map-get? content-verifications content-hash))

(define-read-only (get-plagiarism-report (report-id uint))
    (map-get? plagiarism-reports report-id))

(define-read-only (get-authorship-dispute (dispute-id uint))
    (map-get? authorship-disputes dispute-id))

(define-read-only (get-authenticity-score (content-hash (buff 32)))
    (map-get? authenticity-scores content-hash))

(define-read-only (is-admin (user principal))
    (default-to false (map-get? admins user)))

(define-read-only (is-authorized-validator (validator principal))
    (match (map-get? authorized-validators validator)
        validator-data (get active validator-data)
        false))

(define-read-only (get-validator-info (validator principal))
    (map-get? authorized-validators validator))

(define-read-only (verify-content-authenticity (content-hash (buff 32)) (author principal))
    (match (get-content-verification content-hash)
        verification-data 
        (and 
            (is-eq (get author verification-data) author)
            (is-eq (get status verification-data) "verified")
            (> (get expiry-timestamp verification-data) stacks-block-height))
        false))

(define-read-only (check-plagiarism-risk (content-hash (buff 32)))
    (let (
        (hash-info (map-get? hash-registry content-hash))
        (verification-info (get-content-verification content-hash))
    )
    (and 
        (is-some hash-info)
        (> (get collision-count (unwrap-panic hash-info)) u1))))

(define-read-only (get-proof-submission-history (author principal))
    (default-to 
        { total-submissions: u0, verified-submissions: u0, disputed-submissions: u0, 
          reputation-impact: u0, last-submission: u0 }
        (map-get? proof-submissions author)))

(define-read-only (calculate-verification-score 
    (timestamp-age uint) 
    (validator-reputation uint) 
    (content-uniqueness uint))
    (let (
        (age-score (if (< timestamp-age u144) u30 u10)) ;; Bonus for recent submissions (within 1 day)
        (validator-score (/ (* validator-reputation u40) u100))
        (uniqueness-score (if (> content-uniqueness u90) u30 u20))
    )
    (+ age-score validator-score uniqueness-score)))

;; Administrative functions
(define-public (add-admin (new-admin principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (map-set admins new-admin true))))

(define-public (remove-admin (admin principal))
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq admin CONTRACT_OWNER)) ERR_UNAUTHORIZED)
        (ok (map-delete admins admin))))

(define-public (pause-verification)
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (var-set verification-paused true))))

(define-public (unpause-verification)
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (var-set verification-paused false))))

(define-public (update-verification-fee (new-fee uint))
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (var-set verification-fee new-fee))))

(define-public (update-minimum-proof-score (new-score uint))
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (<= new-score u100) ERR_INVALID_PROOF_TYPE)
        (ok (var-set minimum-proof-score new-score))))

;; Validator management functions
(define-public (authorize-validator 
    (validator principal) 
    (specialization (string-ascii 100)) 
    (validator-type (string-ascii 30)))
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        
        (map-set authorized-validators validator {
            active: true,
            specialization: specialization,
            validation-count: u0,
            reputation-score: u100,
            authorization-timestamp: stacks-block-height,
            validator-type: validator-type
        })
        
        (ok true)))

(define-public (deauthorize-validator (validator principal))
    (let (
        (validator-data (unwrap! (map-get? authorized-validators validator) ERR_NOT_AUTHORIZED_VALIDATOR))
    )
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        
        (map-set authorized-validators validator 
            (merge validator-data { active: false }))
        
        (ok true))))

;; Core verification functions
(define-public (submit-proof-of-authorship 
    (content-hash (buff 32)) 
    (proof-type (string-ascii 30))
    (metadata-hash (buff 32))
    (verification-method (string-ascii 50)))
    (let (
        (verification-cost (var-get verification-fee))
        (current-timestamp stacks-block-height)
        (expiry-timestamp (+ current-timestamp (var-get verification-validity-period)))
        (current-submissions (get-proof-submission-history tx-sender))
    )
    (begin
        (asserts! (not (var-get verification-paused)) ERR_VERIFICATION_EXPIRED)
        (asserts! (> (len content-hash) u0) ERR_INVALID_CONTENT_HASH)
        (asserts! (is-none (get-content-verification content-hash)) ERR_VERIFICATION_ALREADY_EXISTS)
        
        ;; Pay verification fee
        (if (> verification-cost u0)
            (try! (stx-transfer? verification-cost tx-sender (as-contract tx-sender)))
            true)
        
        ;; Update hash registry
        (match (map-get? hash-registry content-hash)
            existing-hash 
            (map-set hash-registry content-hash 
                (merge existing-hash {
                    collision-count: (+ (get collision-count existing-hash) u1),
                    flagged-for-review: true
                }))
            (map-set hash-registry content-hash {
                first-submission: current-timestamp,
                first-author: tx-sender,
                collision-count: u1,
                flagged-for-review: false
            }))
        
        ;; Create verification record
        (map-set content-verifications content-hash {
            content-hash: content-hash,
            author: tx-sender,
            verification-timestamp: current-timestamp,
            proof-type: proof-type,
            verification-score: u0,
            status: "pending",
            expiry-timestamp: expiry-timestamp,
            metadata-hash: metadata-hash,
            validator: tx-sender, ;; Self-submitted initially
            verification-method: verification-method
        })
        
        ;; Update submission history
        (map-set proof-submissions tx-sender 
            (merge current-submissions {
                total-submissions: (+ (get total-submissions current-submissions) u1),
                last-submission: current-timestamp
            }))
        
        (var-set total-verifications (+ (var-get total-verifications) u1))
        (ok content-hash))))

(define-public (validate-authorship 
    (content-hash (buff 32)) 
    (verification-score uint) 
    (validation-notes (string-ascii 200)))
    (let (
        (verification-data (unwrap! (get-content-verification content-hash) ERR_VERIFICATION_NOT_FOUND))
        (validator-data (unwrap! (map-get? authorized-validators tx-sender) ERR_NOT_AUTHORIZED_VALIDATOR))
        (minimum-score (var-get minimum-proof-score))
        (final-status (if (>= verification-score minimum-score) "verified" "rejected"))
    )
    (begin
        (asserts! (get active validator-data) ERR_NOT_AUTHORIZED_VALIDATOR)
        (asserts! (not (var-get verification-paused)) ERR_VERIFICATION_EXPIRED)
        (asserts! (is-eq (get status verification-data) "pending") ERR_VERIFICATION_ALREADY_EXISTS)
        (asserts! (<= verification-score u100) ERR_INVALID_PROOF_TYPE)
        
        ;; Update verification record
        (map-set content-verifications content-hash 
            (merge verification-data {
                verification-score: verification-score,
                status: final-status,
                validator: tx-sender
            }))
        
        ;; Update validator statistics
        (map-set authorized-validators tx-sender 
            (merge validator-data {
                validation-count: (+ (get validation-count validator-data) u1)
            }))
        
        ;; Update author's submission history
        (let (
            (author-submissions (get-proof-submission-history (get author verification-data)))
        )
        (map-set proof-submissions (get author verification-data)
            (merge author-submissions {
                verified-submissions: (if (is-eq final-status "verified") 
                    (+ (get verified-submissions author-submissions) u1)
                    (get verified-submissions author-submissions))
            })))
        
        ;; Calculate and store authenticity score
        (let (
            (timestamp-age (- stacks-block-height (get verification-timestamp verification-data)))
            (validator-reputation (get reputation-score validator-data))
            (uniqueness-score (if (check-plagiarism-risk content-hash) u50 u95))
            (calculated-score (calculate-verification-score timestamp-age validator-reputation uniqueness-score))
        )
        (map-set authenticity-scores content-hash {
            base-score: verification-score,
            timestamp-score: (if (< timestamp-age u144) u30 u10),
            validator-score: (/ (* validator-reputation u40) u100),
            community-score: uniqueness-score,
            final-score: calculated-score,
            last-updated: stacks-block-height
        }))
        
        (ok final-status))))

;; Plagiarism reporting and detection
(define-public (report-plagiarism 
    (reported-content-hash (buff 32)) 
    (original-content-hash (buff 32))
    (accused-author principal)
    (similarity-score uint)
    (evidence-uri (optional (string-ascii 200))))
    (let (
        (report-id (var-get total-disputes))
        (reported-verification (get-content-verification reported-content-hash))
        (original-verification (get-content-verification original-content-hash))
    )
    (begin
        (asserts! (is-some reported-verification) ERR_VERIFICATION_NOT_FOUND)
        (asserts! (is-some original-verification) ERR_VERIFICATION_NOT_FOUND)
        (asserts! (<= similarity-score u100) ERR_INVALID_PROOF_TYPE)
        (asserts! (>= similarity-score u75) ERR_PLAGIARISM_DETECTED) ;; Minimum 75% similarity to report
        
        (map-set plagiarism-reports report-id {
            reported-content-hash: reported-content-hash,
            original-content-hash: original-content-hash,
            reporter: tx-sender,
            accused-author: accused-author,
            original-author: (get author (unwrap-panic original-verification)),
            report-timestamp: stacks-block-height,
            similarity-score: similarity-score,
            status: "pending-review",
            evidence-uri: evidence-uri,
            resolution-notes: ""
        })
        
        (var-set total-disputes (+ report-id u1))
        (ok report-id))))

(define-public (resolve-plagiarism-report 
    (report-id uint) 
    (resolution (string-ascii 20)) 
    (resolution-notes (string-ascii 500)))
    (let (
        (report-data (unwrap! (map-get? plagiarism-reports report-id) ERR_DISPUTE_NOT_FOUND))
    )
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status report-data) "pending-review") ERR_INVALID_DISPUTE_STATUS)
        
        (map-set plagiarism-reports report-id 
            (merge report-data {
                status: resolution,
                resolution-notes: resolution-notes
            }))
        
        ;; If plagiarism is confirmed, update verification status
        (if (is-eq resolution "plagiarism-confirmed")
            (match (get-content-verification (get reported-content-hash report-data))
                verification-data 
                (map-set content-verifications (get reported-content-hash report-data)
                    (merge verification-data {
                        status: "revoked",
                        verification-score: u0
                    }))
                false)
            true)
        
        (ok resolution))))

;; Authorship dispute system
(define-public (submit-authorship-dispute 
    (content-hash (buff 32)) 
    (disputed-author principal) 
    (dispute-reason (string-ascii 300))
    (evidence-hash (buff 32)))
    (let (
        (dispute-id (var-get total-disputes))
        (verification-data (unwrap! (get-content-verification content-hash) ERR_VERIFICATION_NOT_FOUND))
    )
    (begin
        (asserts! (not (is-eq tx-sender disputed-author)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status verification-data) "verified") ERR_VERIFICATION_NOT_FOUND)
        
        (map-set authorship-disputes dispute-id {
            content-hash: content-hash,
            claimant: tx-sender,
            disputed-author: disputed-author,
            dispute-reason: dispute-reason,
            submitted-timestamp: stacks-block-height,
            dispute-status: "open",
            evidence-hash: evidence-hash,
            resolver: none,
            resolution-timestamp: none,
            resolution-outcome: ""
        })
        
        (var-set total-disputes (+ dispute-id u1))
        (ok dispute-id))))

(define-public (resolve-authorship-dispute 
    (dispute-id uint) 
    (outcome (string-ascii 100))
    (resolution-notes (string-ascii 200)))
    (let (
        (dispute-data (unwrap! (map-get? authorship-disputes dispute-id) ERR_DISPUTE_NOT_FOUND))
    )
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get dispute-status dispute-data) "open") ERR_INVALID_DISPUTE_STATUS)
        
        (map-set authorship-disputes dispute-id 
            (merge dispute-data {
                dispute-status: "resolved",
                resolver: (some tx-sender),
                resolution-timestamp: (some stacks-block-height),
                resolution-outcome: outcome
            }))
        
        ;; Update verification based on resolution
        (if (is-eq outcome "claimant-wins")
            (match (get-content-verification (get content-hash dispute-data))
                verification-data 
                (map-set content-verifications (get content-hash dispute-data)
                    (merge verification-data {
                        author: (get claimant dispute-data),
                        status: "transferred"
                    }))
                false)
            true)
        
        (ok outcome))))

