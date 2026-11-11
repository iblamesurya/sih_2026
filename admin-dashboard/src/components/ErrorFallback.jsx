import React, { useState } from 'react';
import { AlertTriangle, RefreshCw, Home, ChevronDown, ChevronUp, Copy, Check } from 'lucide-react';

export default function ErrorFallback({
  error,
  resetErrorBoundary,
  title = 'Module Error Encountered',
  description = 'An unexpected runtime error occurred while rendering this dashboard component.',
}) {
  const [showDetails, setShowDetails] = useState(false);
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    const text = `${error?.toString()}\n\nStack:\n${error?.stack || 'No stack trace available'}`;
    navigator.clipboard?.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="rounded-2xl bg-[#171717] border border-[#E55C5C]/30 p-8 shadow-2xl max-w-3xl mx-auto my-8">
      {/* Alert Header */}
      <div className="flex items-start gap-4">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#E55C5C]/15 border border-[#E55C5C]/30 text-[#E55C5C]">
          <AlertTriangle className="h-6 w-6" />
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h3 className="font-heading text-lg font-bold text-white">{title}</h3>
            <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-[#E55C5C]/20 text-[#E55C5C] border border-[#E55C5C]/40">
              Fault Isolated
            </span>
          </div>
          <p className="mt-1 text-sm text-slate-300">{description}</p>
        </div>
      </div>

      {/* Error Message Box */}
      <div className="mt-6 rounded-xl bg-[#0A0A0B] border border-white/[0.06] p-4">
        <div className="flex items-center justify-between text-xs text-slate-400 pb-2 border-b border-white/[0.04]">
          <span className="font-mono text-[#E55C5C]">
            {error?.name || 'Error'}: {error?.message || 'Unknown runtime error'}
          </span>
          <button
            onClick={handleCopy}
            className="flex items-center gap-1 text-[11px] text-slate-400 hover:text-white transition-colors"
          >
            {copied ? (
              <>
                <Check className="h-3.5 w-3.5 text-[#10B981]" />
                <span className="text-[#10B981]">Copied</span>
              </>
            ) : (
              <>
                <Copy className="h-3.5 w-3.5" />
                <span>Copy Trace</span>
              </>
            )}
          </button>
        </div>

        {/* Collapsible Stack Trace */}
        <button
          onClick={() => setShowDetails(!showDetails)}
          className="mt-3 flex items-center gap-1 text-xs text-slate-400 hover:text-slate-200 transition-colors"
        >
          {showDetails ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
          <span>{showDetails ? 'Hide technical stack' : 'View technical stack trace'}</span>
        </button>

        {showDetails && (
          <pre className="mt-3 max-h-48 overflow-auto text-[11px] font-mono text-slate-400 p-2 rounded bg-black/40 whitespace-pre-wrap">
            {error?.stack || 'No stack trace captured.'}
          </pre>
        )}
      </div>

      {/* Recovery Actions */}
      <div className="mt-6 pt-4 border-t border-white/[0.06] flex flex-wrap items-center justify-between gap-3">
        <span className="text-xs text-slate-400">
          State safety boundary active • Telemetry daemon unharmed
        </span>

        <div className="flex items-center gap-3">
          {resetErrorBoundary && (
            <button
              onClick={resetErrorBoundary}
              className="flex items-center gap-2 rounded-xl bg-[#00E5FF] px-4 py-2 text-xs font-bold text-[#0A0A0B] hover:bg-[#00E5FF]/90 transition-all shadow-md shadow-[#00E5FF]/20"
            >
              <RefreshCw className="h-3.5 w-3.5" />
              <span>Retry Component</span>
            </button>
          )}

          <button
            onClick={() => window.location.reload()}
            className="flex items-center gap-2 rounded-xl bg-[#171717] border border-white/[0.1] px-4 py-2 text-xs font-medium text-slate-200 hover:text-white hover:border-white/20 transition-all"
          >
            <RefreshCw className="h-3.5 w-3.5 text-slate-400" />
            <span>Reload Page</span>
          </button>

          <a
            href="/"
            className="flex items-center gap-2 rounded-xl bg-[#171717] border border-white/[0.1] px-4 py-2 text-xs font-medium text-slate-200 hover:text-white hover:border-white/20 transition-all"
          >
            <Home className="h-3.5 w-3.5 text-slate-400" />
            <span>Dashboard</span>
          </a>
        </div>
      </div>
    </div>
  );
}
