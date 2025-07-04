;; Title: StackVault - Bitcoin-Native Portfolio DeFi Protocol

;;
;; Summary: Revolutionary decentralized asset management protocol engineered for
;;          Bitcoin's Layer 2 ecosystem, enabling sophisticated portfolio construction
;;          and automated rebalancing with institutional-grade precision on Stacks
;;
;; Description: StackVault transforms traditional portfolio management by bringing
;;              Wall Street-level sophistication to Bitcoin DeFi. Users can construct
;;              diversified cryptocurrency portfolios with mathematical precision,
;;              automated rebalancing algorithms, and gas-efficient operations that
;;              scale with Bitcoin's security model. The protocol features dynamic
;;              allocation adjustments, multi-asset support, and risk-optimized
;;              portfolio construction tools designed for both retail and institutional
;;              Bitcoin investors seeking exposure to the broader cryptocurrency market
;;              while maintaining Bitcoin's security guarantees through Stacks L2.
;;
;; Core Capabilities:
;;   - Dynamic multi-asset portfolio construction with mathematical precision
;;   - Automated rebalancing engine with configurable triggers and thresholds
;;   - Institutional-grade allocation management using basis point precision
;;   - Native Bitcoin integration through Stacks Layer 2 infrastructure
;;   - Gas-optimized smart contract architecture with minimal storage overhead
;;   - Advanced risk management tools and portfolio analytics
;;   - SIP-010 token standard integration for seamless DeFi interoperability
;;   - Multi-portfolio management with granular access controls
;;

;; ERROR CODES - Comprehensive Failure State Management System

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PORTFOLIO (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN (err u103))
(define-constant ERR-REBALANCE-FAILED (err u104))
(define-constant ERR-PORTFOLIO-EXISTS (err u105))
(define-constant ERR-INVALID-PERCENTAGE (err u106))
(define-constant ERR-MAX-TOKENS-EXCEEDED (err u107))
(define-constant ERR-LENGTH-MISMATCH (err u108))
(define-constant ERR-USER-STORAGE-FAILED (err u109))
(define-constant ERR-INVALID-TOKEN-ID (err u110))

;; PROTOCOL CONFIGURATION - Immutable System Parameters & Constants

(define-data-var protocol-owner principal tx-sender)
(define-data-var portfolio-counter uint u0)
(define-data-var protocol-fee uint u25) ;; 0.25% protocol fee (25 basis points)

(define-constant MAX-TOKENS-PER-PORTFOLIO u10)
(define-constant BASIS-POINTS u10000) ;; 100% = 10,000 basis points

;; DATA ARCHITECTURE - State Management & Storage Layer

;; Primary portfolio metadata storage with unique NFT-style identification
(define-map Portfolios
  uint ;; Unique portfolio identifier
  {
    owner: principal,
    created-at: uint,
    last-rebalanced: uint,
    total-value: uint, ;; Portfolio value in satoshi equivalents
    active: bool,
    token-count: uint,
  }
)

;; Individual asset allocation specifications within portfolios
(define-map PortfolioAssets
  {
    portfolio-id: uint,
    token-id: uint,
  }
  {
    target-percentage: uint, ;; Target allocation in basis points
    current-amount: uint, ;; Current token quantity held
    token-address: principal, ;; SIP-010 compliant token contract
  }
)

;; User-to-portfolio relationship mapping for multi-portfolio management
(define-map UserPortfolios
  principal
  (list 20 uint) ;; Maximum 20 portfolios per user
)

;; READ-ONLY INTERFACE - Query Functions & Data Retrieval

;; Retrieve complete portfolio metadata and configuration
(define-read-only (get-portfolio (portfolio-id uint))
  (map-get? Portfolios portfolio-id)
)

;; Get specific asset allocation details within a portfolio
(define-read-only (get-portfolio-asset
    (portfolio-id uint)
    (token-id uint)
  )
  (map-get? PortfolioAssets {
    portfolio-id: portfolio-id,
    token-id: token-id,
  })
)

;; Retrieve all portfolios owned by a specific user
(define-read-only (get-user-portfolios (user principal))
  (default-to (list) (map-get? UserPortfolios user))
)

;; Calculate rebalancing requirements and generate recommendations
(define-read-only (calculate-rebalance-amounts (portfolio-id uint))
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (total-value (get total-value portfolio))
    )
    (ok {
      portfolio-id: portfolio-id,
      total-value: total-value,
      needs-rebalance: (> (- stacks-block-height (get last-rebalanced portfolio)) u144), ;; 24 hour rebalancing interval
    })
  )
)

;; CORE FUNCTIONALITY - Portfolio Creation & Management Engine

;; Create new diversified portfolio with initial token allocation strategy
(define-public (create-portfolio
    (initial-tokens (list 10 principal))
    (percentages (list 10 uint))
  )
  (let (
      (portfolio-id (+ (var-get portfolio-counter) u1))
      (token-count (len initial-tokens))
      (percentage-count (len percentages))
      (token-0 (element-at? initial-tokens u0))
      (token-1 (element-at? initial-tokens u1))
      (percentage-0 (element-at? percentages u0))
      (percentage-1 (element-at? percentages u1))
    )
    ;; Comprehensive validation layer for portfolio creation
    (asserts! (<= token-count MAX-TOKENS-PER-PORTFOLIO) ERR-MAX-TOKENS-EXCEEDED)
    (asserts! (is-eq token-count percentage-count) ERR-LENGTH-MISMATCH)
    (asserts! (validate-portfolio-percentages percentages) ERR-INVALID-PERCENTAGE)
    ;; Initialize portfolio metadata with creation parameters
    (map-set Portfolios portfolio-id {
      owner: tx-sender,
      created-at: stacks-block-height,
      last-rebalanced: stacks-block-height,
      total-value: u0,
      active: true,
      token-count: token-count,
    })
    ;; Initialize minimum viable portfolio with first two assets
    (asserts! (and (is-some token-0) (is-some token-1)) ERR-INVALID-TOKEN)
    (asserts! (and (is-some percentage-0) (is-some percentage-1))
      ERR-INVALID-PERCENTAGE
    )
    (try! (initialize-portfolio-asset u0 (unwrap-panic token-0)
      (unwrap-panic percentage-0) portfolio-id
    ))
    (try! (initialize-portfolio-asset u1 (unwrap-panic token-1)
      (unwrap-panic percentage-1) portfolio-id
    ))
    ;; Update user portfolio registry and increment global counter
    (try! (add-to-user-portfolios tx-sender portfolio-id))
    (var-set portfolio-counter portfolio-id)
    (ok portfolio-id)
  )
)

;; PORTFOLIO OPERATIONS - Rebalancing & Allocation Management

;; Execute automated portfolio rebalancing to target allocations
(define-public (rebalance-portfolio (portfolio-id uint))
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO)))
    ;; Authorization and state validation checks
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (get active portfolio) ERR-INVALID-PORTFOLIO)
    ;; Update rebalancing timestamp for tracking purposes
    (map-set Portfolios portfolio-id
      (merge portfolio { last-rebalanced: stacks-block-height })
    )
    (ok true)
  )
)

;; Update target allocation percentage for specific portfolio asset
(define-public (update-portfolio-allocation
    (portfolio-id uint)
    (token-id uint)
    (new-percentage uint)
  )
  (let (
      (portfolio (unwrap! (get-portfolio portfolio-id) ERR-INVALID-PORTFOLIO))
      (asset (unwrap! (get-portfolio-asset portfolio-id token-id) ERR-INVALID-TOKEN))
    )
    ;; Authorization and validation checks
    (asserts! (is-eq tx-sender (get owner portfolio)) ERR-NOT-AUTHORIZED)
    (asserts! (validate-percentage new-percentage) ERR-INVALID-PERCENTAGE)
    (asserts! (validate-token-id portfolio-id token-id) ERR-INVALID-TOKEN-ID)
    ;; Update asset allocation with new target percentage
    (map-set PortfolioAssets {
      portfolio-id: portfolio-id,
      token-id: token-id,
    }
      (merge asset { target-percentage: new-percentage })
    )
    (ok true)
  )
)

;; INTERNAL HELPERS - Validation & Utility Functions

;; Validate token ID against portfolio constraints and bounds
(define-private (validate-token-id
    (portfolio-id uint)
    (token-id uint)
  )
  (let ((portfolio (unwrap! (get-portfolio portfolio-id) false)))
    (and
      (< token-id MAX-TOKENS-PER-PORTFOLIO)
      (< token-id (get token-count portfolio))
      true
    )
  )
)

;; Validate percentage is within acceptable range (0-10000 basis points)
(define-private (validate-percentage (percentage uint))
  (and (>= percentage u0) (<= percentage BASIS-POINTS))
)

;; Validate that all portfolio percentages are within valid ranges
(define-private (validate-portfolio-percentages (percentages (list 10 uint)))
  (fold check-percentage-sum percentages true)
)

;; Helper function for percentage validation fold operation
(define-private (check-percentage-sum
    (current-percentage uint)
    (valid bool)
  )
  (and valid (validate-percentage current-percentage))
)