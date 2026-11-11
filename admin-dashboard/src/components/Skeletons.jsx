import React from 'react';

/**
 * SkeletonCard — Placeholder for KPI cards and Market rate cards.
 * Deep Ocean Matte styling with gentle shimmer pulse.
 */
export function SkeletonCard({ count = 1, className = '' }) {
  const items = Array.from({ length: count });
  return (
    <>
      {items.map((_, i) => (
        <div
          key={i}
          className={`relative overflow-hidden rounded-2xl bg-[#171717] p-5 border border-white/[0.08] shadow-lg animate-pulse ${className}`}
        >
          {/* Top row: Icon placeholder & badge placeholder */}
          <div className="flex items-center justify-between">
            <div className="h-11 w-11 rounded-xl bg-white/[0.06]" />
            <div className="h-6 w-16 rounded-full bg-white/[0.06]" />
          </div>

          {/* Metric value and title placeholder */}
          <div className="mt-4 space-y-2">
            <div className="h-3 w-28 rounded bg-white/[0.05]" />
            <div className="h-8 w-20 rounded bg-white/[0.08]" />
          </div>

          {/* Sparkline placeholder */}
          <div className="mt-4 h-12 w-full rounded-lg bg-white/[0.03]" />
        </div>
      ))}
    </>
  );
}

/**
 * SkeletonChart — Placeholder for Recharts Area and Line charts.
 */
export function SkeletonChart({ height = 'h-72', title = true, className = '' }) {
  return (
    <div
      className={`rounded-2xl bg-[#171717] border border-white/[0.08] p-6 shadow-lg animate-pulse ${className}`}
    >
      {title && (
        <div className="mb-6 space-y-2">
          <div className="h-5 w-48 rounded bg-white/[0.08]" />
          <div className="h-3 w-80 rounded bg-white/[0.04]" />
        </div>
      )}

      {/* Chart body placeholder with vertical grid lines */}
      <div className={`${height} w-full rounded-xl bg-white/[0.02] border border-white/[0.04] p-4 flex items-end justify-between gap-3`}>
        {Array.from({ length: 12 }).map((_, idx) => (
          <div
            key={idx}
            className="w-full rounded-t bg-white/[0.05]"
            style={{ height: `${25 + (idx % 5) * 15}%` }}
          />
        ))}
      </div>
    </div>
  );
}

/**
 * SkeletonTable — Placeholder for tabular feeds (e.g. Recent Scans).
 */
export function SkeletonTable({ rows = 4, className = '' }) {
  return (
    <div
      className={`rounded-2xl bg-[#171717] p-6 border border-white/[0.08] animate-pulse ${className}`}
    >
      <div className="flex items-center justify-between pb-4 border-b border-white/[0.06]">
        <div className="space-y-2">
          <div className="h-5 w-44 rounded bg-white/[0.08]" />
          <div className="h-3 w-64 rounded bg-white/[0.04]" />
        </div>
        <div className="h-4 w-20 rounded bg-white/[0.05]" />
      </div>

      <div className="mt-4 space-y-3">
        {/* Table Header */}
        <div className="grid grid-cols-5 gap-4 py-2 border-b border-white/[0.04]">
          <div className="h-3 w-20 rounded bg-white/[0.04]" />
          <div className="h-3 w-16 rounded bg-white/[0.04]" />
          <div className="h-3 w-24 rounded bg-white/[0.04]" />
          <div className="h-3 w-16 rounded bg-white/[0.04]" />
          <div className="h-3 w-12 ml-auto rounded bg-white/[0.04]" />
        </div>

        {/* Table Rows */}
        {Array.from({ length: rows }).map((_, idx) => (
          <div
            key={idx}
            className="grid grid-cols-5 gap-4 py-3 items-center border-b border-white/[0.02]"
          >
            <div className="h-4 w-32 rounded bg-white/[0.06]" />
            <div className="h-3 w-24 rounded bg-white/[0.05]" />
            <div className="h-3 w-36 rounded bg-white/[0.05]" />
            <div className="h-5 w-16 rounded-full bg-white/[0.06]" />
            <div className="h-3 w-14 ml-auto rounded bg-white/[0.04]" />
          </div>
        ))}
      </div>
    </div>
  );
}

/**
 * SkeletonAnnouncement — Placeholder for regional broadcast alert cards.
 */
export function SkeletonAnnouncement({ count = 3, className = '' }) {
  const items = Array.from({ length: count });
  return (
    <div className={`space-y-4 ${className}`}>
      {items.map((_, i) => (
        <div
          key={i}
          className="rounded-2xl bg-[#171717] border border-white/[0.08] p-6 shadow-lg animate-pulse"
        >
          {/* Header row: badge, category, timestamp */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="h-5 w-24 rounded-full bg-white/[0.07]" />
              <div className="h-3 w-28 rounded bg-white/[0.04]" />
            </div>
            <div className="h-3 w-16 rounded bg-white/[0.04]" />
          </div>

          {/* Titles */}
          <div className="mt-4 space-y-2">
            <div className="h-5 w-3/4 rounded bg-white/[0.08]" />
            <div className="h-4 w-1/2 rounded bg-white/[0.05]" />
          </div>

          {/* Body lines */}
          <div className="mt-3 space-y-1.5">
            <div className="h-3 w-full rounded bg-white/[0.04]" />
            <div className="h-3 w-5/6 rounded bg-white/[0.04]" />
          </div>

          {/* Footer */}
          <div className="mt-4 pt-3 border-t border-white/[0.06] flex items-center justify-between">
            <div className="h-3 w-32 rounded bg-white/[0.04]" />
            <div className="h-3 w-36 rounded bg-white/[0.05]" />
          </div>
        </div>
      ))}
    </div>
  );
}
