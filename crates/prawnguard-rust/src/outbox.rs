use std::collections::{HashSet, VecDeque};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

static MUTATION_SEQ: AtomicU64 = AtomicU64::new(1);

/// Status lifecycle for offline mutations.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MutationStatus {
    Pending,
    InFlight,
    Completed,
    FailedPermanent,
}

/// Offline mutation item queued for background or cloud synchronization.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct OutboxMutation {
    pub id: String,
    pub idempotency_key: Uuid,
    pub table_name: String,
    pub operation: String,
    pub payload: serde_json::Value,
    pub base_version: Option<u32>,
    pub status: MutationStatus,
    pub retry_count: u32,
    pub last_error: Option<String>,
    pub created_at: String,
}

impl OutboxMutation {
    pub fn new(
        table_name: impl Into<String>,
        operation: impl Into<String>,
        payload: serde_json::Value,
        base_version: Option<u32>,
    ) -> Self {
        let now = Utc::now();
        let seq = MUTATION_SEQ.fetch_add(1, Ordering::Relaxed);
        let id = format!("mut_{}_{}", now.timestamp_micros(), seq);
        Self {
            id,
            idempotency_key: Uuid::new_v4(),
            table_name: table_name.into(),
            operation: operation.into(),
            payload,
            base_version,
            status: MutationStatus::Pending,
            retry_count: 0,
            last_error: None,
            created_at: now.to_rfc3339(),
        }
    }

    /// Helper to extract entity ID from mutation payload if present.
    pub fn entity_id(&self) -> Option<String> {
        self.payload.get("id")
            .and_then(|v| v.as_str().map(|s| s.to_string()))
    }

    /// Helper to check if mutation references a specific pond ID.
    pub fn references_pond(&self, pond_id: &str) -> bool {
        if let Some(pid) = self.payload.get("pond_id").and_then(|v| v.as_str()) {
            if pid == pond_id { return true; }
        }
        if let Some(pid) = self.payload.get("pondId").and_then(|v| v.as_str()) {
            if pid == pond_id { return true; }
        }
        false
    }
}

/// Thread-safe state for the outbox engine.
#[derive(Debug, Default)]
struct OutboxState {
    queue: VecDeque<OutboxMutation>,
    dead_letter_queue: Vec<OutboxMutation>,
}

/// High-performance Offline-First Idempotent Outbox Engine.
/// Guarantees FIFO execution order, capacity bounds (100 items),
/// mutex concurrency, and cascading child quarantine.
#[derive(Debug, Clone)]
pub struct OfflineOutboxEngine {
    state: Arc<Mutex<OutboxState>>,
    max_capacity: usize,
}

impl Default for OfflineOutboxEngine {
    fn default() -> Self {
        Self::new(100)
    }
}

impl OfflineOutboxEngine {
    pub fn new(max_capacity: usize) -> Self {
        Self {
            state: Arc::new(Mutex::new(OutboxState::default())),
            max_capacity,
        }
    }

    /// Enqueues a new mutation under lock. If queue exceeds capacity, drops oldest item (FIFO).
    pub fn enqueue(
        &self,
        table_name: impl Into<String>,
        operation: impl Into<String>,
        payload: serde_json::Value,
        base_version: Option<u32>,
    ) -> OutboxMutation {
        let mutation = OutboxMutation::new(table_name, operation, payload, base_version);
        let mut state = self.state.lock().expect("Outbox lock poisoned");

        if state.queue.len() >= self.max_capacity {
            state.queue.pop_front(); // Evict oldest mutation to maintain strict capacity ceiling
        }

        state.queue.push_back(mutation.clone());
        mutation
    }

    /// Enqueues an existing mutation struct directly.
    pub fn enqueue_mutation(&self, mutation: OutboxMutation) {
        let mut state = self.state.lock().expect("Outbox lock poisoned");
        if state.queue.len() >= self.max_capacity {
            state.queue.pop_front();
        }
        state.queue.push_back(mutation);
    }

    /// Peeks the head pending mutation for processing without removing it.
    pub fn peek_head(&self) -> Option<OutboxMutation> {
        let state = self.state.lock().expect("Outbox lock poisoned");
        state.queue.front().cloned()
    }

    /// Atomically removes a successfully synced mutation by its ID.
    pub fn remove_mutation(&self, mutation_id: &str) -> bool {
        let mut state = self.state.lock().expect("Outbox lock poisoned");
        if let Some(pos) = state.queue.iter().position(|m| m.id == mutation_id) {
            state.queue.remove(pos);
            true
        } else {
            false
        }
    }

    /// Quarantines a permanently failed mutation to the Dead-Letter Queue (DLQ).
    pub fn quarantine_mutation(&self, mutation_id: &str, error_reason: &str) -> bool {
        let mut state = self.state.lock().expect("Outbox lock poisoned");
        if let Some(pos) = state.queue.iter().position(|m| m.id == mutation_id) {
            let mut failed = state.queue.remove(pos).expect("Valid index");
            failed.status = MutationStatus::FailedPermanent;
            failed.last_error = Some(error_reason.to_string());
            state.dead_letter_queue.push(failed);
            true
        } else {
            false
        }
    }

    /// Cascading Parent-Child Quarantine:
    /// When an offline pond creation fails permanently, quarantines the parent pond AND
    /// all child mutations referencing the parent's temporary ID (water logs, feed logs, expenses, harvests).
    /// Prevents 23503 foreign key rejections and unblocks subsequent unrelated mutations.
    pub fn quarantine_parent_and_children(
        &self,
        parent_pond_id: &str,
        failure_reason: &str,
    ) -> Vec<String> {
        let mut state = self.state.lock().expect("Outbox lock poisoned");
        let mut quarantined_ids = Vec::new();
        let mut retained = VecDeque::new();

        while let Some(mut mutation) = state.queue.pop_front() {
            let is_parent = mutation.table_name == "ponds"
                && mutation.entity_id().as_deref() == Some(parent_pond_id);
            let is_child = mutation.references_pond(parent_pond_id);

            if is_parent || is_child {
                let reason = if is_parent {
                    failure_reason.to_string()
                } else {
                    format!("Blocked by failed parent pond creation: {}", parent_pond_id)
                };
                mutation.status = MutationStatus::FailedPermanent;
                mutation.last_error = Some(reason);
                quarantined_ids.push(mutation.id.clone());
                state.dead_letter_queue.push(mutation);
            } else {
                retained.push_back(mutation);
            }
        }

        state.queue = retained;
        quarantined_ids
    }

    /// Returns the set of all entity IDs and idempotency keys with pending in-flight mutations.
    /// Used by hydration engines to prevent remote server state from overwriting clean local edits.
    pub fn get_dirty_entity_ids(&self) -> HashSet<String> {
        let state = self.state.lock().expect("Outbox lock poisoned");
        let mut set = HashSet::new();
        for m in state.queue.iter() {
            if let Some(id) = m.entity_id() {
                set.insert(id);
            }
            set.insert(m.idempotency_key.to_string());
        }
        set
    }

    /// Returns count of active queued mutations.
    pub fn queue_len(&self) -> usize {
        let state = self.state.lock().expect("Outbox lock poisoned");
        state.queue.len()
    }

    /// Returns count of dead-letter quarantined mutations.
    pub fn dlq_len(&self) -> usize {
        let state = self.state.lock().expect("Outbox lock poisoned");
        state.dead_letter_queue.len()
    }

    /// Clears both active queue and DLQ.
    pub fn clear(&self) {
        let mut state = self.state.lock().expect("Outbox lock poisoned");
        state.queue.clear();
        state.dead_letter_queue.clear();
    }

    /// Returns snapshot of all currently pending mutations.
    pub fn get_all_pending(&self) -> Vec<OutboxMutation> {
        let state = self.state.lock().expect("Outbox lock poisoned");
        state.queue.iter().cloned().collect()
    }

    /// Returns snapshot of all DLQ items.
    pub fn get_dlq(&self) -> Vec<OutboxMutation> {
        let state = self.state.lock().expect("Outbox lock poisoned");
        state.dead_letter_queue.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_fifo_capacity_and_overflow() {
        let engine = OfflineOutboxEngine::new(5);

        for i in 1..=5 {
            engine.enqueue("water_logs", "INSERT", json!({"id": format!("wlog_{}", i)}), None);
        }
        assert_eq!(engine.queue_len(), 5);

        // Enqueue 6th mutation -> should evict wlog_1
        engine.enqueue("water_logs", "INSERT", json!({"id": "wlog_6"}), None);
        assert_eq!(engine.queue_len(), 5);

        let head = engine.peek_head().expect("Must have head");
        assert_eq!(head.entity_id().as_deref(), Some("wlog_2"));
    }

    #[test]
    fn test_atomic_remove_and_dirty_ids() {
        let engine = OfflineOutboxEngine::new(10);
        let m1 = engine.enqueue("ponds", "INSERT", json!({"id": "pond_temp_1"}), None);
        let _m2 = engine.enqueue("feed_logs", "INSERT", json!({"id": "feed_1", "pond_id": "pond_temp_1"}), None);

        let dirty = engine.get_dirty_entity_ids();
        assert!(dirty.contains("pond_temp_1"));
        assert!(dirty.contains("feed_1"));

        assert!(engine.remove_mutation(&m1.id));
        assert_eq!(engine.queue_len(), 1);

        let dirty_after = engine.get_dirty_entity_ids();
        assert!(!dirty_after.contains("pond_temp_1"));
        assert!(dirty_after.contains("feed_1"));
    }

    #[test]
    fn test_cascading_parent_child_quarantine() {
        let engine = OfflineOutboxEngine::new(10);
        let _p1 = engine.enqueue("ponds", "INSERT", json!({"id": "p_parent_failed"}), None);
        let _c1 = engine.enqueue("water_logs", "INSERT", json!({"id": "w1", "pond_id": "p_parent_failed"}), None);
        let _c2 = engine.enqueue("feed_logs", "INSERT", json!({"id": "f1", "pondId": "p_parent_failed"}), None);
        let other = engine.enqueue("expenses", "INSERT", json!({"id": "exp_other", "pond_id": "p_unrelated"}), None);

        assert_eq!(engine.queue_len(), 4);

        let quarantined = engine.quarantine_parent_and_children("p_parent_failed", "Foreign key constraint failure");
        assert_eq!(quarantined.len(), 3);
        assert_eq!(engine.queue_len(), 1);
        assert_eq!(engine.dlq_len(), 3);

        let remaining = engine.peek_head().expect("Other item remains");
        assert_eq!(remaining.id, other.id);
    }
}
