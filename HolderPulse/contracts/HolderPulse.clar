;; Behavioral Analysis for Token Holders
;; This contract tracks and analyzes token holder behavior including transfer patterns,
;; holding duration, activity frequency, and risk scoring to identify suspicious activities
;; and reward loyal holders. It provides comprehensive analytics for token economics.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-parameter (err u105))

;; Risk level thresholds
(define-constant risk-low u25)
(define-constant risk-medium u50)
(define-constant risk-high u75)

;; Behavior scoring weights
(define-constant weight-frequency u30)
(define-constant weight-volume u25)
(define-constant weight-duration u25)
(define-constant weight-consistency u20)

;; data maps and vars

;; Track individual holder behavior metrics
(define-map holder-profiles
    principal
    {
        total-transfers: uint,
        total-volume: uint,
        first-activity: uint,
        last-activity: uint,
        average-hold-time: uint,
        risk-score: uint,
        loyalty-score: uint,
        is-flagged: bool
    }
)

;; Track transfer patterns for anomaly detection
(define-map transfer-history
    { holder: principal, transfer-id: uint }
    {
        amount: uint,
        timestamp: uint,
        recipient: principal,
        transfer-type: (string-ascii 20)
    }
)

;; Track daily activity aggregates
(define-map daily-activity
    { holder: principal, day: uint }
    {
        transfer-count: uint,
        total-volume: uint,
        unique-recipients: uint
    }
)

;; Behavioral patterns and flags
(define-map behavior-flags
    principal
    {
        rapid-trading: bool,
        large-volume: bool,
        suspicious-pattern: bool,
        whale-activity: bool,
        dormant-reactivation: bool
    }
)

;; Global analytics
(define-data-var total-holders uint u0)
(define-data-var total-flagged-holders uint u0)
(define-data-var average-risk-score uint u0)
(define-data-var next-transfer-id uint u0)

;; Configuration parameters
(define-data-var min-hold-time-for-loyalty uint u2592000) ;; ~30 days in blocks
(define-data-var max-transfers-per-day uint u50)
(define-data-var whale-threshold uint u1000000)
(define-data-var dormancy-period uint u8640000) ;; ~100 days in blocks

;; private functions

;; Helper function to get maximum of two uints
(define-private (max (a uint) (b uint))
    (if (> a b) a b)
)

;; Helper function to get minimum of two uints
(define-private (min (a uint) (b uint))
    (if (< a b) a b)
)

;; Calculate risk score based on multiple behavioral factors
(define-private (calculate-risk-score (holder principal))
    (let
        (
            (profile (unwrap! (map-get? holder-profiles holder) u0))
            (flags (default-to 
                { rapid-trading: false, large-volume: false, suspicious-pattern: false, 
                  whale-activity: false, dormant-reactivation: false }
                (map-get? behavior-flags holder)))
            (transfer-frequency (get total-transfers profile))
            (volume-score (if (> (get total-volume profile) (var-get whale-threshold)) u25 u0))
            (frequency-score (if (> transfer-frequency u100) u25 u0))
            (flag-score (+ 
                (if (get rapid-trading flags) u10 u0)
                (if (get large-volume flags) u10 u0)
                (if (get suspicious-pattern flags) u15 u0)
                (if (get whale-activity flags) u5 u0)
                (if (get dormant-reactivation flags) u10 u0)))
        )
        (+ volume-score (+ frequency-score flag-score))
    )
)

;; Calculate loyalty score based on holding duration and consistency
(define-private (calculate-loyalty-score (holder principal))
    (let
        (
            (profile (unwrap! (map-get? holder-profiles holder) u0))
            (hold-duration (- (get last-activity profile) (get first-activity profile)))
            (avg-hold (get average-hold-time profile))
            (duration-score (if (>= hold-duration (var-get min-hold-time-for-loyalty)) u40 
                (/ (* hold-duration u40) (var-get min-hold-time-for-loyalty))))
            (consistency-score (if (> avg-hold u86400) u30 (/ (* avg-hold u30) u86400)))
            (activity-score (if (and (> (get total-transfers profile) u5) 
                                     (< (get total-transfers profile) u50)) u30 u10))
        )
        (+ duration-score (+ consistency-score activity-score))
    )
)

;; Check if holder exhibits rapid trading behavior
(define-private (check-rapid-trading (holder principal) (day uint))
    (let
        (
            (daily-data (map-get? daily-activity { holder: holder, day: day }))
        )
        (match daily-data
            activity (> (get transfer-count activity) (var-get max-transfers-per-day))
            false
        )
    )
)

;; Update behavior flags based on recent activity
(define-private (update-behavior-flags (holder principal) (amount uint))
    (match (map-get? holder-profiles holder)
        profile
        (let
            (
                (current-day (/ block-height u144))
                (is-rapid (check-rapid-trading holder current-day))
                (is-large-volume (> amount (/ (var-get whale-threshold) u10)))
                (is-whale (> (get total-volume profile) (var-get whale-threshold)))
                (time-since-last (- block-height (get last-activity profile)))
                (is-dormant-reactivation (> time-since-last (var-get dormancy-period)))
            )
            (map-set behavior-flags holder {
                rapid-trading: is-rapid,
                large-volume: is-large-volume,
                suspicious-pattern: (and is-rapid is-large-volume),
                whale-activity: is-whale,
                dormant-reactivation: is-dormant-reactivation
            })
        )
        false
    )
)

;; public functions

;; Initialize or update holder profile
(define-public (register-holder (holder principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (match (map-get? holder-profiles holder)
            existing-profile err-already-exists
            (begin
                (map-set holder-profiles holder {
                    total-transfers: u0,
                    total-volume: u0,
                    first-activity: block-height,
                    last-activity: block-height,
                    average-hold-time: u0,
                    risk-score: u0,
                    loyalty-score: u0,
                    is-flagged: false
                })
                (var-set total-holders (+ (var-get total-holders) u1))
                (ok true)
            )
        )
    )
)

;; Record a transfer and update behavioral metrics
(define-public (record-transfer (holder principal) (recipient principal) 
                                (amount uint) (transfer-type (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> amount u0) err-invalid-amount)
        
        (let
            (
                (profile (unwrap! (map-get? holder-profiles holder) err-not-found))
                (transfer-id (var-get next-transfer-id))
                (current-day (/ block-height u144))
                (new-total-transfers (+ (get total-transfers profile) u1))
                (new-total-volume (+ (get total-volume profile) amount))
                (time-held (- block-height (get last-activity profile)))
                (new-avg-hold (/ (+ (* (get average-hold-time profile) (get total-transfers profile)) 
                                   time-held) new-total-transfers))
            )
            
            ;; Update transfer history
            (map-set transfer-history 
                { holder: holder, transfer-id: transfer-id }
                {
                    amount: amount,
                    timestamp: block-height,
                    recipient: recipient,
                    transfer-type: transfer-type
                })
            
            ;; Update daily activity
            (match (map-get? daily-activity { holder: holder, day: current-day })
                existing-daily
                    (map-set daily-activity { holder: holder, day: current-day }
                        {
                            transfer-count: (+ (get transfer-count existing-daily) u1),
                            total-volume: (+ (get total-volume existing-daily) amount),
                            unique-recipients: (get unique-recipients existing-daily)
                        })
                (map-set daily-activity { holder: holder, day: current-day }
                    {
                        transfer-count: u1,
                        total-volume: amount,
                        unique-recipients: u1
                    })
            )
            
            ;; Update behavior flags
            (update-behavior-flags holder amount)
            
            ;; Calculate new scores
            (let
                (
                    (new-risk-score (calculate-risk-score holder))
                    (new-loyalty-score (calculate-loyalty-score holder))
                    (should-flag (>= new-risk-score risk-high))
                )
                
                ;; Update holder profile
                (map-set holder-profiles holder {
                    total-transfers: new-total-transfers,
                    total-volume: new-total-volume,
                    first-activity: (get first-activity profile),
                    last-activity: block-height,
                    average-hold-time: new-avg-hold,
                    risk-score: new-risk-score,
                    loyalty-score: new-loyalty-score,
                    is-flagged: should-flag
                })
                
                ;; Update global flagged count
                (if (and should-flag (not (get is-flagged profile)))
                    (var-set total-flagged-holders (+ (var-get total-flagged-holders) u1))
                    true
                )
                
                (var-set next-transfer-id (+ transfer-id u1))
                (ok transfer-id)
            )
        )
    )
)

;; Get comprehensive holder profile with all metrics
(define-read-only (get-holder-profile (holder principal))
    (ok (map-get? holder-profiles holder))
)

;; Get behavior flags for a holder
(define-read-only (get-behavior-flags (holder principal))
    (ok (map-get? behavior-flags holder))
)

;; Get transfer history for a specific transfer
(define-read-only (get-transfer-details (holder principal) (transfer-id uint))
    (ok (map-get? transfer-history { holder: holder, transfer-id: transfer-id }))
)

;; Get daily activity summary
(define-read-only (get-daily-activity (holder principal) (day uint))
    (ok (map-get? daily-activity { holder: holder, day: day }))
)

;; Get global analytics
(define-read-only (get-global-analytics)
    (ok {
        total-holders: (var-get total-holders),
        total-flagged: (var-get total-flagged-holders),
        average-risk: (var-get average-risk-score),
        next-transfer-id: (var-get next-transfer-id)
    })
)


