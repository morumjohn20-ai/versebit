;; Poetry Registry Contract for Versebit
;; Core NFT minting, ownership tracking, and metadata management for poetry

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_POEM_NOT_FOUND (err u101))
(define-constant ERR_POEM_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_TITLE (err u103))
(define-constant ERR_INVALID_CONTENT_HASH (err u104))
(define-constant ERR_NOT_POEM_OWNER (err u105))
(define-constant ERR_TRANSFER_FAILED (err u106))
(define-constant ERR_INVALID_ROYALTY (err u107))
(define-constant ERR_COLLECTION_NOT_FOUND (err u108))
(define-constant ERR_COLLECTION_ALREADY_EXISTS (err u109))
(define-constant ERR_POEM_BURNED (err u110))
(define-constant ERR_INVALID_PRICE (err u111))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u112))

;; Data Variables
(define-data-var next-poem-id uint u1)
(define-data-var next-collection-id uint u1)
(define-data-var total-poems uint u0)
(define-data-var total-collections uint u0)
(define-data-var contract-paused bool false)
(define-data-var minting-fee uint u1000000) ;; 1 STX in microSTX

;; NFT Definition
(define-non-fungible-token poetry-nft uint)

;; Data Maps
;; Poem metadata and ownership
(define-map poems uint {
    title: (string-ascii 100),
    content-hash: (buff 32),
    author: principal,
    creation-timestamp: uint,
    genre: (string-ascii 50),
    language: (string-ascii 20),
    word-count: uint,
    line-count: uint,
    collection-id: (optional uint),
    royalty-percentage: uint,
    license-type: (string-ascii 30),
    is-burned: bool,
    metadata-uri: (optional (string-ascii 200))
})

;; Poet profiles and statistics
(define-map poet-profiles principal {
    display-name: (string-ascii 50),
    bio: (string-ascii 500),
    poems-created: uint,
    collections-created: uint,
    total-royalties-earned: uint,
    reputation-score: uint,
    verified-poet: bool,
    social-links: (string-ascii 200)
})

;; Poetry collections
(define-map collections uint {
    name: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    creation-timestamp: uint,
    poem-count: uint,
    is-public: bool,
    cover-image-uri: (optional (string-ascii 200))
})

;; Poem pricing for sales
(define-map poem-prices uint {
    price: uint,
    for-sale: bool,
    seller: principal
})

;; Royalty recipients for poems
(define-map poem-royalties uint {
    primary-author: { recipient: principal, percentage: uint },
    collaborators: (list 5 { recipient: principal, percentage: uint })
})

;; Admin permissions
(define-map admins principal bool)

;; Poem view and engagement tracking
(define-map poem-stats uint {
    views: uint,
    likes: uint,
    shares: uint,
    last-interaction: uint
})

;; Initialize contract
(map-set admins CONTRACT_OWNER true)

;; Read-only functions
(define-read-only (get-poem (poem-id uint))
    (map-get? poems poem-id))

(define-read-only (get-poem-owner (poem-id uint))
    (nft-get-owner? poetry-nft poem-id))

(define-read-only (get-poet-profile (poet principal))
    (map-get? poet-profiles poet))

(define-read-only (get-collection (collection-id uint))
    (map-get? collections collection-id))

(define-read-only (get-poem-price (poem-id uint))
    (map-get? poem-prices poem-id))

(define-read-only (get-poem-stats (poem-id uint))
    (default-to 
        { views: u0, likes: u0, shares: u0, last-interaction: u0 }
        (map-get? poem-stats poem-id)))

(define-read-only (get-contract-stats)
    {
        total-poems: (var-get total-poems),
        total-collections: (var-get total-collections),
        next-poem-id: (var-get next-poem-id),
        contract-paused: (var-get contract-paused),
        minting-fee: (var-get minting-fee)
    })

(define-read-only (is-admin (user principal))
    (default-to false (map-get? admins user)))

(define-read-only (verify-poem-authenticity (poem-id uint) (content-hash (buff 32)))
    (match (get-poem poem-id)
        poem-data (is-eq (get content-hash poem-data) content-hash)
        false))

(define-read-only (get-poems-by-author (author principal))
    (match (get-poet-profile author)
        profile-data (get poems-created profile-data)
        u0))

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

(define-public (pause-contract)
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (var-set contract-paused true))))

(define-public (unpause-contract)
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (var-set contract-paused false))))

(define-public (update-minting-fee (new-fee uint))
    (begin
        (asserts! (is-admin tx-sender) ERR_UNAUTHORIZED)
        (ok (var-set minting-fee new-fee))))

;; Poet profile management
(define-public (create-poet-profile 
    (display-name (string-ascii 50))
    (bio (string-ascii 500))
    (social-links (string-ascii 200)))
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> (len display-name) u0) ERR_INVALID_TITLE)
        
        (map-set poet-profiles tx-sender {
            display-name: display-name,
            bio: bio,
            poems-created: u0,
            collections-created: u0,
            total-royalties-earned: u0,
            reputation-score: u100,
            verified-poet: false,
            social-links: social-links
        })
        (ok true)))

(define-public (update-poet-profile 
    (display-name (string-ascii 50))
    (bio (string-ascii 500))
    (social-links (string-ascii 200)))
    (let (
        (current-profile (unwrap! (map-get? poet-profiles tx-sender) ERR_UNAUTHORIZED))
    )
    (begin
        (asserts! (> (len display-name) u0) ERR_INVALID_TITLE)
        
        (map-set poet-profiles tx-sender 
            (merge current-profile {
                display-name: display-name,
                bio: bio,
                social-links: social-links
            }))
        (ok true))))

;; Collection management
(define-public (create-collection 
    (name (string-ascii 100))
    (description (string-ascii 500))
    (is-public bool)
    (cover-image-uri (optional (string-ascii 200))))
    (let (
        (collection-id (var-get next-collection-id))
        (current-profile (default-to 
            { display-name: "", bio: "", poems-created: u0, collections-created: u0, 
              total-royalties-earned: u0, reputation-score: u100, verified-poet: false, social-links: "" }
            (map-get? poet-profiles tx-sender)))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> (len name) u0) ERR_INVALID_TITLE)
        
        (map-set collections collection-id {
            name: name,
            description: description,
            creator: tx-sender,
            creation-timestamp: stacks-block-height,
            poem-count: u0,
            is-public: is-public,
            cover-image-uri: cover-image-uri
        })
        
        (map-set poet-profiles tx-sender 
            (merge current-profile {
                collections-created: (+ (get collections-created current-profile) u1)
            }))
        
        (var-set next-collection-id (+ collection-id u1))
        (var-set total-collections (+ (var-get total-collections) u1))
        (ok collection-id))))

;; Core poem minting functionality
(define-public (mint-poem 
    (title (string-ascii 100))
    (content-hash (buff 32))
    (genre (string-ascii 50))
    (language (string-ascii 20))
    (word-count uint)
    (line-count uint)
    (collection-id (optional uint))
    (royalty-percentage uint)
    (license-type (string-ascii 30))
    (metadata-uri (optional (string-ascii 200))))
    (let (
        (poem-id (var-get next-poem-id))
        (minting-cost (var-get minting-fee))
        (current-profile (default-to 
            { display-name: "", bio: "", poems-created: u0, collections-created: u0, 
              total-royalties-earned: u0, reputation-score: u100, verified-poet: false, social-links: "" }
            (map-get? poet-profiles tx-sender)))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> (len title) u0) ERR_INVALID_TITLE)
        (asserts! (> (len content-hash) u0) ERR_INVALID_CONTENT_HASH)
        (asserts! (<= royalty-percentage u1000) ERR_INVALID_ROYALTY) ;; Max 10% (1000 basis points)
        
        ;; Pay minting fee
        (if (> minting-cost u0)
            (try! (stx-transfer? minting-cost tx-sender (as-contract tx-sender)))
            true)
        
        ;; Mint the NFT
        (try! (nft-mint? poetry-nft poem-id tx-sender))
        
        ;; Store poem metadata
        (map-set poems poem-id {
            title: title,
            content-hash: content-hash,
            author: tx-sender,
            creation-timestamp: stacks-block-height,
            genre: genre,
            language: language,
            word-count: word-count,
            line-count: line-count,
            collection-id: collection-id,
            royalty-percentage: royalty-percentage,
            license-type: license-type,
            is-burned: false,
            metadata-uri: metadata-uri
        })
        
        ;; Initialize poem stats
        (map-set poem-stats poem-id {
            views: u0,
            likes: u0,
            shares: u0,
            last-interaction: stacks-block-height
        })
        
        ;; Update poet profile
        (map-set poet-profiles tx-sender 
            (merge current-profile {
                poems-created: (+ (get poems-created current-profile) u1)
            }))
        
        ;; Update collection if specified
        (match collection-id
            coll-id 
            (match (map-get? collections coll-id)
                collection-data 
                (begin
                    (asserts! (is-eq (get creator collection-data) tx-sender) ERR_UNAUTHORIZED)
                    (map-set collections coll-id 
                        (merge collection-data {
                            poem-count: (+ (get poem-count collection-data) u1)
                        }))
                    true)
                false)
            true)
        
        (var-set next-poem-id (+ poem-id u1))
        (var-set total-poems (+ (var-get total-poems) u1))
        (ok poem-id))))

;; Poem transfer functionality
(define-public (transfer-poem (poem-id uint) (sender principal) (recipient principal))
    (let (
        (poem-data (unwrap! (get-poem poem-id) ERR_POEM_NOT_FOUND))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (not (get is-burned poem-data)) ERR_POEM_BURNED)
        (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
        
        (try! (nft-transfer? poetry-nft poem-id sender recipient))
        (ok true))))

;; Poem marketplace functions
(define-public (list-poem-for-sale (poem-id uint) (price uint))
    (let (
        (poem-data (unwrap! (get-poem poem-id) ERR_POEM_NOT_FOUND))
        (owner (unwrap! (nft-get-owner? poetry-nft poem-id) ERR_POEM_NOT_FOUND))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq tx-sender owner) ERR_NOT_POEM_OWNER)
        (asserts! (not (get is-burned poem-data)) ERR_POEM_BURNED)
        (asserts! (> price u0) ERR_INVALID_PRICE)
        
        (map-set poem-prices poem-id {
            price: price,
            for-sale: true,
            seller: tx-sender
        })
        (ok true))))

(define-public (remove-poem-from-sale (poem-id uint))
    (let (
        (owner (unwrap! (nft-get-owner? poetry-nft poem-id) ERR_POEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender owner) ERR_NOT_POEM_OWNER)
        (map-delete poem-prices poem-id)
        (ok true))))

(define-public (purchase-poem (poem-id uint))
    (let (
        (poem-data (unwrap! (get-poem poem-id) ERR_POEM_NOT_FOUND))
        (price-data (unwrap! (get-poem-price poem-id) ERR_POEM_NOT_FOUND))
        (owner (unwrap! (nft-get-owner? poetry-nft poem-id) ERR_POEM_NOT_FOUND))
        (sale-price (get price price-data))
        (royalty-amount (* sale-price (get royalty-percentage poem-data)))
        (seller-amount (- sale-price (/ royalty-amount u10000)))
    )
    (begin
        (asserts! (get for-sale price-data) ERR_POEM_NOT_FOUND)
        (asserts! (not (is-eq tx-sender owner)) ERR_UNAUTHORIZED)
        (asserts! (not (get is-burned poem-data)) ERR_POEM_BURNED)
        
        ;; Transfer payment
        (try! (stx-transfer? seller-amount tx-sender (get seller price-data)))
        
        ;; Pay royalty to original author
        (if (> royalty-amount u0)
            (try! (stx-transfer? (/ royalty-amount u10000) tx-sender (get author poem-data)))
            true)
        
        ;; Transfer NFT
        (try! (nft-transfer? poetry-nft poem-id owner tx-sender))
        
        ;; Remove from sale
        (map-delete poem-prices poem-id)
        
        (ok true))))

;; Poem interaction functions
(define-public (increment-poem-views (poem-id uint))
    (let (
        (current-stats (get-poem-stats poem-id))
    )
    (begin
        (asserts! (is-some (get-poem poem-id)) ERR_POEM_NOT_FOUND)
        
        (map-set poem-stats poem-id 
            (merge current-stats {
                views: (+ (get views current-stats) u1),
                last-interaction: stacks-block-height
            }))
        (ok true))))

(define-public (like-poem (poem-id uint))
    (let (
        (current-stats (get-poem-stats poem-id))
    )
    (begin
        (asserts! (is-some (get-poem poem-id)) ERR_POEM_NOT_FOUND)
        
        (map-set poem-stats poem-id 
            (merge current-stats {
                likes: (+ (get likes current-stats) u1),
                last-interaction: stacks-block-height
            }))
        (ok true))))

;; Burn poem function
(define-public (burn-poem (poem-id uint))
    (let (
        (poem-data (unwrap! (get-poem poem-id) ERR_POEM_NOT_FOUND))
        (owner (unwrap! (nft-get-owner? poetry-nft poem-id) ERR_POEM_NOT_FOUND))
    )
    (begin
        (asserts! (is-eq tx-sender owner) ERR_NOT_POEM_OWNER)
        (asserts! (not (get is-burned poem-data)) ERR_POEM_BURNED)
        
        ;; Update poem data to mark as burned
        (map-set poems poem-id 
            (merge poem-data { is-burned: true }))
        
        ;; Remove from sale if listed
        (map-delete poem-prices poem-id)
        
        ;; Burn the NFT
        (try! (nft-burn? poetry-nft poem-id owner))
        
        (ok true))))

