/**
 * Client-side caching helper for PrawnGuard Web Admin Portal.
 * Provides resilient localStorage caching with TTL for rural/slow broadband.
 */

const DEFAULT_TTL_MS = 10 * 60 * 1000; // 10 minutes default TTL

export function getCache(key, maxAgeMs = DEFAULT_TTL_MS) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') return null;

    // Check expiration
    if (parsed.timestamp && Date.now() - parsed.timestamp > maxAgeMs) {
      localStorage.removeItem(key);
      return null;
    }
    return parsed.data;
  } catch (err) {
    console.warn(`[Cache] Failed to read ${key}:`, err);
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
  }
}

export function removeCache(key) {
  try {
    localStorage.removeItem(key);
  } catch (err) {
    console.warn(`[Cache] Failed to remove ${key}:`, err);
  }
}
