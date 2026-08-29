import React from 'react';
import { MapPin, Navigation, Info } from 'lucide-react';

export default function FarmMap() {
  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="font-heading text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <MapPin className="h-6 w-6 text-[#00E5FF]" />
            Geospatial Farm Map
          </h2>
          <p className="text-sm text-slate-400">
            Regional GPS clustering & satellite overlay for active aquaculture clusters.
          </p>
        </div>
      </div>

      <div className="relative flex flex-col items-center justify-center rounded-2xl bg-[#171717] border border-white/[0.08] p-12 text-center min-h-[460px] shadow-lg">
        <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#00E5FF]/10 text-[#00E5FF] border border-[#00E5FF]/20 mb-4">
          <Navigation className="h-8 w-8 animate-pulse" />
        </div>
        
        <h3 className="font-heading text-lg font-semibold text-white">
          Interactive Geospatial Visualization
        </h3>
        
        <p className="mt-2 text-sm text-slate-400 max-w-md font-mono text-center">
          Map will render Leaflet here - coords from profiles.last_gps_lat/lng
        </p>

        <div className="mt-6 flex items-center gap-2 rounded-xl bg-[#0A0A0B] px-4 py-2 border border-white/[0.06] text-xs text-slate-400">
          <Info className="h-4 w-4 text-[#00E5FF]" />
          <span>Leaflet integration scheduled for Phase 2 telemetry sync.</span>
        </div>
      </div>
    </div>
  );
}
