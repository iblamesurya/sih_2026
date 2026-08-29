import React from 'react';
import {
  Waves,
  Users,
  ScanEye,
  AlertTriangle,
  ArrowUpRight,
  ArrowDownRight,
  TrendingUp,
  Activity,
  CheckCircle2,
  Droplets,
  Thermometer,
  ShieldCheck
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  Tooltip
} from 'recharts';

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

const KPI_CARDS = [
  {
    id: 'ponds',
    title: 'Total Active Ponds',
    value: '142',
    change: '+12.4%',
    changeType: 'positive',
    timeframe: 'vs last month',
    icon: Waves,
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
    icon: Users,
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
    icon: ScanEye,
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
    icon: AlertTriangle,
    accentColor: '#E55C5C',
    accentBg: 'rgba(229, 92, 92, 0.1)',
    data: alertsSparkline,
    gradientId: 'alertsGrad',
  },
];

// Mock recent disease detections
const RECENT_SCANS = [
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

export default function Dashboard() {
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
          <div className="inline-flex items-center gap-2 rounded-xl bg-[#171717] px-3.5 py-2 border border-white/[0.08] text-xs font-medium text-slate-300">
            <ShieldCheck className="h-4 w-4 text-[#10B981]" />
            <span>Gemini Vision 2.0 Active</span>
          </div>
        </div>
      </div>

      {/* 4 KPI Cards (Responsive Grid 1 / 2 / 4) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {KPI_CARDS.map((card) => {
          const Icon = card.icon;
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
        })}
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
        <div className="lg:col-span-2 rounded-2xl bg-[#171717] p-6 border border-white/[0.08]">
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
            <span className="text-xs text-slate-400">Latest 4 scans</span>
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
                {RECENT_SCANS.map((scan) => (
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
      </div>
    </div>
  );
}
