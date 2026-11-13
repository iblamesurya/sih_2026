/**
 * PrawnGuard.ai TypeScript Offline Outbox Engine
 * FIFO queue, capacity eviction (100 cap), UUID v4 idempotency,
 * mutex concurrency, cascading parent-child quarantine, and dirty entity ID tracking.
 */

export type MutationStatus = 'Pending' | 'InFlight' | 'Completed' | 'FailedPermanent';

export interface OutboxMutation {
  id: string;
  idempotencyKey: string;
  tableName: string;
  operation: string;
  payload: Record<string, unknown>;
  baseVersion?: number | null;
  status: MutationStatus;
  retryCount: number;
  lastError?: string | null;
  createdAt: string;
}

/**
 * Generates an RFC4122 v4 UUID without external dependencies.
 */
export function generateUuid(): string {
  if (typeof globalThis.crypto !== 'undefined' && typeof globalThis.crypto.randomUUID === 'function') {
    return globalThis.crypto.randomUUID();
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

let mutationCounter = 0;

export function createMutation(
  tableName: string,
  operation: string,
  payload: Record<string, unknown>,
  baseVersion?: number | null
): OutboxMutation {
  const now = new Date();
  mutationCounter = (mutationCounter + 1) % 1_000_000;
  const id = `mut_${now.getTime()}_${mutationCounter}`;

  return {
    id,
    idempotencyKey: generateUuid(),
    tableName,
    operation,
    payload,
    baseVersion: baseVersion ?? null,
    status: 'Pending',
    retryCount: 0,
    lastError: null,
    createdAt: now.toISOString(),
  };
}

export function getEntityId(mutation: OutboxMutation): string | undefined {
  if (mutation.payload && typeof mutation.payload['id'] === 'string') {
    return mutation.payload['id'];
  }
  return undefined;
}

export function referencesPond(mutation: OutboxMutation, pondId: string): boolean {
  if (!mutation.payload) return false;
  if (mutation.payload['pond_id'] === pondId) return true;
  if (mutation.payload['pondId'] === pondId) return true;
  return false;
}

/**
 * Async Mutex for serialized queue operations in concurrent asynchronous contexts.
 */
export class Mutex {
  private _locked: boolean = false;
  private _waiting: Array<() => void> = [];

  public async acquire(): Promise<() => void> {
    if (!this._locked) {
      this._locked = true;
      return () => this.release();
    }
    return new Promise<() => void>((resolve) => {
      this._waiting.push(() => {
        this._locked = true;
        resolve(() => this.release());
      });
    });
  }

  public release(): void {
    if (this._waiting.length > 0) {
      const next = this._waiting.shift();
      if (next) next();
    } else {
      this._locked = false;
    }
  }

  public async runExclusive<T>(fn: () => T | Promise<T>): Promise<T> {
    const release = await this.acquire();
    try {
      return await fn();
    } finally {
      release();
    }
  }
}

/**
 * Offline-First Idempotent Outbox Engine.
 * Guarantees FIFO execution order, capacity ceiling (100 items),
 * async mutex synchronization, and cascading parent-child quarantine.
 */
export class OfflineOutboxEngine {
  private queue: OutboxMutation[] = [];
  private deadLetterQueue: OutboxMutation[] = [];
  private maxCapacity: number;
  private mutex: Mutex = new Mutex();

  constructor(maxCapacity: number = 100) {
    this.maxCapacity = maxCapacity;
  }

  /**
   * Enqueues a new mutation. If capacity is exceeded, drops oldest item (FIFO head eviction).
   */
  public enqueue(
    tableName: string,
    operation: string,
    payload: Record<string, unknown>,
    baseVersion?: number | null
  ): OutboxMutation {
    const mutation = createMutation(tableName, operation, payload, baseVersion);
    if (this.queue.length >= this.maxCapacity) {
      this.queue.shift(); // Evict oldest
    }
    this.queue.push(mutation);
    return mutation;
  }

  /**
   * Enqueues an existing mutation.
   */
  public enqueueMutation(mutation: OutboxMutation): void {
    if (this.queue.length >= this.maxCapacity) {
      this.queue.shift();
    }
    this.queue.push(mutation);
  }

  /**
   * Peeks the head pending mutation for sync processing.
   */
  public peekHead(): OutboxMutation | undefined {
    return this.queue.length > 0 ? { ...this.queue[0] } : undefined;
  }

  /**
   * Atomically removes a successfully synced mutation by ID.
   */
  public removeMutation(mutationId: string): boolean {
    const idx = this.queue.findIndex((m) => m.id === mutationId);
    if (idx !== -1) {
      this.queue.splice(idx, 1);
      return true;
    }
    return false;
  }

  /**
   * Quarantines a permanently failed mutation to the Dead-Letter Queue (DLQ).
   */
  public quarantineMutation(mutationId: string, errorReason: string): boolean {
    const idx = this.queue.findIndex((m) => m.id === mutationId);
    if (idx !== -1) {
      const [failed] = this.queue.splice(idx, 1);
      failed.status = 'FailedPermanent';
      failed.lastError = errorReason;
      this.deadLetterQueue.push(failed);
      return true;
    }
    return false;
  }

  /**
   * Cascading Parent-Child Quarantine:
   * When an offline pond creation fails permanently, quarantines the parent pond AND
   * all child mutations referencing the parent's temporary ID (water logs, feed logs, expenses, harvests).
   * Prevents 23503 foreign key rejections and unblocks subsequent unrelated mutations.
   */
  public quarantineParentAndChildren(parentPondId: string, failureReason: string): string[] {
    const quarantinedIds: string[] = [];
    const retained: OutboxMutation[] = [];

    for (const mutation of this.queue) {
      const isParent = mutation.tableName === 'ponds' && getEntityId(mutation) === parentPondId;
      const isChild = referencesPond(mutation, parentPondId);

      if (isParent || isChild) {
        const reason = isParent
          ? failureReason
          : `Blocked by failed parent pond creation: ${parentPondId}`;
        mutation.status = 'FailedPermanent';
        mutation.lastError = reason;
        quarantinedIds.push(mutation.id);
        this.deadLetterQueue.push(mutation);
      } else {
        retained.push(mutation);
      }
    }

    this.queue = retained;
    return quarantinedIds;
  }

  /**
   * Returns the set of all entity IDs with pending in-flight mutations.
   * Used by hydration engines to prevent remote server state from overwriting clean local edits.
   */
  public getDirtyEntityIds(): Set<string> {
    const dirty = new Set<string>();
    for (const m of this.queue) {
      const entId = getEntityId(m);
      if (entId) {
        dirty.add(entId);
      }
    }
    return dirty;
  }

  /**
   * Returns count of active queued mutations.
   */
  public queueLen(): number {
    return this.queue.length;
  }

  /**
   * Returns count of dead-letter quarantined mutations.
   */
  public dlqLen(): number {
    return this.deadLetterQueue.length;
  }

  /**
   * Clears both active queue and DLQ.
   */
  public clear(): void {
    this.queue = [];
    this.deadLetterQueue = [];
  }

  /**
   * Returns snapshot of all currently pending mutations.
   */
  public getAllPending(): OutboxMutation[] {
    return this.queue.map((m) => ({ ...m }));
  }

  /**
   * Returns snapshot of all DLQ items.
   */
  public getDlq(): OutboxMutation[] {
    return this.deadLetterQueue.map((m) => ({ ...m }));
  }

  /**
   * Runs an operation with mutex exclusivity.
   */
  public async runLocked<T>(fn: () => T | Promise<T>): Promise<T> {
    return this.mutex.runExclusive(fn);
  }
}
