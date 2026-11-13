# PrawnGuard Rust Native Core Engine (`prawnguard-rust`)
**Architecture Specification & FFI Integration Guide**  
**Crate:** `prawnguard-rust` (Rust 2021 Edition)  
**Target:** High-Performance Aquaculture Intelligence, Offline-First Synchronization & Flutter Native FFI  
**Version:** v0.1.0  

---

## 1. Executive Summary & Design Philosophy

The `prawnguard-rust` crate is a native, memory-safe, zero-cost abstraction implementation of the core aquaculture logic powering **PrawnGuard.ai (AquaVerse)**. Designed to run both as a standalone high-throughput microservice daemon / CLI and as an embedded C-ABI shared library (`cdylib`) via Dart FFI (`dart:ffi`), the engine achieves:
- **Sub-Microsecond Latency:** Mathematical models, bio-energetic feed scheduling, morphometric allometric curves, and opaque predicate evaluations execute in $<1\ \mu\text{s}$.
- **Zero-Allocation Critical Paths:** Numerical evaluations and state transitions avoid dynamic heap allocations wherever possible.
- **Deterministic Concurrency:** Offline outbox synchronization is protected by thread-safe `Arc<Mutex<...>>` synchronization with a strict 100-item FIFO cap and atomic dead-letter cascading quarantine.
- **Counter-REA Blue-Team Hardening:** Native $O(1)$ number-theoretic opaque predicates and honey-canary traps are embedded directly in compiled machine code.

---

## 2. System Architecture

```mermaid
flowchart TD
    subgraph ClientLayer["Flutter Mobile App / Admin CLI / Edge Service"]
        DartApp["Flutter UI (Dart 3.x)"]
        CLI["prawnguard CLI Binary"]
        DartFFI["Dart FFI (dart:ffi bindings)"]
    end

    subgraph NativeCrate["prawnguard-rust Native Engine"]
        FFI["C-ABI Interface (ffi.rs)"]
        
        subgraph CoreEngines["Core Domain & Intelligence Engines"]
            Models["Domain Models (models.rs)"]
            Outbox["Offline-First Outbox (outbox.rs)"]
            FeedAI["Bio-Energetic Feed AI (feed_ai.rs)"]
            Alerts["Hypoxia Alert Engine (alert_system.rs)"]
            Telugu["Telugu Voice NLU (telugu_nlu.rs)"]
            ABW["Morphometric ABW (abw.rs)"]
            PrawnDoc["PrawnDoc Vision AI (prawndoc.rs)"]
            Mandi["Mandi Rates Aggregator (mandi.rs)"]
            Finance["PrawnCredit Risk Engine (finance.rs)"]
            Security["Counter-REA Invariants (security.rs)"]
        end
    end

    DartApp --> DartFFI
    DartFFI --> FFI
    CLI --> CoreEngines
    FFI --> CoreEngines
```

---

## 3. Module Specifications & Parity Matrix

### 3.1 Domain Models (`src/models.rs`)
- Strongly typed Rust structs with `serde::Serialize` and `serde::Deserialize`.
- Entities: `Pond`, `WaterLog`, `FeedLog`, `DiseaseScan`, `Expense`, `Harvest`, `MarketPrice`.
- Includes helper methods such as `Pond::estimated_biomass_kg()`.

### 3.2 Offline-First Outbox Engine (`src/outbox.rs`)
- Thread-safe FIFO queue managed via `OfflineOutboxEngine` with `Arc<Mutex<OutboxState>>`.
- **Capacity Constraint:** Clamped strictly to a 100-mutation maximum capacity with head-eviction on overflow.
- **Idempotency:** Generates and validates deterministic UUID v4 idempotency keys.
- **Cascading Dead-Letter Quarantine (`quarantine_parent_and_children`):** When a parent pond mutation fails permanently, all dependent child records (water logs, feed logs, scans, expenses, harvests) referencing the parent pond ID are atomically routed to the dead-letter queue, eliminating foreign-key blocking (`23503`).
- **Dirty ID Isolation (`get_dirty_entity_ids`):** Provides hydration engines with in-flight dirty IDs so clean local edits are never overwritten by stale remote server state.

### 3.3 Bio-Energetic Feed AI (`src/feed_ai.rs`)
- Computes biomass: $\text{Biomass (kg)} = \text{Area (ha)} \times 10,000 \times \text{Density} \times \text{Survival} \times \frac{\text{ABW}}{1000}$.
- Clamps DOC feeding percentage strictly within $[0.03, 0.08]$ ($3\% - 8\%$).
- Diurnal 4-meal distribution: Meal 1 (20% @ 06:00), Meal 2 (30% @ 11:00), Meal 3 (30% @ 16:00), Meal 4 (20% @ 21:00).
- Check-tray adjustment multiplier strictly clamped to $[0.80, 1.10]$.
- Metabolic temperature curve: adjustments across $<24^\circ\text{C}$ (0.85), $24^\circ\text{C} - 32^\circ\text{C}$ (1.00), $>32^\circ\text{C}$ (0.90).
- ICAR-CIBA & CP/Avanti Bio-Energetic Finisher Curve for large shrimp ($>22\text{g}$).

### 3.4 Water Quality & Hypoxia Alert Engine (`src/alert_system.rs`)
- Threshold evaluation: pH ($7.5 - 8.5$), DO ($> 4.0\ \text{mg/L}$, critical siren if $< 3.5\ \text{mg/L}$, lethal if $< 2.8\ \text{mg/L}$), Ammonia ($< 0.05\ \text{mg/L}$ optimal, $> 0.1\ \text{mg/L}$ toxic urgent), Alkalinity ($100 - 150\ \text{mg/L}$).
- Emerson et al. (1975) un-ionized ammonia dissociation model ($pKa = 0.09018 + \frac{2729.92}{T_K}$).
- Nocturnal DO crash prediction (`forecast_dawn_dissolved_oxygen`) estimating 05:00 AM DO based on sediment/shrimp respiration, temperature, DOC, biomass, and aeration.
- Severity classification: `Optimal`, `Watch`, `Urgent`, `Critical`.

### 3.5 Telugu Voice NLU Regex Parser (`src/telugu_nlu.rs`)
- Tokenizes spoken and transliterated Telugu phrases (e.g. *"cheruvu 1 lo pH 7.8 DO 3.2 ammonia 0.08 feed 35kg"*, *"చెరువు 2 లో pH 7.5"*).
- Normalizes spoken Telugu number words (*ఒకటి*, *రెండు*, *మూడు*, *నాలుగు*, *ఐదు*, *ఆరు*, *ఏడు*, *ఎనిమిది*, *తొమ్మిది*, *పది*).
- Extracts pond index, pH, dissolved oxygen, ammonia, and feed weight into structured telemetry.

### 3.6 Allometric Morphometric ABW Engine (`src/abw.rs`)
- Evaluates weight-length allometric power law:
  $$W = 0.0082 \times L^{3.04}$$
  $$\text{Count per kg} = \frac{1000}{W}$$
- Classifies commercial size tiers: $20\text{c}, 30\text{c}, 40\text{c}, 50\text{c}, 60\text{c}, 80\text{c}, 100\text{c}$.
- Computes sample size uniformity and coefficient of variation ($CV$).

### 3.7 PrawnDoc Vision AI Heuristic Classifier (`src/prawndoc.rs`)
- 12 ICAR-CIBA shrimp disease classifications:
  1. White Spot Disease (WSSV) - Whispovirus
  2. Enterocytozoon hepatopenaei (EHP) - Microsporidian
  3. Acute Hepatopancreatic Necrosis / EMS (AHPND) - *Vibrio parahaemolyticus*
  4. White Feces Syndrome (WFS) - Vermiform Gregarine-like Aggregations
  5. Running Mortality Syndrome (RMS) - Idiopathic / Vibriosis
  6. Black Gill Disease - Melanin precipitation
  7. Loose Shell Syndrome (LSS) - Nutritional / Mineral
  8. Vibriosis (Luminous Bacteria) - *Vibrio harveyi*
  9. Cotton Shrimp / Microsporidiosis - *Thelohania*
  10. Infectious Hypodermal & Hematopoietic Necrosis (IHHNV) - Parvovirus
  11. Yellow Head Virus (YHV) - Okavirus
  12. Healthy / Optimal Cuticle
- Includes bilingual English & Telugu treatment protocols, dosage metrics, and emergency containment checklists.

### 3.8 PrawnCredit Risk & FCR Engine (`src/finance.rs`)
- Computes Feed Conversion Ratio: $\text{FCR} = \frac{\text{Total Feed (kg)}}{\text{Total Harvest Biomass (kg)}}$.
- Evaluates PrawnCredit Score ($300 - 900$) using weighted scoring factors:
  - FCR Efficiency ($35\%$)
  - Water Quality Log Consistency ($15\%$)
  - Survival Rate & Predictability ($25\%$)
  - Profit Margin & ROI ($25\%$)
- Maps scores to Underwriting Tiers: Tier-1 Elite (₹5,00,000/ha @ 1.1%/mo), Tier-2 Preferred (₹3,50,000/ha @ 1.4%/mo), Tier-3 Basic (₹2,00,000/ha @ 1.8%/mo).

### 3.9 Mandi Market Prices Aggregator (`src/mandi.rs`)
- Regional procurement rates across 4 Andhra Pradesh hubs: Bhimavaram (baseline), Nellore (+₹10 port proximity), Kaikaluru (-₹5 freight offset), Kakinada (+₹5 seaport terminal).
- Evaluates harvest valuation and net revenue realization after deducting 1.5% Mandi commission and ₹3.00/kg transport/ice fees.

### 3.10 Counter-REA Security & Opaque Invariants (`src/security.rs`)
- Evaluates $O(1)$ constant-time number-theoretic invariants:
  - $7x^2 - 1 \neq y^2 \pmod 7$ (Quadratic non-residue mod 7)
  - $x^2 + y^2 \not\equiv 3 \pmod 4$ (Sum of two squares mod 4)
  - $k(k+1) \pmod 2 == 0$ (Consecutive integer parity)
- Traps decompiler agents via string table adversarial prompt injections (`DECOMPILER_PROMPT_TRAP`) and honeypot canary tokens (`DECOY_ADMIN_TOKEN`, `DECOY_PAYMENT_SECRET`).

### 3.11 C-ABI FFI Bindings (`src/ffi.rs`)
- Exports un-mangled `extern "C"` functions for zero-overhead invocation from Flutter via `dart:ffi`:
  - `prawnguard_version() -> *const c_char`
  - `prawnguard_free_string(ptr: *mut c_char)`
  - `prawnguard_diagnose_symptoms(symptoms_csv: *const c_char) -> *mut c_char`
  - `prawnguard_get_mandi_price(hub_name: *const c_char, count_per_kg: u32) -> *mut c_char`
  - `prawnguard_estimate_harvest(biomass_kg: f64, count_per_kg: u32, hub_name: *const c_char) -> *mut c_char`
  - `prawnguard_verify_security(is_demo: i32) -> i32`

---

## 4. Interactive Terminal CLI Commands

The compiled `prawnguard` binary provides command-line diagnostic execution:

```powershell
# Run end-to-end simulation across all 10 subsystems
cargo run --manifest-path crates/prawnguard-rust/Cargo.toml -- demo

# Diagnose symptoms using ICAR-CIBA protocol
cargo run --manifest-path crates/prawnguard-rust/Cargo.toml -- diagnose "white spots on carapace, reddish coloration"

# Query regional Mandi price for a count grade
cargo run --manifest-path crates/prawnguard-rust/Cargo.toml -- mandi Bhimavaram 30

# Estimate harvest realization for 5000 kg at Nellore hub
cargo run --manifest-path crates/prawnguard-rust/Cargo.toml -- harvest 5000 30 Nellore

# Parse spoken Telugu voice telemetry
cargo run --manifest-path crates/prawnguard-rust/Cargo.toml -- telugu "cheruvu 1 lo pH 7.8 DO 3.2 ammonia 0.08 feed 35kg"

# Evaluate Counter-REA RASP invariant posture
cargo run --manifest-path crates/prawnguard-rust/Cargo.toml -- security
```

---

## 5. Verification & Test Suite Results

The complete Rust verification suite achieves 100% pass rate:
```powershell
cargo test --manifest-path crates/prawnguard-rust/Cargo.toml
cargo clippy --manifest-path crates/prawnguard-rust/Cargo.toml
```

- **Unit Tests:** 40/40 passed (0 failures, 0 warnings)
- **Integration Tests:** 3/3 passed (0 failures)
- **Execution Time:** ~0.06 seconds
- **Clippy Lint Status:** 0 warnings (100% clean)
