;; --------------------------------------
;; On-Chain Artist Registry Contract
;; --------------------------------------
;; Description:
;; A foundational contract for registering artists and their songs on-chain,
;; including song metadata and royalty recipients.
;;
;; Future extensions:
;; - Royalty payout system (integrated with fungible tokens)
;; - Integration with NFT minting for songs
;; - Music & podcast streaming service
;; --------------------------------------

;; --------------------------------------
;; Constants
;; --------------------------------------
;; Store the contract deployer's address as the owner
(define-constant CONTRACT_OWNER tx-sender)
;; Maximum length for artist names (50 ASCII characters)
(define-constant MAX_NAME_LEN 50)
;; Maximum length for song titles (100 ASCII characters)
(define-constant MAX_TITLE_LEN 100)

;; --------------------------------------
;; Errors
;; --------------------------------------
;; Error when artist tries to register but is already registered
(define-constant ERR_ALREADY_REGISTERED (err u101))
;; Error when trying to access an artist that doesn't exist
(define-constant ERR_ARTIST_NOT_FOUND (err u102))
;; Error when trying to access a song that doesn't exist
(define-constant ERR_SONG_NOT_FOUND (err u103))
;; Error when non-artist tries to perform artist-only operations
(define-constant ERR_NOT_ARTIST (err u104))
;; Error for empty or invalid names
(define-constant ERR_INVALID_NAME (err u110))
;; Error for duplicate file hashes
(define-constant ERR_DUPLICATE_FILE_HASH (err u111))

;; --------------------------------------
;; Data Variables & Maps
;; --------------------------------------

;; Counters
;; Global counter to track the next artist ID to assign
(define-data-var artist-counter uint u0)
;; Global counter to track the next song ID to assign
(define-data-var song-counter uint u0)

;; Artist storage
;; Maps artist ID to artist information (name and wallet address)
(define-map artists
  uint
  { name: (string-ascii 50), wallet: principal }
)

;; Principal to Artist ID lookup
;; Maps wallet address to artist ID for quick lookups
(define-map artist-by-principal principal uint)

;; Song storage
;; Maps song ID to song information (title, artist ID, and file hash)
(define-map songs
  uint
  { title: (string-ascii 100), artist-id: uint, file-hash: (buff 32) }
)

;; File hash tracking for duplicate prevention
;; Maps file hash to song ID to prevent duplicate uploads
(define-map file-hash-to-song (buff 32) uint)


;; --------------------------------------
;; Private Helper Functions
;; --------------------------------------

;; Check if a principal is registered as an artist
;; Returns the artist ID if registered, error if not
(define-private (is-artist-registered (who principal))
  ;; Look up the principal in the artist-by-principal map
  (match (map-get? artist-by-principal who)
    ;; If found, return the artist ID wrapped in ok
    some-id (ok some-id)
    ;; If not found, return artist not found error
    ERR_ARTIST_NOT_FOUND
  )
)


;; --------------------------------------
;; Public Functions
;; --------------------------------------

;; Register a new artist with the given name
;; Returns the new artist ID if successful, error if already registered or invalid name
(define-public (register-artist (name (string-ascii 50)))
  ;; Get the transaction sender (caller)
  (let ((caller tx-sender))
    ;; First validate the name is not empty
    (if (is-eq (len name) u0)
        ERR_INVALID_NAME
        ;; Check if caller is already registered as an artist
        (match (map-get? artist-by-principal caller)
          ;; If already registered, return error
          existing-id ERR_ALREADY_REGISTERED
          ;; If not registered, proceed with registration
            ;; Calculate the next artist ID by incrementing counter
            (let ((next-id (+ (var-get artist-counter) u1)))
              ;; Update the artist counter to the new ID
              (var-set artist-counter next-id)
              ;; Insert the new artist into the artists map
              (map-insert artists next-id { name: name, wallet: caller })
              ;; Create reverse lookup from principal to artist ID
              (map-insert artist-by-principal caller next-id)
              ;; Return the new artist ID
              (ok next-id)
            )
        )
    )
  )
)

;; Register a new song with title and file hash
;; Returns the new song ID if successful, error if not an artist or limits exceeded
(define-public (register-song (title (string-ascii 100)) (file-hash (buff 32)))
  ;; Get the transaction sender (caller)
  (let ((caller tx-sender))
    ;; First validate the title is not empty
    (if (is-eq (len title) u0)
        ERR_INVALID_NAME
        ;; Check if file hash already exists (prevent duplicates)
        (match (map-get? file-hash-to-song file-hash)
          ;; If file hash exists, return duplicate error
          existing-song-id ERR_DUPLICATE_FILE_HASH
          ;; If file hash is unique, proceed
            ;; Check if caller is registered as an artist
            (match (map-get? artist-by-principal caller)
              ;; If is an artist, proceed with song registration
              artist-id
                ;; Register the song
                (let ((next-song-id (+ (var-get song-counter) u1)))
                  ;; Update the global song counter
                  (var-set song-counter next-song-id)
                  ;; Insert the new song into songs map
                  (map-insert songs next-song-id { title: title, artist-id: artist-id, file-hash: file-hash })
                  ;; Map file hash to song ID for duplicate prevention
                  (map-insert file-hash-to-song file-hash next-song-id)
                  ;; Return the new song ID
                  (ok next-song-id)
                )
              ;; If not an artist, return error
              ERR_NOT_ARTIST
            )
        )
    )
  )
)


;; --------------------------------------
;; Read-Only Functions
;; --------------------------------------

;; Get song information by song ID
;; Returns song data (title, artist-id, file-hash) if found, error if not found
(define-read-only (get-song (song-id uint))
  ;; Look up song in the songs map
  (match (map-get? songs song-id)
    ;; If found, return the song data wrapped in ok
    song (ok song)
    ;; If not found, return song not found error
    ERR_SONG_NOT_FOUND
  )
)

;; --------------------------------------
;; End of Contract
;; --------------------------------------
;; Future roadmap:
;; 1. Integrate royalty payout using SIP-010 token transfers.
;; 2. Add admin/label verification with role-based access.
;; 3. Add metadata URIs (IPFS/Arweave) for songs.
;; 4. Introduce song ownership transfers and collaborations.
