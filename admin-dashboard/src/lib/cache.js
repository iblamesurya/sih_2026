/**
 * Client-side caching helper for PrawnGuard Web Admin Portal.
 * Provides resilient localStorage caching with TTL and self-healing under corrupted or quota-exceeded local state.
 */

const DEFAULT_TTL_MS = 10 * 60 * 1000; // 10 minutes default TTL

export function getCache(key, maxAgeMs = DEFAULT_TTL_MS) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') {
      localStorage.removeItem(key);
      return null;
    }

    // Check expiration
    if (parsed.timestamp && Date.now() - parsed.timestamp > maxAgeMs) {
      localStorage.removeItem(key);
      return null;
    }
    return parsed.data;
  } catch (err) {
    console.warn(`[Cache] Corrupted entry for ${key}, self-healing by removal:`, err);
    try {
      localStorage.removeItem(key);
    } catch (_) {}
    return null;
  }
}

export function setCache(key, data) {
  try {
    const payload = {
      timestamp: Date.now(),
      data,
    };
    localStorage.setItem(key, JSON.stringify(payload));
  } catch (err) {
    console.warn(`[Cache] Failed to write ${key}:`, err);
    // QuotaExceededError recovery: purge expired or old cache entries
    try {
      const keysToClean = [];
      for (let i = 0; i < localStorage.length; i++) {
        const k = localStorage.key(i);
        if (k && k.startsWith('prawnguard_') && k !== key) {
          keysToClean.push(k);
        }
      }
      keysToClean.slice(0, 3).forEach((k) => localStorage.removeItem(k));
      // Retry setItem once after cleanup
      const payload = { timestamp: Date.now(), data };
      localStorage.setItem(key, JSON.stringify(payload));
    } catch (_) {}
  }
}

export function removeCache(key) {
  try {
    localStorage.removeItem(key);
  } catch (err) {
    console.warn(`[Cache] Failed to remove ${key}:`, err);
  }
}
