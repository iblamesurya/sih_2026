import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import FarmMap from './pages/FarmMap';
import MarketPrices from './pages/MarketPrices';
import Announcements from './pages/Announcements';

function PlaceholderPage({ title, description }) {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div>
        <h2 className="font-heading text-2xl font-bold tracking-tight text-white">
          {title}
        </h2>
        <p className="text-sm text-slate-400">{description}</p>
      </div>
      <div className="rounded-2xl bg-[#171717] border border-white/[0.08] p-12 text-center text-slate-400">
        <p className="font-mono text-sm">Module assigned to separate sub-team feature branch.</p>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="farm-map" element={<FarmMap />} />
          <Route
            path="disease-scans"
            element={
              <PlaceholderPage
                title="Disease Scans & AI Vision Diagnostics"
                description="Pathology vision history and Gemini Flash triage logs."
              />
            }
          />
          <Route path="market" element={<MarketPrices />} />
          <Route path="announcements" element={<Announcements />} />
          <Route
            path="users"
            element={
              <PlaceholderPage
                title="User Management"
                description="Farmer and field officer role access control."
              />
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
