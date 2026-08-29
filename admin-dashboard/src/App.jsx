import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import FarmMap from './pages/FarmMap';

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
                description="Pathology vision history and Gemini 2.0 triage logs."
              />
            }
          />
          <Route
            path="market"
            element={
              <PlaceholderPage
                title="Market Prices & Mandi Rates"
                description="Live shrimp procurement rates across regional hubs."
              />
            }
          />
          <Route
            path="announcements"
            element={
              <PlaceholderPage
                title="Broadcasts & Announcements"
                description="Farmer advisory broadcasts and regional weather alerts."
              />
            }
          />
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
