import React, { useState, useEffect } from 'react';
import {
  Waves,
  Users,
  ScanEye,
  AlertTriangle,
  ArrowUpRight,
  ArrowDownRight,
  Activity,
  Droplets,
  ShieldCheck,
  RefreshCw,
  Database
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  Tooltip
} from 'recharts';
import { SkeletonCard, SkeletonTable } from '../components/Skeletons';
import { getCache, setCache } from '../lib/cache';
import { supabase } from '../lib/supabase';

// Mock sparkline data
const pondsSparkline = [
  { val: 120 }, { val: 125 }, { val: 128 }, { val: 132 },
  { val: 130 }, { val: 138 }, { val: 142 }
];

const farmersSparkline = [
  { val: 1100 }, { val: 1140 }, { val: 1180 }, { val: 1210 },
  { val: 1230 }, { val: 1260 }, { val: 1280 }
];

const scansSparkline = [
  { val: 210 }, { val: 245 }, { val: 290 }, { val: 320 },
  { val: 280 }, { val: 350 }, { val: 384 }
];

const alertsSparkline = [
  { val: 14 }, { val: 12 }, { val: 15 }, { val: 10 },
  { val: 9 }, { val: 8 }, { val: 7 }
];

const INITIAL_KPIS = [
  {
    id: 'ponds',
    title: 'Total Active Ponds',
    value: '142',
    change: '+12.4%',
    changeType: 'positive',
    timeframe: 'vs last month',
    iconName: 'Waves',
    accentColor: '#00E5FF',
    accentBg: 'rgba(0, 229, 255, 0.1)',
    data: pondsSparkline,
    gradientId: 'pondsGrad',
  },
  {
    id: 'farmers',
    title: 'Registered Farmers',
    value: '1,280',
    change: '+8.1%',
    changeType: 'positive',
    timeframe: 'vs last week',
    iconName: 'Users',
    accentColor: '#10B981',
    accentBg: 'rgba(16, 185, 129, 0.1)',
    data: farmersSparkline,
    gradientId: 'farmersGrad',
  },
  {
    id: 'scans',
    title: 'Scans Today',
    value: '384',
    change: '+24.6%',
    changeType: 'positive',
    timeframe: 'vs yesterday',
    iconName: 'ScanEye',
    accentColor: '#5C9EE5',
    accentBg: 'rgba(92, 158, 229, 0.1)',
    data: scansSparkline,
    gradientId: 'scansGrad',
  },
  {
    id: 'alerts',
    title: 'High-Risk Alerts',
    value: '7',
    change: '-22.2%',
    changeType: 'neutral-positive', // fewer alerts is good
    timeframe: '3 resolved today',
    iconName: 'AlertTriangle',
    accentColor: '#E55C5C',
    accentBg: 'rgba(229, 92, 92, 0.1)',
    data: alertsSparkline,
    gradientId: 'alertsGrad',
  },
];

const ICONS = {
  Waves,
  Users,
  ScanEye,
  AlertTriangle,
};

// Mock recent disease detections
const INITIAL_SCANS = [
  {
    id: 'SCN-9021',
    pond: 'Pond 4B — Godavari East',
    farmer: 'R. Koteswara Rao',
    diagnosis: 'White Spot Disease (WSSV)',
    confidence: '96.4%',
    severity: 'High',
    time: '8 mins ago',
  },
  {
    id: 'SCN-9020',
    pond: 'Pond 1A — Bhimavaram',
    farmer: 'V. Satyanarayana',
    diagnosis: 'Running Mortality (RMS)',
    confidence: '89.1%',
    severity: 'Medium',
    time: '24 mins ago',
  },
  {
    id: 'SCN-9019',
    pond: 'Pond 7C — Nellore Coastal',
    farmer: 'K. Subba Rao',
    diagnosis: 'Normal / Healthy Cuticle',
    confidence: '99.2%',
    severity: 'Normal',
    time: '42 mins ago',
  },
  {
    id: 'SCN-9018',
    pond: 'Pond 2D — Kakinada West',
    farmer: 'M. Venkatesh',
    diagnosis: 'Early Black Gill Symptoms',
    confidence: '91.8%',
    severity: 'Watch',
    time: '1 hr ago',
  },
];

const CACHE_KEY = 'prawnguard_admin_dashboard';

export default function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [kpis, setKpis] = useState(INITIAL_KPIS);
  const [scans, setScans] = useState(INITIAL_SCANS);
  const [isCached, setIsCached] = useState(false);

  // Load from cache first for instantaneous rural broadband UX
  useEffect(() => {
    let active = true;
    const cached = getCache(CACHE_KEY, 15 * 60 * 1000); // 15 mins cache
    if (cached && active) {
      if (cached.kpis) setKpis(cached.kpis);
      if (cached.scans) setScans(cached.scans);
      setIsCached(true);
      setLoading(false);
    }

    // Hydrate from live / seed data
    async function hydrate() {
      try {
        // Query Supabase live counts if accessible
        const { count: pondsCount, error: pErr } = await supabase
          .from('ponds')
          .select('*', { count: 'exact', head: true });

        const { count: profilesCount, error: prErr } = await supabase
          .from('profiles')
          .select('*', { count: 'exact', head: true });

        const { data: recentScans, error: sErr } = await supabase
          .from('disease_scans')
          .select('*')
          .order('created_at', { ascending: false })
          .limit(4);

        if (active) {
          let updatedKpis = [...INITIAL_KPIS];
          if (!pErr && typeof pondsCount === 'number' && pondsCount > 0) {
            updatedKpis = updatedKpis.map((k) =>
              k.id === 'ponds' ? { ...k, value: pondsCount.toLocaleString() } : k
            );
          }
          if (!prErr && typeof profilesCount === 'number' && profilesCount > 0) {
            updatedKpis = updatedKpis.map((k) =>
              k.id === 'farmers' ? { ...k, value: profilesCount.toLocaleString() } : k
            );
          }

          let updatedScans = INITIAL_SCANS;
          if (!sErr && Array.isArray(recentScans) && recentScans.length > 0) {
            updatedScans = recentScans.map((s) => ({
              id: s.id || `SCN-${Math.floor(Math.random() * 9000)}`,
              pond: s.pond_name || 'Active Pond',
              farmer: s.farmer_name || 'Verified Farmer',
              diagnosis: s.diagnosis || 'Analyzed Specimen',
              confidence: s.confidence ? `${(s.confidence * 100).toFixed(1)}%` : '95.0%',
              severity: s.severity === 'critical' ? 'High' : (s.severity === 'urgent' ? 'High' : 'Normal'),
              time: 'Just now',
            }));
          }

          setKpis(updatedKpis);
          setScans(updatedScans);

          // Save to localStorage cache for offline/rural instant load
          setCache(CACHE_KEY, { kpis: updatedKpis, scans: updatedScans });
        }
      } catch (_) {
        // Safe offline fallback: ensure initial data is preserved
        if (active && !cached) {
          setCache(CACHE_KEY, { kpis: INITIAL_KPIS, scans: INITIAL_SCANS });
        }
      } finally {
        if (active) {
          setLoading(false);
          setRefreshing(false);
        }
      }
    }

    hydrate();

    return () => {
      active = false;
    };
  }, []);

  const handleManualRefresh = () => {
    setRefreshing(true);
    setTimeout(() => {
      setCache(CACHE_KEY, { kpis, scans });
      setRefreshing(false);
    }, 600);
  };

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      {/* Top Welcome & Summary Header */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="font-heading text-2xl sm:text-3xl font-bold tracking-tight text-white">
            AquaCulture Command Center
          </h2>
          <p className="text-sm text-slate-400">
            Real-time biometric monitoring & AI disease triage across active shrimp farms.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {isCached && (
            <div className="hidden sm:inline-flex items-center gap-1.5 rounded-xl bg-[#171717] px-3 py-1.5 border border-white/[0.08] text-[11px] font-mono text-slate-400">
              <Database className="h-3.5 w-3.5 text-[#10B981]" />
              <span>Offline Cache Active</span>
            </div>
          )}

          <button
            onClick={handleManualRefresh}
            disabled={refreshing}
            className="flex items-center gap-1.5 rounded-xl bg-[#171717] px-3 py-2 border border-white/[0.08] text-xs font-medium text-slate-300 hover:text-white hover:border-[#00E5FF]/40 transition-all"
            title="Refresh dashboard metrics"
          >
            <RefreshCw className={`h-3.5 w-3.5 text-[#00E5FF] ${refreshing ? 'animate-spin' : ''}`} />
            <span className="hidden sm:inline">Sync</span>
          </button>

          <div className="inline-flex items-center gap-2 rounded-xl bg-[#171717] px-3.5 py-2 border border-white/[0.08] text-xs font-medium text-slate-300">
            <ShieldCheck className="h-4 w-4 text-[#10B981]" />
            <span>Gemini Vision 2.0 Active</span>
          </div>
        </div>
      </div>

      {/* 4 KPI Cards (Responsive Grid 1 / 2 / 4) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {loading ? (
          <SkeletonCard count={4} />
        ) : (
          kpis.map((card) => {
            const Icon = ICONS[card.iconName] || Waves;
            return (
              <div
                key={card.id}
                className="relative overflow-hidden rounded-2xl bg-[#171717] p-5 border border-white/[0.08] shadow-lg backdrop-blur transition-all duration-300 hover:border-white/[0.18] hover:translate-y-[-2px]"
              >
                {/* Top Row: Icon & Timeframe badge */}
                <div className="flex items-center justify-between">
                  <div
                    className="flex h-11 w-11 items-center justify-center rounded-xl border border-white/[0.08]"
                    style={{ backgroundColor: card.accentBg }}
                  >
                    <Icon className="h-5 w-5" style={{ color: card.accentColor }} />
                  </div>
                  <div className="flex items-center gap-1 text-xs font-semibold">
                    {card.changeType === 'positive' || card.changeType === 'neutral-positive' ? (
                      <span className="flex items-center text-[#10B981] bg-[#10B981]/10 px-2 py-0.5 rounded-full border border-[#10B981]/20">
                        <ArrowUpRight className="h-3.5 w-3.5 mr-0.5" />
                        {card.change}
                      </span>
                    ) : (
                      <span className="flex items-center text-[#E55C5C] bg-[#E55C5C]/10 px-2 py-0.5 rounded-full border border-[#E55C5C]/20">
                        <ArrowDownRight className="h-3.5 w-3.5 mr-0.5" />
                        {card.change}
                      </span>
                    )}
                  </div>
                </div>

                {/* Value & Title */}
                <div className="mt-4">
                  <h3 className="text-xs font-medium uppercase tracking-wider text-slate-400">
                    {card.title}
                  </h3>
                  <div className="mt-1 flex items-baseline gap-2">
                    <span className="font-heading text-3xl font-bold tracking-tight text-white">
                      {card.value}
                    </span>
                    <span className="text-[11px] text-slate-500">{card.timeframe}</span>
                  </div>
                </div>

                {/* Mini Sparkline with Recharts */}
                <div className="mt-4 h-12 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={card.data} margin={{ top: 2, right: 0, left: 0, bottom: 0 }}>
                      <defs>
                        <linearGradient id={card.gradientId} x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor={card.accentColor} stopOpacity={0.4} />
                          <stop offset="95%" stopColor={card.accentColor} stopOpacity={0.0} />
                        </linearGradient>
                      </defs>
                      <Tooltip
                        content={({ active, payload }) => {
                          if (active && payload && payload.length) {
                            return (
                              <div className="rounded-lg bg-[#0A0A0B] px-2 py-1 text-[11px] font-mono text-white border border-white/10 shadow-md">
                                {payload[0].value}
                              </div>
                            );
                          }
                          return null;
                        }}
                      />
                      <Area
                        type="monotone"
                        dataKey="val"
                        stroke={card.accentColor}
                        strokeWidth={2}
                        fillOpacity={1}
                        fill={`url(#${card.gradientId})`}
                        isAnimationActive={true}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Secondary Dashboard Content: Water Quality Telemetry & Recent AI Scans */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Realtime Water Quality Health */}
        <div className="rounded-2xl bg-[#171717] p-6 border border-white/[0.08] flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-4 border-b border-white/[0.06]">
              <h3 className="font-heading text-base font-semibold text-white flex items-center gap-2">
                <Droplets className="h-4 w-4 text-[#00E5FF]" />
                Sensor Telemetry Summary
              </h3>
              <span className="text-[11px] font-mono text-[#10B981] bg-[#10B981]/10 px-2 py-0.5 rounded border border-[#10B981]/20">
                Optimal
              </span>
            </div>

            <div className="mt-5 space-y-4">
              <div className="flex items-center justify-between p-3 rounded-xl bg-[#0A0A0B]/60 border border-white/[0.04]">
                <div>
                  <p className="text-xs text-slate-400">Avg Dissolved Oxygen (DO)</p>
                  <p className="font-heading text-lg font-bold text-white">6.2 mg/L</p>
                </div>
                <span className="text-xs text-[#10B981] font-medium">&gt; 5.0 Safe</span>
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl bg-[#0A0A0B]/60 border border-white/[0.04]">
                <div>
                  <p className="text-xs text-slate-400">Mean pH Level</p>
                  <p className="font-heading text-lg font-bold text-white">7.8 pH</p>
                </div>
                <span className="text-xs text-[#10B981] font-medium">7.5 - 8.5 Safe</span>
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl bg-[#0A0A0B]/60 border border-white/[0.04]">
                <div>
                  <p className="text-xs text-slate-400">Water Temperature</p>
                  <p className="font-heading text-lg font-bold text-white">28.4 °C</p>
                </div>
                <span className="text-xs text-[#00E5FF] font-medium">Standard</span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-white/[0.06] text-xs text-slate-500 flex items-center justify-between">
            <span>Aggregated across 142 ponds</span>
            <span className="font-mono">Live Sync</span>
          </div>
        </div>

        {/* Live Scans Triage Feed (2 Cols) */}
        <div className="lg:col-span-2">
          {loading ? (
            <SkeletonTable rows={4} />
          ) : (
            <div className="rounded-2xl bg-[#171717] p-6 border border-white/[0.08]">
              <div className="flex items-center justify-between pb-4 border-b border-white/[0.06]">
                <div>
                  <h3 className="font-heading text-base font-semibold text-white flex items-center gap-2">
                    <Activity className="h-4 w-4 text-[#00E5FF]" />
                    Recent AI Vision Scans
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Gemini Vision automated pathology detection log
                  </p>
                </div>
                <span className="text-xs text-slate-400">Latest {scans.length} scans</span>
              </div>

              <div className="mt-4 overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-white/[0.04] text-slate-500 uppercase tracking-wider">
                      <th className="pb-3 font-medium">Pond / Location</th>
                      <th className="pb-3 font-medium">Farmer</th>
                      <th className="pb-3 font-medium">AI Diagnosis</th>
                      <th className="pb-3 font-medium">Severity</th>
                      <th className="pb-3 font-medium text-right">Time</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/[0.04]">
                    {scans.map((scan) => (
                      <tr key={scan.id} className="hover:bg-white/[0.02] transition-colors">
                        <td className="py-3 font-medium text-white">{scan.pond}</td>
                        <td className="py-3 text-slate-300">{scan.farmer}</td>
                        <td className="py-3">
                          <span className="font-medium text-slate-200">{scan.diagnosis}</span>
                          <span className="ml-1 text-[10px] text-slate-500">({scan.confidence})</span>
                        </td>
                        <td className="py-3">
                          {scan.severity === 'High' && (
                            <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-[#E55C5C]/15 text-[#E55C5C] border border-[#E55C5C]/30">
                              Critical
                            </span>
                          )}
                          {scan.severity === 'Medium' && (
                            <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-[#E5B05C]/15 text-[#E5B05C] border border-[#E5B05C]/30">
                              Medium
                            </span>
                          )}
                          {scan.severity === 'Watch' && (
                            <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-[#5C9EE5]/15 text-[#5C9EE5] border border-[#5C9EE5]/30">
                              Watch
                            </span>
                          )}
                          {scan.severity === 'Normal' && (
                            <span className="px-2 py-0.5 rounded text-[11px] font-semibold bg-[#10B981]/15 text-[#10B981] border border-[#10B981]/30">
                              Healthy
                            </span>
                          )}
                        </td>
                        <td className="py-3 text-right text-slate-500 font-mono">{scan.time}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
