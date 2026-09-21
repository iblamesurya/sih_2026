import React, { useState } from 'react';
import {
  TrendingUp,
  MapPin,
  Plus,
  RefreshCw,
  ArrowUpRight,
  ArrowDownRight,
  DollarSign,
  Calendar,
  Building,
  CheckCircle2,
  Bell
} from 'lucide-react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Legend
} from 'recharts';

const REGIONAL_HUBS = [
  'Bhimavaram (West Godavari, AP)',
  'Nellore (Andhra Pradesh)',
  'Surat (Gujarat)',
  'Kakinada (East Godavari, AP)',
  'Machilipatnam (Krishna, AP)'
];

const INITIAL_PRICES = [
  { count: '30 Count', price: 420, change: '+₹15', isUp: true, demand: 'High', updated: 'Today, 08:30 AM' },
  { count: '40 Count', price: 360, change: '+₹10', isUp: true, demand: 'Very High', updated: 'Today, 08:30 AM' },
  { count: '50 Count', price: 310, change: '-₹5', isUp: false, demand: 'Stable', updated: 'Today, 08:30 AM' },
  { count: '60 Count', price: 275, change: '+₹5', isUp: true, demand: 'Moderate', updated: 'Today, 08:30 AM' },
  { count: '80 Count', price: 230, change: '0', isUp: true, demand: 'Stable', updated: 'Today, 08:30 AM' },
  { count: '100 Count', price: 195, change: '-₹10', isUp: false, demand: 'Low', updated: 'Today, 08:30 AM' },
];

const HISTORICAL_TRENDS = [
  { date: 'Aug 1', count30: 395, count40: 340, count50: 295 },
  { date: 'Aug 6', count30: 400, count40: 345, count50: 300 },
  { date: 'Aug 11', count30: 408, count40: 350, count50: 305 },
  { date: 'Aug 16', count30: 412, count40: 352, count50: 308 },
  { date: 'Aug 21', count30: 415, count40: 355, count50: 312 },
  { date: 'Aug 26', count30: 418, count40: 358, count50: 310 },
  { date: 'Aug 29', count30: 420, count40: 360, count50: 310 },
];

export default function MarketPrices() {
  const [selectedHub, setSelectedHub] = useState(REGIONAL_HUBS[0]);
  const [prices, setPrices] = useState(INITIAL_PRICES);
  const [showModal, setShowModal] = useState(false);
  const [notification, setNotification] = useState('');

  // Form state
  const [formCount, setFormCount] = useState('30 Count');
  const [formPrice, setFormPrice] = useState('');
  const [formDemand, setFormDemand] = useState('High');

  const handleAddPrice = (e) => {
    e.preventDefault();
    if (!formPrice) return;

    const newPriceVal = parseFloat(formPrice);
    const updated = prices.map((p) => {
      if (p.count === formCount) {
        const diff = newPriceVal - p.price;
        return {
          ...p,
          price: newPriceVal,
          change: diff >= 0 ? `+₹${diff.toFixed(0)}` : `-₹${Math.abs(diff).toFixed(0)}`,
          isUp: diff >= 0,
          demand: formDemand,
          updated: 'Just now',
        };
      }
      return p;
    });

    setPrices(updated);
    setShowModal(false);
    setFormPrice('');
    setNotification(`Updated ${formCount} rate to ₹${newPriceVal}/kg in ${selectedHub}`);
    setTimeout(() => setNotification(''), 4000);
  };

  const handleBroadcast = () => {
    setNotification(`Broadcasted latest mandi price bulletin to 1,280 farmers via SMS & App Push!`);
    setTimeout(() => setNotification(''), 5000);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="font-heading text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <TrendingUp className="h-6 w-6 text-[#00E5FF]" />
            Live Market Prices & Mandi Rates
          </h2>
          <p className="text-sm text-slate-400">
            Real-time shrimp procurement benchmarks across major processing and exporting hubs.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={handleBroadcast}
            className="flex items-center gap-2 rounded-xl bg-[#171717] border border-white/[0.08] px-4 py-2 text-sm font-medium text-slate-200 hover:border-[#00E5FF]/40 hover:text-white transition-all shadow-sm"
          >
            <Bell className="h-4 w-4 text-[#00E5FF]" />
            <span>Broadcast Bulletin</span>
          </button>
          <button
            onClick={() => setShowModal(true)}
            className="flex items-center gap-2 rounded-xl bg-[#00E5FF] px-4 py-2 text-sm font-bold text-[#0A0A0B] hover:bg-[#00E5FF]/90 transition-all shadow-lg shadow-[#00E5FF]/20"
          >
            <Plus className="h-4 w-4" />
            <span>Update Rate</span>
          </button>
        </div>
      </div>

      {/* Success Notification Banner */}
      {notification && (
        <div className="flex items-center gap-3 rounded-xl bg-[#10B981]/15 border border-[#10B981] p-4 text-sm text-[#10B981] animate-fade-in">
          <CheckCircle2 className="h-5 w-5 shrink-0" />
          <span>{notification}</span>
        </div>
      )}

      {/* Regional Hub Selector Strip */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2">
        <MapPin className="h-4 w-4 text-slate-400 shrink-0" />
        <span className="text-xs text-slate-400 shrink-0 font-medium">Regional Mandi:</span>
        {REGIONAL_HUBS.map((hub) => (
          <button
            key={hub}
            onClick={() => setSelectedHub(hub)}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all ${
              selectedHub === hub
                ? 'bg-[#00E5FF]/20 text-[#00E5FF] border border-[#00E5FF]/50'
                : 'bg-[#171717] text-slate-400 border border-white/[0.06] hover:text-white'
            }`}
          >
            {hub}
          </button>
        ))}
      </div>

      {/* Pricing Cards Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        {prices.map((item) => (
          <div
            key={item.count}
            className="rounded-2xl bg-[#171717] border border-white/[0.08] p-5 shadow-lg flex flex-col justify-between hover:border-[#00E5FF]/30 transition-all"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold font-mono text-slate-400">{item.count}</span>
              <span
                className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                  item.demand === 'High' || item.demand === 'Very High'
                    ? 'bg-[#10B981]/15 text-[#10B981] border border-[#10B981]/30'
                    : 'bg-slate-800 text-slate-400'
                }`}
              >
                {item.demand}
              </span>
            </div>

            <div className="my-4">
              <div className="text-2xl font-bold font-heading text-white">
                ₹{item.price}
                <span className="text-xs font-normal text-slate-400 ml-1">/kg</span>
              </div>
              <div className="flex items-center gap-1 mt-1 text-xs">
                {item.isUp ? (
                  <span className="flex items-center text-[#10B981] font-semibold">
                    <ArrowUpRight className="h-3.5 w-3.5" />
                    {item.change}
                  </span>
                ) : (
                  <span className="flex items-center text-[#E55C5C] font-semibold">
                    <ArrowDownRight className="h-3.5 w-3.5" />
                    {item.change}
                  </span>
                )}
                <span className="text-slate-500">• 24h</span>
              </div>
            </div>

            <div className="text-[10px] text-slate-500 font-mono">
              {item.updated}
            </div>
          </div>
        ))}
      </div>

      {/* 30-Day Trend Chart */}
      <div className="rounded-2xl bg-[#171717] border border-white/[0.08] p-6 shadow-lg">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="font-heading text-base font-bold text-white">
              Historical Price Trends ({selectedHub})
            </h3>
            <p className="text-xs text-slate-400">
              Procurement price movement for top commercial count sizes over 30 days (₹/kg)
            </p>
          </div>
        </div>

        <div className="h-72 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={HISTORICAL_TRENDS}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ffffff10" vertical={false} />
              <XAxis dataKey="date" stroke="#64748b" fontSize={11} tickLine={false} />
              <YAxis stroke="#64748b" fontSize={11} domain={[280, 440]} tickLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#0A0A0B',
                  borderColor: '#ffffff20',
                  borderRadius: '0.75rem',
                  color: '#fff',
                  fontSize: '12px',
                }}
              />
              <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
              <Line type="monotone" dataKey="count30" name="30 Count" stroke="#00E5FF" strokeWidth={2} dot={{ r: 3 }} />
              <Line type="monotone" dataKey="count40" name="40 Count" stroke="#10B981" strokeWidth={2} dot={{ r: 3 }} />
              <Line type="monotone" dataKey="count50" name="50 Count" stroke="#E5B05C" strokeWidth={2} dot={{ r: 3 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Modal Dialog for Updating Price */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl bg-[#171717] border border-white/[0.1] p-6 shadow-2xl">
            <h3 className="font-heading text-lg font-bold text-white mb-1">
              Update Mandi Benchmark Rate
            </h3>
            <p className="text-xs text-slate-400 mb-4">
              Enter official procurement rate for {selectedHub}
            </p>

            <form onSubmit={handleAddPrice} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Shrimp Count Category
                </label>
                <select
                  value={formCount}
                  onChange={(e) => setFormCount(e.target.value)}
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                >
                  {INITIAL_PRICES.map((p) => (
                    <option key={p.count} value={p.count}>{p.count}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  New Price (₹ / kg)
                </label>
                <input
                  type="number"
                  placeholder="e.g. 425"
                  value={formPrice}
                  onChange={(e) => setFormPrice(e.target.value)}
                  required
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Buyer Demand Level
                </label>
                <select
                  value={formDemand}
                  onChange={(e) => setFormDemand(e.target.value)}
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                >
                  <option value="Very High">Very High (Exporters Aggressive)</option>
                  <option value="High">High</option>
                  <option value="Stable">Stable</option>
                  <option value="Moderate">Moderate</option>
                  <option value="Low">Low</option>
                </select>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-white/[0.08]">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 rounded-xl text-sm text-slate-400 hover:text-white font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-[#00E5FF] text-[#0A0A0B] text-sm font-bold hover:bg-[#00E5FF]/90 shadow-lg shadow-[#00E5FF]/20"
                >
                  Save & Publish Rate
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
