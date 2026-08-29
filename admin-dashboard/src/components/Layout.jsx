import React, { useState } from 'react';
import { NavLink, Outlet, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  MapPin,
  Activity,
  TrendingUp,
  Megaphone,
  Users,
  Shield,
  Menu,
  X,
  Bell,
  Search,
  Radio,
  ExternalLink,
  ChevronRight
} from 'lucide-react';

const NAV_ITEMS = [
  { name: 'Dashboard', path: '/', icon: LayoutDashboard },
  { name: 'Farm Map', path: '/farm-map', icon: MapPin },
  { name: 'Disease Scans', path: '/disease-scans', icon: Activity },
  { name: 'Market Prices', path: '/market', icon: TrendingUp },
  { name: 'Announcements', path: '/announcements', icon: Megaphone },
  { name: 'Users', path: '/users', icon: Users },
];

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  const currentNav = NAV_ITEMS.find((item) => item.path === location.pathname) || {
    name: 'Dashboard',
  };

  return (
    <div className="flex min-h-screen bg-[#0A0A0B] text-slate-100 antialiased">
      {/* Mobile Backdrop */}
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 z-40 bg-black/70 backdrop-blur-sm lg:hidden transition-opacity"
        />
      )}

      {/* Sidebar */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex w-72 flex-col justify-between border-r border-white/[0.08] bg-[#0A0A0B]/95 backdrop-blur-xl transition-transform duration-300 ease-in-out lg:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Top Header / Logo */}
        <div>
          <div className="flex h-20 items-center justify-between px-6 border-b border-white/[0.06]">
            <div className="flex items-center gap-3">
              <div className="relative flex h-10 w-10 items-center justify-center rounded-xl bg-[#171717] border border-[#00E5FF]/30 shadow-[0_0_15px_rgba(0,229,255,0.2)]">
                <Shield className="h-5 w-5 text-[#00E5FF]" />
                <span className="absolute -top-0.5 -right-0.5 flex h-2.5 w-2.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#00E5FF] opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-[#00E5FF]"></span>
                </span>
              </div>
              <div>
                <h1 className="font-heading text-lg font-bold tracking-tight text-white flex items-center gap-1.5">
                  Prawn<span className="text-[#00E5FF]">Guard</span>
                  <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-[#00E5FF]/10 text-[#00E5FF] border border-[#00E5FF]/20">
                    Admin
                  </span>
                </h1>
                <p className="text-xs text-slate-400 font-medium">Deep Ocean Command</p>
              </div>
            </div>

            <button
              onClick={() => setSidebarOpen(false)}
              className="rounded-lg p-1.5 text-slate-400 hover:bg-white/[0.05] hover:text-white lg:hidden"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          {/* Navigation Links */}
          <nav className="mt-6 space-y-1.5 px-3">
            <div className="px-3 pb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-500 font-mono">
              Main Navigation
            </div>
            {NAV_ITEMS.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;
              return (
                <NavLink
                  key={item.path}
                  to={item.path}
                  onClick={() => setSidebarOpen(false)}
                  className={`group flex items-center gap-3.5 rounded-xl px-3.5 py-3 text-sm font-medium transition-all duration-200 ${
                    isActive
                      ? 'bg-[#171717] text-[#00E5FF] border border-[#00E5FF]/20 shadow-[0_0_20px_rgba(0,229,255,0.08)]'
                      : 'text-slate-400 hover:bg-[#171717]/60 hover:text-slate-100 hover:border hover:border-white/[0.04]'
                  }`}
                >
                  <Icon
                    className={`h-5 w-5 transition-transform duration-200 group-hover:scale-110 ${
                      isActive ? 'text-[#00E5FF]' : 'text-slate-400 group-hover:text-slate-200'
                    }`}
                  />
                  <span>{item.name}</span>
                  {isActive && (
                    <span className="ml-auto h-1.5 w-1.5 rounded-full bg-[#00E5FF] shadow-[0_0_8px_#00E5FF]" />
                  )}
                </NavLink>
              );
            })}
          </nav>
        </div>

        {/* Bottom Sidebar info & user card */}
        <div className="p-4 border-t border-white/[0.06] space-y-3">
          {/* Live Status indicator */}
          <div className="rounded-xl bg-[#171717] border border-white/[0.06] p-3">
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-2 text-slate-300 font-medium">
                <Radio className="h-3.5 w-3.5 text-[#10B981] animate-pulse" />
                Telemetry Live
              </span>
              <span className="text-[11px] font-mono text-[#00E5FF]">v0.1-dev</span>
            </div>
          </div>

          {/* User profile */}
          <div className="flex items-center gap-3 rounded-xl bg-[#171717]/50 border border-white/[0.04] p-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-tr from-[#00E5FF]/20 to-[#10B981]/20 text-white font-bold text-xs border border-white/10">
              VR
            </div>
            <div className="flex-1 min-w-0">
              <p className="truncate text-xs font-semibold text-white font-heading">
                Varshith Reddy
              </p>
              <p className="truncate text-[11px] text-slate-400">Portal Admin</p>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex flex-1 flex-col lg:pl-72">
        {/* Top Navbar */}
        <header className="sticky top-0 z-30 flex h-20 items-center justify-between border-b border-white/[0.08] bg-[#0A0A0B]/80 px-4 sm:px-8 backdrop-blur-md">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setSidebarOpen(true)}
              className="rounded-lg p-2 text-slate-400 hover:bg-[#171717] hover:text-white lg:hidden border border-white/[0.08]"
              aria-label="Open Sidebar"
            >
              <Menu className="h-5 w-5" />
            </button>

            <div className="flex items-center gap-2 text-sm">
              <span className="text-slate-400 font-medium">PrawnGuard</span>
              <ChevronRight className="h-4 w-4 text-slate-600" />
              <span className="font-heading font-semibold text-[#00E5FF]">
                {currentNav.name}
              </span>
            </div>
          </div>

          {/* Top Right Controls */}
          <div className="flex items-center gap-3">
            <div className="hidden md:flex items-center gap-2 rounded-xl bg-[#171717] px-3 py-1.5 border border-white/[0.08]">
              <Search className="h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search ponds, farmers, alerts..."
                className="bg-transparent text-xs text-white placeholder-slate-500 focus:outline-none w-48 lg:w-64"
                readOnly
              />
            </div>

            <button className="relative rounded-xl bg-[#171717] p-2.5 text-slate-300 hover:text-white border border-white/[0.08] hover:border-[#00E5FF]/30 transition-all">
              <Bell className="h-4 w-4" />
              <span className="absolute top-2 right-2 h-2 w-2 rounded-full bg-[#E55C5C] ring-2 ring-[#0A0A0B]" />
            </button>
          </div>
        </header>

        {/* Page View Outlet */}
        <main className="flex-1 p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
