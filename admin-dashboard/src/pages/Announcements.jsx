import React, { useState } from 'react';
import {
  Megaphone,
  Plus,
  Radio,
  Send,
  AlertTriangle,
  CheckCircle2,
  Trash2,
  Globe,
  BellRing,
  Calendar,
  Filter
} from 'lucide-react';

const INITIAL_ANNOUNCEMENTS = [
  {
    id: 'ann_1',
    title: 'Severe Cyclone Warning & Pond Aerator Precaution Advisory',
    teluguTitle: 'తీవ్ర తుఫాను హెచ్చరిక - చెరువులలో ఏరేటర్ల నిర్వహణ జాగ్రత్తలు',
    body: 'IMD forecasts heavy squalls across Coastal Andhra (West Godavari & Krishna). Farmers are advised to maintain backup diesel generators and increase evening DO monitoring.',
    category: 'Weather Advisory',
    priority: 'Critical',
    targetRegion: 'West Godavari, Krishna, Guntur',
    author: 'State Fisheries Dept & PrawnGuard AI',
    timestamp: 'Today, 07:15 AM',
    recipientCount: 840,
    status: 'Active',
  },
  {
    id: 'ann_2',
    title: 'WSSV Early Outbreak Alert in Bhimavaram Cluster',
    teluguTitle: 'భీమవరం పరిసరాలలో తెల్లమచ్చ వ్యాధి హెచ్చరిక',
    body: 'Multiple confirmed WSSV detections reported within 10km radius. Activate strict biosecurity protocols, bird netting, and avoid untreated water intake.',
    category: 'Disease Warning',
    priority: 'High',
    targetRegion: 'Bhimavaram Hub',
    author: 'PrawnDoc Pathology Center',
    timestamp: 'Yesterday, 04:30 PM',
    recipientCount: 420,
    status: 'Active',
  },
  {
    id: 'ann_3',
    title: 'Government Subsidy Notification for Solar Aerators',
    teluguTitle: 'సోలార్ ఏరేటర్ల కొనుగోలుపై ప్రభుత్వ రాయితీ వివరాలు',
    body: 'Applications open for 40% capital subsidy on BLDC solar paddlewheel aerators under PMMSY scheme. Register at district fisheries office before Sep 15.',
    category: 'Scheme & Subsidy',
    priority: 'Normal',
    targetRegion: 'All Andhra Pradesh',
    author: 'Aquaculture Development Authority',
    timestamp: 'Aug 27, 2026',
    recipientCount: 1280,
    status: 'Active',
  },
];

export default function Announcements() {
  const [announcements, setAnnouncements] = useState(INITIAL_ANNOUNCEMENTS);
  const [showModal, setShowModal] = useState(false);
  const [filterCategory, setFilterCategory] = useState('All');
  const [toastMessage, setToastMessage] = useState('');

  // Form state
  const [formTitle, setFormTitle] = useState('');
  const [formTeluguTitle, setFormTeluguTitle] = useState('');
  const [formBody, setFormBody] = useState('');
  const [formCategory, setFormCategory] = useState('Disease Warning');
  const [formPriority, setFormPriority] = useState('High');
  const [formRegion, setFormRegion] = useState('All Andhra Pradesh');

  const handleCreateAnnouncement = (e) => {
    e.preventDefault();
    if (!formTitle || !formBody) return;

    const newAnn = {
      id: `ann_${Date.now()}`,
      title: formTitle,
      teluguTitle: formTeluguTitle || formTitle,
      body: formBody,
      category: formCategory,
      priority: formPriority,
      targetRegion: formRegion,
      author: 'Admin Central',
      timestamp: 'Just now',
      recipientCount: 1280,
      status: 'Active',
    };

    setAnnouncements([newAnn, ...announcements]);
    setShowModal(false);
    setFormTitle('');
    setFormTeluguTitle('');
    setFormBody('');
    setToastMessage(`Broadcasted announcement to ${newAnn.recipientCount} farmers!`);
    setTimeout(() => setToastMessage(''), 5000);
  };

  const handleDelete = (id) => {
    setAnnouncements(announcements.filter((a) => a.id !== id));
    setToastMessage('Announcement removed from active farmer feeds.');
    setTimeout(() => setToastMessage(''), 3000);
  };

  const filteredAnnouncements = filterCategory === 'All'
    ? announcements
    : announcements.filter((a) => a.category === filterCategory);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="font-heading text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <Megaphone className="h-6 w-6 text-[#00E5FF]" />
            Broadcasts & Announcements
          </h2>
          <p className="text-sm text-slate-400">
            Publish critical weather alerts, disease outbreak warnings, and government schemes to mobile app users.
          </p>
        </div>

        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 rounded-xl bg-[#00E5FF] px-4 py-2.5 text-sm font-bold text-[#0A0A0B] hover:bg-[#00E5FF]/90 transition-all shadow-lg shadow-[#00E5FF]/20"
        >
          <Plus className="h-4 w-4" />
          <span>New Broadcast</span>
        </button>
      </div>

      {/* Toast Notification */}
      {toastMessage && (
        <div className="flex items-center gap-3 rounded-xl bg-[#10B981]/15 border border-[#10B981] p-4 text-sm text-[#10B981] animate-fade-in">
          <CheckCircle2 className="h-5 w-5 shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Filters Bar */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        <Filter className="h-4 w-4 text-slate-400 shrink-0" />
        <span className="text-xs text-slate-400 shrink-0 font-medium">Category:</span>
        {['All', 'Disease Warning', 'Weather Advisory', 'Scheme & Subsidy'].map((cat) => (
          <button
            key={cat}
            onClick={() => setFilterCategory(cat)}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all ${
              filterCategory === cat
                ? 'bg-[#00E5FF]/20 text-[#00E5FF] border border-[#00E5FF]/50'
                : 'bg-[#171717] text-slate-400 border border-white/[0.06] hover:text-white'
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Announcements Feed */}
      <div className="space-y-4">
        {filteredAnnouncements.map((item) => (
          <div
            key={item.id}
            className="rounded-2xl bg-[#171717] border border-white/[0.08] p-6 shadow-lg hover:border-white/[0.15] transition-all"
          >
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div className="flex items-center gap-2">
                <span
                  className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full ${
                    item.priority === 'Critical'
                      ? 'bg-[#E55C5C]/20 text-[#E55C5C] border border-[#E55C5C]/40'
                      : (item.priority === 'High'
                          ? 'bg-[#E5B05C]/20 text-[#E5B05C] border border-[#E5B05C]/40'
                          : 'bg-[#00E5FF]/20 text-[#00E5FF] border border-[#00E5FF]/40')
                  }`}
                >
                  {item.priority} Priority
                </span>
                <span className="text-xs text-slate-400 font-mono">• {item.category}</span>
                <span className="text-xs text-slate-400">• Target: {item.targetRegion}</span>
              </div>

              <div className="flex items-center gap-3">
                <span className="text-xs text-slate-500 font-mono">{item.timestamp}</span>
                <button
                  onClick={() => handleDelete(item.id)}
                  className="text-slate-500 hover:text-[#E55C5C] transition-colors p-1"
                  title="Delete Announcement"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>

            <div className="mt-3 space-y-2">
              <h3 className="font-heading text-lg font-bold text-white">
                {item.title}
              </h3>
              {item.teluguTitle && item.teluguTitle !== item.title && (
                <p className="text-sm font-semibold text-[#00E5FF]">
                  {item.teluguTitle}
                </p>
              )}
              <p className="text-sm text-slate-300 leading-relaxed">
                {item.body}
              </p>
            </div>

            <div className="mt-4 pt-3 border-t border-white/[0.06] flex items-center justify-between text-xs text-slate-500">
              <span>Author: {item.author}</span>
              <div className="flex items-center gap-1.5 text-[#10B981]">
                <Radio className="h-3.5 w-3.5 animate-pulse" />
                <span>Delivered to {item.recipientCount} Farmers</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Create Announcement Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-sm p-4">
          <div className="w-full max-w-lg rounded-2xl bg-[#171717] border border-white/[0.1] p-6 shadow-2xl">
            <h3 className="font-heading text-lg font-bold text-white mb-1">
              Create Push Announcement
            </h3>
            <p className="text-xs text-slate-400 mb-4">
              Broadcast high-priority notifications to registered aquaculture farmers.
            </p>

            <form onSubmit={handleCreateAnnouncement} className="space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Category</label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                  >
                    <option value="Disease Warning">Disease Warning</option>
                    <option value="Weather Advisory">Weather Advisory</option>
                    <option value="Scheme & Subsidy">Scheme & Subsidy</option>
                    <option value="Market Bulletin">Market Bulletin</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">Priority</label>
                  <select
                    value={formPriority}
                    onChange={(e) => setFormPriority(e.target.value)}
                    className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                  >
                    <option value="Critical">Critical (Immediate Alert)</option>
                    <option value="High">High Priority</option>
                    <option value="Normal">Normal</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Target Geographic Zone</label>
                <select
                  value={formRegion}
                  onChange={(e) => setFormRegion(e.target.value)}
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                >
                  <option value="All Andhra Pradesh">All Andhra Pradesh (Statewide)</option>
                  <option value="West Godavari, Krishna, Guntur">West Godavari & Krishna Delta</option>
                  <option value="Nellore & Prakasam">Nellore & Prakasam Coastal</option>
                  <option value="Surat & South Gujarat">Surat & Gujarat Hub</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Title (English)</label>
                <input
                  type="text"
                  placeholder="e.g. Heavy Rain & DO Depletion Warning"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  required
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Title (Telugu - Optional)</label>
                <input
                  type="text"
                  placeholder="ఉదా: భారీ వర్షాలు మరియు ఆక్సిజన్ హెచ్చరిక"
                  value={formTeluguTitle}
                  onChange={(e) => setFormTeluguTitle(e.target.value)}
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">Message Content</label>
                <textarea
                  rows={3}
                  placeholder="Provide precise actionable steps for farmers..."
                  value={formBody}
                  onChange={(e) => setFormBody(e.target.value)}
                  required
                  className="w-full rounded-xl bg-[#0A0A0B] border border-white/[0.1] px-3 py-2 text-sm text-white focus:border-[#00E5FF] focus:outline-none"
                />
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
                  className="px-4 py-2 rounded-xl bg-[#00E5FF] text-[#0A0A0B] text-sm font-bold hover:bg-[#00E5FF]/90 shadow-lg shadow-[#00E5FF]/20 flex items-center gap-2"
                >
                  <Send className="h-4 w-4" />
                  <span>Send Broadcast</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
