"use client";

import { useState, useEffect, useCallback } from "react";

/* ─── Types ─────────────────────────────────────────────────── */
type Screen = "home" | "content" | "banks" | "settings";
type Phase = "0-7" | "8-30" | "30+";
type ConnState = "online" | "offline" | "syncing";

interface Baby { name: string; birthDate: string; }

/* ─── Helpers ────────────────────────────────────────────────── */
const daysSince = (iso: string) =>
  Math.max(0, Math.floor((Date.now() - new Date(iso).getTime()) / 86400000));

const toPhase = (d: number): Phase => d <= 7 ? "0-7" : d <= 30 ? "8-30" : "30+";

const phaseInfo = (p: Phase) => ({
  "0-7":  { label: "Primeiros dias",    emoji: "🌸", msg: "Que começo especial!" },
  "8-30": { label: "Primeiro mês",      emoji: "🌷", msg: "Vocês estão se conhecendo" },
  "30+":  { label: "Crescendo juntos",  emoji: "💪", msg: "Que dupla incrível!" },
}[p]);

/* ─── Tokens helpers ─────────────────────────────────────────── */
const t = {
  bg:        "var(--bg)",
  bg2:       "var(--bg-secondary)",
  surface:   "var(--surface)",
  surface2:  "var(--surface-2)",
  border:    "var(--border)",
  border2:   "var(--border-2)",
  peach:     "var(--peach)",
  peachSoft: "var(--peach-soft)",
  peachMid:  "var(--peach-mid)",
  lilac:     "var(--lilac)",
  lilacSoft: "var(--lilac-soft)",
  lilacMid:  "var(--lilac-mid)",
  rose:      "var(--rose)",
  roseSoft:  "var(--rose-soft)",
  roseMid:   "var(--rose-mid)",
  txt:       "var(--text-primary)",
  txt2:      "var(--text-secondary)",
  muted:     "var(--text-muted)",
  faint:     "var(--text-faint)",
};

function IllustrationMomBaby() {
  return (
    <svg viewBox="0 0 200 200" fill="none" className="h-full w-full" style={{ filter: "drop-shadow(0 8px 24px rgba(197,140,220,0.25))" }}>
      <circle cx="100" cy="108" r="78" fill="var(--lilac-soft)" />
      <circle cx="100" cy="105" r="62" fill="var(--rose-soft)" opacity=".6" />
      <ellipse cx="86" cy="148" rx="36" ry="30" fill="var(--lilac-mid)" />
      <path d="M62 142 Q56 155 62 165 Q68 175 80 172 L110 162 Q124 155 118 143 Q112 132 100 136 Z" fill="var(--lilac-mid)" />
      <rect x="80" y="102" width="12" height="18" rx="6" fill="var(--peach-mid)" />
      <circle cx="86" cy="90" r="26" fill="var(--peach-mid)" />
      <ellipse cx="86" cy="74" rx="26" ry="18" fill="#8B4A8B" />
      <ellipse cx="62" cy="88" rx="9" ry="18" fill="#8B4A8B" />
      <ellipse cx="110" cy="88" rx="9" ry="18" fill="#8B4A8B" />
      <path d="M60 96 Q58 108 62 116" stroke="#8B4A8B" strokeWidth="8" strokeLinecap="round" fill="none" />
      <path d="M112 96 Q114 108 110 116" stroke="#8B4A8B" strokeWidth="8" strokeLinecap="round" fill="none" />
      <ellipse cx="79" cy="90" rx="3.5" ry="4" fill="var(--text-primary)" />
      <ellipse cx="93" cy="90" rx="3.5" ry="4" fill="var(--text-primary)" />
      <circle cx="80.5" cy="88.5" r="1.2" fill="white" />
      <circle cx="94.5" cy="88.5" r="1.2" fill="white" />
      <ellipse cx="72" cy="97" rx="6" ry="4" fill="var(--peach)" opacity=".45" />
      <ellipse cx="100" cy="97" rx="6" ry="4" fill="var(--peach)" opacity=".45" />
      <path d="M78 97 Q86 104 94 97" stroke="var(--rose)" strokeWidth="2.2" strokeLinecap="round" fill="none" />
      <ellipse cx="118" cy="150" rx="20" ry="16" fill="var(--peach-soft)" />
      <circle cx="124" cy="132" r="17" fill="var(--peach-mid)" />
      <path d="M118 118 Q124 112 130 118" stroke="#8B4A8B" strokeWidth="3.5" strokeLinecap="round" fill="none" />
      <path d="M118 130 Q120.5 127 123 130" stroke="var(--text-primary)" strokeWidth="1.8" strokeLinecap="round" fill="none" />
      <path d="M126 130 Q128.5 127 131 130" stroke="var(--text-primary)" strokeWidth="1.8" strokeLinecap="round" fill="none" />
      <path d="M120 136 Q124 140 128 136" stroke="var(--rose)" strokeWidth="1.8" strokeLinecap="round" fill="none" />
      <ellipse cx="116" cy="135" rx="4" ry="3" fill="var(--peach)" opacity=".5" />
      <ellipse cx="132" cy="135" rx="4" ry="3" fill="var(--peach)" opacity=".5" />
      <path d="M100 50 C100 50 95 44 91 46.5 C87 49 87 54 91 57.5 L100 67 L109 57.5 C113 54 113 49 109 46.5 C105 44 100 50 100 50Z" fill="var(--rose)" />
      <g fill="var(--lilac)" opacity=".7">
        <circle cx="46" cy="60" r="3" />
        <circle cx="155" cy="70" r="2.5" />
        <circle cx="148" cy="48" r="2" />
        <circle cx="44" cy="145" r="2" />
        <circle cx="160" cy="138" r="2.5" />
      </g>
      <g fill="var(--peach)" opacity=".6">
        <circle cx="58" cy="45" r="2" />
        <circle cx="163" cy="110" r="2" />
      </g>
    </svg>
  );
}

function IllustrationContent() {
  return (
    <svg viewBox="0 0 80 80" fill="none">
      <circle cx="40" cy="40" r="36" fill="var(--rose-soft)" />
      <rect x="20" y="25" width="40" height="32" rx="5" fill="var(--rose-mid)" />
      <rect x="24" y="30" width="24" height="3" rx="1.5" fill="var(--rose)" opacity=".7" />
      <rect x="24" y="36" width="32" height="2.5" rx="1.25" fill="var(--rose)" opacity=".4" />
      <rect x="24" y="41" width="28" height="2.5" rx="1.25" fill="var(--rose)" opacity=".4" />
      <rect x="24" y="46" width="20" height="2.5" rx="1.25" fill="var(--rose)" opacity=".4" />
      <circle cx="54" cy="52" r="10" fill="var(--rose)" />
      <path d="M50 52 L53 55 L58 49" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
  );
}

function IllustrationMap() {
  return (
    <svg viewBox="0 0 80 80" fill="none">
      <circle cx="40" cy="40" r="36" fill="var(--peach-soft)" />
      <rect x="16" y="22" width="48" height="36" rx="6" fill="var(--peach-mid)" />
      <line x1="16" y1="36" x2="64" y2="36" stroke="var(--peach)" strokeWidth="1.5" opacity=".5" />
      <line x1="40" y1="22" x2="40" y2="58" stroke="var(--peach)" strokeWidth="1.5" opacity=".5" />
      <path d="M40 30 C40 30 35 35 35 39 A5 5 0 0 0 45 39 C45 35 40 30 40 30Z" fill="var(--rose)" />
      <circle cx="40" cy="39" r="2.5" fill="white" />
      <circle cx="26" cy="48" r="4" fill="var(--peach)" />
      <circle cx="55" cy="30" r="3.5" fill="var(--peach)" />
    </svg>
  );
}

const Ico = {
  Home: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" className="h-6 w-6">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  ),
  Book: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" className="h-6 w-6">
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" /><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
    </svg>
  ),
  Drop: ({ c, size = 6 }: { c: string; size?: number }) => (
    <svg viewBox="0 0 24 24" fill={c} className={`h-${size} w-${size}`}>
      <path d="M12 2 C12 2 5 10 5 15.5 A7 7 0 0 0 19 15.5 C19 10 12 2 12 2Z" />
    </svg>
  ),
  Gear: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" className="h-6 w-6">
      <circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  ),
  Heart: ({ c, fill }: { c: string; fill?: boolean }) => (
    <svg viewBox="0 0 24 24" fill={fill ? c : "none"} stroke={c} strokeWidth="2" className="h-5 w-5">
      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
    </svg>
  ),
  Pin: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" />
    </svg>
  ),
  Bell: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  ),
  Shield: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  ),
  Moon: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
    </svg>
  ),
  Wifi: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
      <path d="M5 12.55a11 11 0 0 1 14.08 0" /><path d="M1.42 9a16 16 0 0 1 21.16 0" /><path d="M8.53 16.11a6 6 0 0 1 6.95 0" /><line x1="12" y1="20" x2="12.01" y2="20" />
    </svg>
  ),
  WifiOff: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
      <line x1="1" y1="1" x2="23" y2="23" /><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55" /><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39" /><path d="M10.71 5.05A16 16 0 0 1 22.56 9" /><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88" /><path d="M8.53 16.11a6 6 0 0 1 6.95 0" /><line x1="12" y1="20" x2="12.01" y2="20" />
    </svg>
  ),
  Check: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  ),
  ChevronRight: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
      <polyline points="9 18 15 12 9 6" />
    </svg>
  ),
  ChevronLeft: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="h-5 w-5">
      <polyline points="15 18 9 12 15 6" />
    </svg>
  ),
  Sync: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
      <polyline points="1 4 1 10 7 10" /><polyline points="23 20 23 14 17 14" /><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15" />
    </svg>
  ),
  Download: ({ c }: { c: string }) => (
    <svg viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="h-4 w-4">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7 10 12 15 17 10" /><line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  ),
};

function Pill({ children, color, bg }: { children: React.ReactNode; color: string; bg: string }) {
  return (
    <span className="inline-flex items-center rounded-full px-3 py-1 text-xs font-bold" style={{ color, background: bg }}>
      {children}
    </span>
  );
}

function Toggle({ on, onToggle, accentColor }: { on: boolean; onToggle: () => void; accentColor?: string }) {
  return (
    <button
      onClick={onToggle}
      className="relative h-6.5 w-12 flex-shrink-0 rounded-full transition-all duration-300"
      style={{ background: on ? (accentColor ?? t.rose) : t.border2 }}
      role="switch"
      aria-checked={on}
    >
      <span
        className="absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-all duration-300"
        style={{ left: on ? "26px" : "2px" }}
      />
    </button>
  );
}

function BackButton({ onBack }: { onBack: () => void }) {
  return (
    <button
      onClick={onBack}
      className="flex h-10 w-10 items-center justify-center rounded-2xl transition-transform active:scale-90"
      style={{ background: t.surface2, border: `1px solid ${t.border}` }}
    >
      <Ico.ChevronLeft c={t.rose} />
    </button>
  );
}

function ConnBadge({ state }: { state: ConnState }) {
  const cfg = {
    online:  { icon: <Ico.Wifi c="#4CAF50" />, label: "Online", bg: "#E8F5E9", color: "#388E3C" },
    offline: { icon: <Ico.WifiOff c="#FF5722" />, label: "Offline", bg: "#FBE9E7", color: "#D84315" },
    syncing: { icon: <Ico.Sync c="#FF9800" />, label: "Sincronizando…", bg: "#FFF3E0", color: "#E65100" },
  }[state];

  return (
    <div className="flex items-center gap-1.5 rounded-xl px-2.5 py-1.5" style={{ background: cfg.bg }}>
      <span className={state === "syncing" ? "spin-slow" : ""}>{cfg.icon}</span>
      <span className="text-xs font-bold" style={{ color: cfg.color }}>{cfg.label}</span>
    </div>
  );
}

function MapView() {
  const pins = [{ x: 68, y: 72 }, { x: 118, y: 48 }, { x: 88, y: 116 }, { x: 148, y: 92 }, { x: 42, y: 118 }];
  return (
    <svg viewBox="0 0 200 160" className="h-full w-full">
      <rect width="200" height="160" fill="var(--peach-soft)" />
      {[40, 80, 120].map(y => <line key={y} x1="0" y1={y} x2="200" y2={y} stroke="var(--peach-mid)" strokeWidth="8" />)}
      {[50, 100, 150].map(x => <line key={x} x1={x} y1="0" x2={x} y2="160" stroke="var(--peach-mid)" strokeWidth="8" />)}
      {[[2,2],[52,2],[102,2],[2,42],[52,42],[102,42],[2,82],[52,82],[102,82]].map(([x,y],i) => (
        <rect key={i} x={x+2} y={y+2} width={44} height={34} rx={5} fill="var(--peach-mid)" opacity=".7" />
      ))}
      <circle cx="100" cy="80" r="11" fill="var(--rose)" opacity=".25" />
      <circle cx="100" cy="80" r="7" fill="var(--rose)" opacity=".5" />
      <circle cx="100" cy="80" r="4" fill="var(--rose)" />
      <circle cx="100" cy="80" r="1.5" fill="white" />
      {pins.map((p, i) => (
        <g key={i}>
          <path d={`M${p.x} ${p.y-14} C${p.x} ${p.y-14} ${p.x-7} ${p.y-5} ${p.x-7} ${p.y} A7 7 0 0 0 ${p.x+7} ${p.y} C${p.x+7} ${p.y-5} ${p.x} ${p.y-14} ${p.x} ${p.y-14}Z`} fill="var(--lilac)" />
          <circle cx={p.x} cy={p.y-7} r="3" fill="white" opacity=".9" />
        </g>
      ))}
    </svg>
  );
}

function SplashScreen({ onDone }: { onDone: () => void }) {
  useEffect(() => { const id = setTimeout(onDone, 2600); return () => clearTimeout(id); }, [onDone]);

  return (
    <div className="flex h-full flex-col items-center justify-center gap-8" style={{ background: "linear-gradient(155deg, var(--peach-soft) 0%, var(--lilac-soft) 60%, var(--rose-soft) 100%)" }}>
      <div className="float h-32 w-32">
        <svg viewBox="0 0 128 128" fill="none">
          <circle cx="64" cy="64" r="62" fill="white" opacity=".85" />
          <circle cx="64" cy="64" r="52" fill="var(--rose-soft)" />
          <ellipse cx="58" cy="84" rx="22" ry="18" fill="var(--lilac-mid)" />
          <circle cx="58" cy="56" r="16" fill="var(--peach-mid)" />
          <ellipse cx="58" cy="46" rx="16" ry="11" fill="#8B4A8B" />
          <circle cx="76" cy="78" r="12" fill="var(--peach-soft)" />
          <circle cx="82" cy="67" r="10" fill="var(--peach-mid)" />
          <path d="M64 32 C64 32 60 27 57 29.5 C54 32 54 37 57 40 L64 47 L71 40 C74 37 74 32 71 29.5 C68 27 64 32 64 32Z" fill="var(--rose)" />
        </svg>
      </div>

      <div className="text-center">
        <h1 className="text-4xl font-black tracking-tight" style={{ color: t.txt }}>Colo de Mãe</h1>
        <p className="mt-1.5 text-sm font-semibold italic" style={{ color: t.muted }}>apoio, amor e amamentação</p>
      </div>

      <div className="flex gap-2.5">
        {[0, 150, 300].map(d => (
          <span key={d} className="h-2 w-2 rounded-full" style={{ background: [t.rose, t.lilac, t.peach][d / 150], animation: `pulse-soft 1.4s ease-in-out ${d}ms infinite` }} />
        ))}
      </div>
    </div>
  );
}

function HomeScreen({ baby, favorites, onFavorite, conn, onNavigate }: {
  baby: Baby; favorites: Set<string>; onFavorite: (id: string) => void;
  conn: ConnState; onNavigate: (s: Screen) => void;
}) {
  const days = daysSince(baby.birthDate);
  const phase = toPhase(days);
  const info = phaseInfo(phase);
  const [tipOpen, setTipOpen] = useState(false);

  const tip = "Uma pega adequada ajuda o bebê a mamar melhor e pode evitar desconforto durante a amamentação. Lembre-se: a barriga do bebê deve estar voltada para a sua.";

  const shortcuts = [
    { id: "pega", label: "Pega", emoji: "latch", bg: t.roseSoft },
    { id: "ordenha", label: "Ordenha", emoji: "pump", bg: t.lilacSoft },
    { id: "armazenamento", label: "Armazenamento", emoji: "bottle", bg: t.peachSoft },
  ];

  return (
    <div className="flex h-full flex-col gap-0 overflow-y-auto pb-28" style={{ background: t.bg }}>
      <div className="flex items-center justify-between px-5 pb-5 pt-10">
        <div>
          <p className="mb-1 text-xs font-bold uppercase tracking-widest" style={{ color: t.muted }}>Bem-vinda</p>
          <h1 className="text-2xl font-black leading-tight" style={{ color: t.txt }}>Olá, mamãe 💜</h1>
        </div>
        <ConnBadge state={conn} />
      </div>

      <div className="mx-5 mb-4 overflow-hidden rounded-3xl" style={{ background: "linear-gradient(140deg, var(--lilac-soft) 0%, var(--rose-soft) 100%)", border: "1.5px solid var(--border)" }}>
        <div className="flex items-center gap-3 p-5">
          <div className="min-w-0 flex-1">
            <p className="mb-1.5 text-xs font-bold uppercase tracking-widest" style={{ color: t.muted }}>Seu bebê</p>
            <h2 className="mb-1.5 text-3xl font-black leading-none" style={{ color: t.txt }}>{baby.name}</h2>
            <p className="text-lg font-bold" style={{ color: t.txt2 }}>{days} dias de vida</p>
            <div className="mt-3 flex items-center gap-2">
              <Pill color="white" bg={t.rose}>{info.emoji} {info.label}</Pill>
            </div>
            <p className="mt-2 text-xs font-semibold" style={{ color: t.muted }}>{info.msg}</p>
          </div>
          <div className="-mb-2 -mr-2 h-32 w-32 flex-shrink-0">
            <IllustrationMomBaby />
          </div>
        </div>
      </div>

      <div className="mx-5 mb-4 rounded-3xl p-5" style={{ background: t.surface, border: `1.5px solid ${t.border}` }}>
        <div className="mb-3 flex items-center gap-2">
          <p className="flex-1 text-xs font-black uppercase tracking-widest" style={{ color: t.muted }}>Dica do dia</p>
          <button onClick={() => onFavorite("tip-today")} className="p-1 transition-transform active:scale-90">
            <Ico.Heart c={t.rose} fill={favorites.has("tip-today")} />
          </button>
        </div>

        {!tipOpen ? (
          <>
            <p className="mb-4 text-sm font-semibold leading-relaxed" style={{ color: t.txt2 }}>{tip.slice(0, 72)}…</p>
            <button onClick={() => setTipOpen(true)} className="w-full rounded-2xl py-4 text-sm font-black transition-transform active:scale-95" style={{ background: t.rose, color: "white" }}>
              Ver dica do dia
            </button>
          </>
        ) : (
          <>
            <p className="text-sm font-semibold leading-relaxed" style={{ color: t.txt2 }}>{tip}</p>
            {favorites.has("tip-today") && (
              <div className="mt-3 flex items-center gap-2 text-xs font-semibold" style={{ color: t.muted }}>
                <Ico.Download c={t.lilac} />
                Salvo — disponível offline
              </div>
            )}
          </>
        )}
      </div>

      <div className="mb-4 px-5">
        <p className="mb-3 text-xs font-black uppercase tracking-widest" style={{ color: t.muted }}>Acesso rápido</p>
        <div className="grid grid-cols-3 gap-3">
          {shortcuts.map(s => (
            <button key={s.id} onClick={() => onNavigate("content")} className="flex flex-col items-center gap-2 rounded-2xl py-4 transition-transform active:scale-93" style={{ background: s.bg, border: `1px solid ${t.border}` }}>
              {s.emoji === "latch" ? (
                <svg viewBox="0 0 32 32" fill="none" className="h-7 w-7">
                  <circle cx="10" cy="14" r="7" fill="var(--rose-mid)" />
                  <circle cx="10" cy="10" r="5" fill="var(--peach-mid)" />
                  <path d="M7 13 Q10 16 13 13" stroke="var(--rose)" strokeWidth="1.5" strokeLinecap="round" fill="none" />
                  <ellipse cx="22" cy="17" rx="7" ry="8" fill="var(--rose-mid)" />
                  <circle cx="22" cy="17" r="3" fill="var(--rose)" opacity=".5" />
                  <path d="M13 14 Q17 15 19 17" stroke="white" strokeWidth="1.2" strokeLinecap="round" opacity=".6" fill="none" />
                </svg>
              ) : s.emoji === "pump" ? (
                <svg viewBox="0 0 32 32" fill="none" className="h-7 w-7">
                  <path d="M6 8 L14 18 L14 26 L18 26 L18 18 L26 8 Z" fill="var(--lilac-mid)" />
                  <path d="M6 8 L26 8" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity=".5" />
                  <rect x="13" y="25" width="6" height="4" rx="2" fill="var(--lilac)" />
                  <path d="M16 2 C16 2 14 5 14 6.5 A2 2 0 0 0 18 6.5 C18 5 16 2 16 2Z" fill="var(--lilac)" opacity=".7" />
                  <path d="M22 4 C22 4 21 6 21 7 A1.3 1.3 0 0 0 23 7 C23 6 22 4 22 4Z" fill="var(--lilac)" opacity=".45" />
                </svg>
              ) : s.emoji === "bottle" ? (
                <svg viewBox="0 0 32 32" fill="none" className="h-7 w-7">
                  <rect x="12" y="2" width="8" height="4" rx="1.5" fill="var(--peach-mid)" />
                  <path d="M10 6 Q8 8 8 11 L8 26 Q8 29 11 29 L21 29 Q24 29 24 26 L24 11 Q24 8 22 6 Z" fill="var(--peach-mid)" />
                  <path d="M8 16 L24 16" stroke="white" strokeWidth="1.5" opacity=".5" />
                  <path d="M10 11 Q16 13 22 11" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity=".4" />
                  <ellipse cx="16" cy="22" rx="4" ry="2" fill="white" opacity=".2" />
                </svg>
              ) : (
                <span className="text-2xl">{s.emoji}</span>
              )}
              <span className="text-center text-xs font-bold leading-tight" style={{ color: t.txt2 }}>{s.label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="mx-5 mb-4 flex items-center gap-3 rounded-2xl px-4 py-3.5" style={{ background: t.lilacSoft, border: `1px solid ${t.border}` }}>
        <span className="text-xl">📥</span>
        <div>
          <p className="text-xs font-bold" style={{ color: t.txt2 }}>Conteúdos disponíveis offline</p>
          <p className="mt-0.5 text-xs" style={{ color: t.muted }}>Dicas e favoritos acessíveis sem internet</p>
        </div>
      </div>

      <div className="mb-2 px-5">
        <button onClick={() => onNavigate("banks")} className="flex w-full items-center justify-center gap-3 rounded-3xl py-5 text-base font-black transition-transform active:scale-95" style={{ background: "linear-gradient(130deg, var(--lilac) 0%, var(--rose) 100%)", color: "white", boxShadow: "0 8px 24px rgba(197,140,180,0.35)" }}>
          Onde doar leite
        </button>
      </div>
    </div>
  );
}

function CategoryIcon({ cat, size = 7 }: { cat: string; size?: number }) {
  const cls = `h-${size} w-${size}`;
  if (cat === "pega") return (
    <svg viewBox="0 0 32 32" fill="none" className={cls}>
      <circle cx="10" cy="14" r="7" fill="var(--rose-mid)" />
      <circle cx="10" cy="10" r="5" fill="var(--peach-mid)" />
      <path d="M7 13 Q10 16 13 13" stroke="var(--rose)" strokeWidth="1.5" strokeLinecap="round" fill="none" />
      <ellipse cx="22" cy="17" rx="7" ry="8" fill="var(--rose-mid)" />
      <circle cx="22" cy="17" r="3" fill="var(--rose)" opacity=".5" />
      <path d="M13 14 Q17 15 19 17" stroke="white" strokeWidth="1.2" strokeLinecap="round" opacity=".6" fill="none" />
    </svg>
  );
  if (cat === "ordenha") return (
    <svg viewBox="0 0 32 32" fill="none" className={cls}>
      <path d="M6 8 L14 18 L14 26 L18 26 L18 18 L26 8 Z" fill="var(--lilac-mid)" />
      <path d="M6 8 L26 8" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity=".5" />
      <rect x="13" y="25" width="6" height="4" rx="2" fill="var(--lilac)" />
      <path d="M16 2 C16 2 14 5 14 6.5 A2 2 0 0 0 18 6.5 C18 5 16 2 16 2Z" fill="var(--lilac)" opacity=".7" />
      <path d="M22 4 C22 4 21 6 21 7 A1.3 1.3 0 0 0 23 7 C23 6 22 4 22 4Z" fill="var(--lilac)" opacity=".45" />
    </svg>
  );
  if (cat === "amamentacao") return (
    <svg viewBox="0 0 32 32" fill="none" className={cls}>
      <rect x="12" y="2" width="8" height="4" rx="1.5" fill="var(--peach-mid)" />
      <path d="M10 6 Q8 8 8 11 L8 26 Q8 29 11 29 L21 29 Q24 29 24 26 L24 11 Q24 8 22 6 Z" fill="var(--peach-mid)" />
      <path d="M8 16 L24 16" stroke="white" strokeWidth="1.5" opacity=".5" />
      <path d="M10 11 Q16 13 22 11" stroke="white" strokeWidth="1.5" strokeLinecap="round" opacity=".4" />
      <ellipse cx="16" cy="22" rx="4" ry="2" fill="white" opacity=".2" />
    </svg>
  );
  if (cat === "sono") return (
    <svg viewBox="0 0 32 32" fill="none" className={cls}>
      <path d="M22 6 A10 10 0 1 0 26 16 A7 7 0 0 1 22 6Z" fill="var(--lilac-mid)" />
      <circle cx="10" cy="9" r="1.5" fill="var(--lilac)" opacity=".6" />
      <circle cx="25" cy="22" r="1" fill="var(--lilac)" opacity=".5" />
      <circle cx="7" cy="22" r="1.2" fill="var(--lilac)" opacity=".4" />
    </svg>
  );
  return null;
}

const ARTICLES = [
  { id:"p1", cat:"pega", catLabel:"Pega", emoji:"👄", title:"Como identificar a pega correta", time:"3 min", desc:"Aprenda os sinais de uma pega eficaz para uma amamentação confortável e sem dor.", color:{ bg:"var(--rose-soft)", accent:"var(--rose)", mid:"var(--rose-mid)" } },
  { id:"p2", cat:"pega", catLabel:"Pega", emoji:"👄", title:"Sinais de má pega", time:"4 min", desc:"Reconheça os indícios de que algo precisa ser ajustado antes que cause desconforto.", color:{ bg:"var(--rose-soft)", accent:"var(--rose)", mid:"var(--rose-mid)" } },
  { id:"p3", cat:"pega", catLabel:"Pega", emoji:"👄", title:"Posições para amamentar", time:"5 min", desc:"Descubra as melhores posições para você e seu bebê ficarem confortáveis durante as mamadas.", color:{ bg:"var(--rose-soft)", accent:"var(--rose)", mid:"var(--rose-mid)" } },
  { id:"o1", cat:"ordenha", catLabel:"Ordenha", emoji:"🤱", title:"Como fazer a ordenha", time:"6 min", desc:"Técnica manual e com bomba, explicada passo a passo com carinho e precisão.", color:{ bg:"var(--lilac-soft)", accent:"var(--lilac)", mid:"var(--lilac-mid)" } },
  { id:"o2", cat:"ordenha", catLabel:"Ordenha", emoji:"🤱", title:"Higienização dos utensílios", time:"3 min", desc:"Cuidados essenciais de higiene para manter o leite materno seguro e saudável.", color:{ bg:"var(--lilac-soft)", accent:"var(--lilac)", mid:"var(--lilac-mid)" } },
  { id:"o3", cat:"ordenha", catLabel:"Ordenha", emoji:"🤱", title:"Armazenamento do leite", time:"4 min", desc:"Temperatura, recipientes e tempo certo para guardar o leite materno com segurança.", color:{ bg:"var(--lilac-soft)", accent:"var(--lilac)", mid:"var(--lilac-mid)" } },
  { id:"a1", cat:"amamentacao", catLabel:"Amamentação", emoji:"🍼", title:"Livre demanda", time:"3 min", desc:"Por que amamentar sempre que o bebê pedir faz toda a diferença nos primeiros meses.", color:{ bg:"var(--peach-soft)", accent:"var(--peach)", mid:"var(--peach-mid)" } },
  { id:"a2", cat:"amamentacao", catLabel:"Amamentação", emoji:"🍼", title:"Aleitamento exclusivo", time:"5 min", desc:"Os benefícios do leite materno exclusivo nos primeiros 6 meses de vida do bebê.", color:{ bg:"var(--peach-soft)", accent:"var(--peach)", mid:"var(--peach-mid)" } },
  { id:"a3", cat:"amamentacao", catLabel:"Amamentação", emoji:"🍼", title:"Dúvidas dos primeiros dias", time:"7 min", desc:"Respondemos com carinho as perguntas mais frequentes das primeiras semanas.", color:{ bg:"var(--peach-soft)", accent:"var(--peach)", mid:"var(--peach-mid)" } },
  { id:"s1", cat:"sono", catLabel:"Sono & Rotina", emoji:"🌙", title:"Mamadas durante a madrugada", time:"4 min", desc:"Como tornar as mamadas noturnas mais tranquilas para mamãe e bebê.", color:{ bg:"var(--lilac-soft)", accent:"var(--lilac)", mid:"var(--lilac-mid)" } },
  { id:"s2", cat:"sono", catLabel:"Sono & Rotina", emoji:"🌙", title:"Rotina dos primeiros dias", time:"5 min", desc:"Construir uma rotina gentil e adaptável ao ritmo natural do bebê.", color:{ bg:"var(--lilac-soft)", accent:"var(--lilac)", mid:"var(--lilac-mid)" } },
];

const CATS = ["pega", "ordenha", "amamentacao", "sono"] as const;
const CAT_LABELS: Record<string, { label: string; emoji: string }> = {
  pega: { label: "Pega", emoji: "👄" },
  ordenha: { label: "Ordenha", emoji: "🤱" },
  amamentacao: { label: "Amamentação", emoji: "🍼" },
  sono: { label: "Sono & Rotina", emoji: "🌙" },
};

function ArticleDetail({ id, favorites, onFavorite, onBack }: {
  id: string; favorites: Set<string>; onFavorite: (id: string) => void; onBack: () => void;
}) {
  const article = ARTICLES.find(a => a.id === id)!;
  const isFav = favorites.has(id);

  return (
    <div className="flex h-full flex-col overflow-y-auto slide-up" style={{ background: t.bg }}>
      <div className="flex items-center gap-3 px-5 pb-4 pt-10">
        <BackButton onBack={onBack} />
        <span className="text-xl">{article.emoji}</span>
        <span className="text-sm font-bold" style={{ color: t.muted }}>{article.catLabel}</span>
      </div>

      <div className="px-5 pb-10">
        <h1 className="mb-3 text-2xl font-black leading-snug" style={{ color: t.txt }}>{article.title}</h1>

        <div className="mb-6 flex flex-wrap items-center gap-2">
          <Pill color={t.txt2} bg={t.surface2}>⏱ {article.time} de leitura</Pill>
          <button onClick={() => onFavorite(id)} className="flex items-center gap-1.5 rounded-full px-3 py-1.5 transition-all active:scale-95" style={{ background: isFav ? article.color.accent : t.surface2, color: isFav ? "white" : article.color.accent, border: `1.5px solid ${isFav ? article.color.accent : t.border}` }}>
            <Ico.Heart c={isFav ? "white" : article.color.accent} fill={isFav} />
            <span className="text-xs font-bold">{isFav ? "Favoritado ✓" : "Favoritar"}</span>
          </button>
        </div>

        <div className="mb-6 flex h-40 w-full items-center justify-center overflow-hidden rounded-3xl" style={{ background: article.color.mid }}>
          <span className="text-8xl">{article.emoji}</span>
        </div>

        <div className="space-y-4">
          {[
            article.desc,
            "Durante os primeiros dias, é muito comum sentir dúvidas e inseguranças. Isso é completamente normal e faz parte do processo de adaptação — tanto para você quanto para o bebê.",
            "Lembre-se: você não está sozinha. Cada mamada é um ato de amor profundo, e cada dia que passa vocês ficam mais conectadas e mais confiantes.",
            "Se tiver dúvidas, não hesite em consultar uma consultora de amamentação ou o pediatra do seu bebê. Pedir ajuda é sinal de sabedoria e cuidado.",
            "Você está fazendo um trabalho incrível, mamãe. 💜",
          ].map((para, i) => (
            <p key={i} className="text-sm font-semibold leading-relaxed" style={{ color: t.txt2 }}>{para}</p>
          ))}
        </div>

        {isFav && (
          <div className="mt-6 flex items-center gap-2.5 rounded-2xl px-4 py-3.5" style={{ background: t.lilacSoft, border: `1px solid ${t.border}` }}>
            <Ico.Download c={t.lilac} />
            <span className="text-xs font-semibold" style={{ color: t.txt2 }}>Salvo nos favoritos — disponível offline</span>
          </div>
        )}
      </div>
    </div>
  );
}

function ContentScreen({ favorites, onFavorite }: {
  favorites: Set<string>; onFavorite: (id: string) => void;
}) {
  const [openArticle, setOpenArticle] = useState<string | null>(null);

  if (openArticle) return (<ArticleDetail id={openArticle} favorites={favorites} onFavorite={onFavorite} onBack={() => setOpenArticle(null)} />);

  return (
    <div className="flex h-full flex-col overflow-y-auto pb-28" style={{ background: t.bg }}>
      <div className="px-5 pb-4 pt-10">
        <p className="mb-1 text-xs font-black uppercase tracking-widest" style={{ color: t.muted }}>Biblioteca</p>
        <h1 className="text-2xl font-black leading-snug" style={{ color: t.txt }}>Vamos cuidar dessa fase juntos 🌸</h1>
      </div>

      <div className="space-y-4 px-5">
        {CATS.map(cat => {
          const { label, emoji } = CAT_LABELS[cat];
          const arts = ARTICLES.filter(a => a.cat === cat);
          const firstColor = arts[0].color;

          return (
            <div key={cat} className="overflow-hidden rounded-3xl" style={{ background: t.surface, border: `1.5px solid ${t.border}` }}>
              <div className="flex items-center gap-3 px-5 py-4" style={{ background: firstColor.mid }}>
                <span className="text-2xl">{emoji}</span>
                <h2 className="flex-1 text-base font-black" style={{ color: t.txt }}>{label}</h2>
                <Pill color="white" bg={firstColor.accent}>{arts.length} artigos</Pill>
              </div>

              <div>
                {arts.map((a, i) => (
                  <div key={a.id} className="w-full" style={{ borderTop: i > 0 ? `1px solid ${t.border}` : "none" }}>
                    <button onClick={() => setOpenArticle(a.id)} className="flex w-full items-center gap-3 px-5 py-3.5 text-left transition-colors active:opacity-70">
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-bold" style={{ color: t.txt }}>{a.title}</p>
                        <p className="mt-0.5 text-xs" style={{ color: t.muted }}>⏱ {a.time}</p>
                      </div>
                      <button onClick={e => { e.stopPropagation(); onFavorite(a.id); }} className="flex-shrink-0 p-1.5 transition-transform active:scale-90" aria-label={`Favoritar ${a.title}`}>
                        <Ico.Heart c={a.color.accent} fill={favorites.has(a.id)} />
                      </button>
                      <Ico.ChevronRight c={t.faint} />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

const BANKS = [
  { name:"BLH Santa Casa", dist:"0.8 km", addr:"Rua das Flores, 123 — Centro", hours:"Seg–Sex, 7h–17h", phone:"(11) 3333-4444", tags:["Doação","Orientação"] },
  { name:"BLH Hospital das Clínicas", dist:"1.4 km", addr:"Av. Dr. Enéas, 255 — Cerqueira César", hours:"24 horas", phone:"(11) 2661-0000", tags:["Doação","Pasteurização","Distribuição"] },
  { name:"BLH Maternidade Pró-Amor", dist:"2.1 km", addr:"Rua das Acácias, 88 — Jardim Paulista", hours:"Seg–Sáb, 6h–18h", phone:"(11) 4444-5555", tags:["Doação","Triagem"] },
  { name:"BLH UBS Vila Madalena", dist:"3.5 km", addr:"Rua Girassol, 303 — Vila Madalena", hours:"Seg–Sex, 8h–16h", phone:"(11) 3032-1122", tags:["Orientação"] },
];

function BankDetail({ bank, onBack }: { bank: typeof BANKS[0]; onBack: () => void }) {
  return (
    <div className="flex h-full flex-col overflow-y-auto slide-up" style={{ background: t.bg }}>
      <div className="flex items-center gap-3 px-5 pb-4 pt-10">
        <BackButton onBack={onBack} />
        <h2 className="flex-1 text-base font-black leading-tight" style={{ color: t.txt }}>{bank.name}</h2>
      </div>

      <div className="space-y-4 px-5 pb-10">
        <div className="h-44 overflow-hidden rounded-3xl" style={{ border: `1.5px solid ${t.border}` }}>
          <MapView />
        </div>

        {[
          { icon: "📍", label: "Endereço", value: bank.addr },
          { icon: "🕐", label: "Horário", value: bank.hours },
          { icon: "📞", label: "Contato", value: bank.phone },
        ].map((row, i) => (
          <div key={i} className="flex items-start gap-3 rounded-2xl p-4" style={{ background: t.surface, border: `1.5px solid ${t.border}` }}>
            <span className="mt-0.5 flex-shrink-0 text-xl">{row.icon}</span>
            <div>
              <p className="mb-0.5 text-xs font-black uppercase tracking-wide" style={{ color: t.muted }}>{row.label}</p>
              <p className="text-sm font-semibold" style={{ color: t.txt }}>{row.value}</p>
            </div>
          </div>
        ))}

        <div className="flex flex-wrap gap-2">
          {bank.tags.map(tag => <Pill key={tag} color={t.rose} bg={t.roseSoft}>{tag}</Pill>)}
        </div>

        <div className="rounded-2xl p-4" style={{ background: t.lilacSoft, border: `1px solid ${t.border}` }}>
          <div className="mb-2 flex items-center gap-2">
            <Ico.Shield c={t.lilac} />
            <p className="text-xs font-black" style={{ color: t.txt2 }}>Orientação para doação</p>
          </div>
          <p className="text-xs font-medium leading-relaxed" style={{ color: t.muted }}>
            A doadora deve estar em boas condições de saúde, não fumar, não consumir bebidas alcoólicas e não tomar medicamentos contraindicados. Ligue antes para agendar sua visita.
          </p>
        </div>

        <div className="flex items-center gap-2 rounded-2xl px-4 py-3" style={{ background: t.peachSoft }}>
          <span className="text-sm">🔒</span>
          <p className="text-xs font-semibold" style={{ color: t.txt2 }}>
            Sua localização é usada somente com seu consentimento e nunca armazenada.
          </p>
        </div>

        <div className="flex gap-3">
          <button className="flex-1 rounded-2xl py-4 text-sm font-bold transition-transform active:scale-95" style={{ background: t.rose, color: "white" }}>
            🗺 Como chegar
          </button>
          <button className="flex-1 rounded-2xl py-4 text-sm font-bold transition-transform active:scale-95" style={{ background: t.surface2, color: t.txt2, border: `1.5px solid ${t.border}` }}>
            📞 Ligar
          </button>
        </div>

        <button className="flex w-full items-center justify-center gap-3 rounded-3xl py-5 text-base font-black transition-transform active:scale-95" style={{ background: "linear-gradient(130deg, var(--lilac) 0%, var(--rose) 100%)", color: "white", boxShadow: "0 8px 24px rgba(197,140,180,0.35)" }}>
          Quero doar leite
        </button>
      </div>
    </div>
  );
}

function BanksScreen() {
  const [selectedBank, setSelectedBank] = useState<number | null>(null);
  const [locState, setLocState] = useState<"idle" | "locating" | "done">("idle");

  if (selectedBank !== null) return <BankDetail bank={BANKS[selectedBank]} onBack={() => setSelectedBank(null)} />;

  const handleLocate = () => {
    setLocState("locating");
    setTimeout(() => setLocState("done"), 1800);
  };

  return (
    <div className="flex h-full flex-col overflow-y-auto pb-28" style={{ background: t.bg }}>
      <div className="px-5 pb-4 pt-10">
        <p className="mb-1 text-xs font-black uppercase tracking-widest" style={{ color: t.muted }}>Rede BLH</p>
        <h1 className="text-2xl font-black leading-snug" style={{ color: t.txt }}>Encontre um Banco de Leite</h1>
        <p className="mt-1.5 text-sm font-semibold" style={{ color: t.muted }}>
          Encontre o ponto mais próximo para orientação ou doação de leite humano.
        </p>
      </div>

      <div className="mx-5 mb-4 h-48 overflow-hidden rounded-3xl" style={{ border: `1.5px solid ${t.border}` }}>
        <MapView />
      </div>

      <div className="mb-4 px-5">
        <button onClick={handleLocate} disabled={locState === "locating"} className="flex w-full items-center justify-center gap-2 rounded-2xl py-4 text-sm font-bold transition-transform active:scale-95" style={{ background: t.surface, border: `1.5px solid ${t.border2}`, color: t.txt2 }}>
          {locState === "idle" && <><Ico.Pin c={t.rose} /> Usar minha localização</>}
          {locState === "locating" && <><span className="spin-slow"><Ico.Sync c={t.lilac} /></span> Localizando...</>}
          {locState === "done" && <><span>✅</span> Localização encontrada</>}
        </button>
        <p className="mt-2 text-center text-xs font-medium" style={{ color: t.faint }}>
          🔒 Localização com seu consentimento — nunca armazenada
        </p>
      </div>

      <div className="space-y-3 px-5">
        {BANKS.map((bank, i) => (
          <div key={i} className="rounded-3xl p-4" style={{ background: t.surface, border: `1.5px solid ${t.border}` }}>
            <div className="mb-3 flex items-start gap-3">
              <div className="min-w-0 flex-1">
                <h3 className="text-base font-black" style={{ color: t.txt }}>{bank.name}</h3>
                <p className="mt-0.5 truncate text-xs" style={{ color: t.muted }}>{bank.addr}</p>
              </div>
              <Pill color={t.rose} bg={t.roseSoft}>{bank.dist}</Pill>
            </div>
            <div className="mb-3 flex flex-wrap gap-1.5">
              {bank.tags.map(tag => <Pill key={tag} color={t.lilac} bg={t.lilacSoft}>{tag}</Pill>)}
            </div>
            <div className="flex gap-2">
              <button onClick={() => setSelectedBank(i)} className="flex-1 rounded-xl py-2.5 text-xs font-bold transition-transform active:scale-95" style={{ background: t.roseSoft, color: t.rose, border: `1px solid ${t.border}` }}>
                Ver detalhes
              </button>
              <button className="flex-1 rounded-xl py-2.5 text-xs font-bold text-white transition-transform active:scale-95" style={{ background: t.rose }}>
                🗺 Como chegar
              </button>
            </div>
          </div>
        ))}
      </div>

      <div className="mb-2 mt-5 px-5">
        <button className="flex w-full items-center justify-center gap-3 rounded-3xl py-5 text-base font-black transition-transform active:scale-95" style={{ background: "linear-gradient(130deg, var(--lilac) 0%, var(--rose) 100%)", color: "white", boxShadow: "0 8px 24px rgba(197,140,180,0.35)" }}>
          Quero doar leite
        </button>
      </div>
    </div>
  );
}

function SettingsScreen({ dark, onToggleDark, baby, onBabyChange }: {
  dark: boolean; onToggleDark: () => void;
  baby: Baby; onBabyChange: (b: Baby) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [editName, setEditName] = useState(baby.name);
  const [editDate, setEditDate] = useState(baby.birthDate);
  const [notifs, setNotifs] = useState(true);
  const [challenge, setChallenge] = useState(true);

  const days = daysSince(baby.birthDate);

  const saveEdit = () => {
    onBabyChange({ name: editName, birthDate: editDate });
    setEditing(false);
  };

  const Section = ({ icon, title, children }: { icon: React.ReactNode; title: string; children: React.ReactNode }) => (
    <div className="overflow-hidden rounded-3xl" style={{ background: t.surface, border: `1.5px solid ${t.border}` }}>
      <div className="flex items-center gap-2.5 px-5 py-4" style={{ borderBottom: `1px solid ${t.border}` }}>
        {icon}
        <h2 className="text-base font-black" style={{ color: t.txt }}>{title}</h2>
      </div>
      <div>{children}</div>
    </div>
  );

  const Row = ({ label, desc, right, last }: { label: string; desc?: string; right: React.ReactNode; last?: boolean }) => (
    <div className="flex items-center gap-3 px-5 py-4" style={{ borderBottom: last ? "none" : `1px solid ${t.border}` }}>
      <div className="min-w-0 flex-1">
        <p className="text-sm font-bold" style={{ color: t.txt }}>{label}</p>
        {desc && <p className="mt-0.5 text-xs font-medium" style={{ color: t.muted }}>{desc}</p>}
      </div>
      {right}
    </div>
  );

  return (
    <div className="flex h-full flex-col overflow-y-auto pb-28" style={{ background: t.bg }}>
      <div className="px-5 pb-4 pt-10">
        <p className="mb-1 text-xs font-black uppercase tracking-widest" style={{ color: t.muted }}>Perfil</p>
        <h1 className="text-2xl font-black" style={{ color: t.txt }}>Configurações 🌸</h1>
      </div>

      <div className="space-y-4 px-5">
        <Section icon={<span className="text-xl">👶</span>} title="Meu bebê">
          {editing ? (
            <div className="space-y-3 px-5 py-4">
              <div>
                <label className="mb-1.5 block text-xs font-bold" style={{ color: t.muted }}>Nome do bebê</label>
                <input value={editName} onChange={e => setEditName(e.target.value)} className="w-full rounded-xl px-4 py-3 text-sm font-semibold outline-none" style={{ background: t.bg, color: t.txt, border: `1.5px solid ${t.border2}` }} />
              </div>
              <div>
                <label className="mb-1.5 block text-xs font-bold" style={{ color: t.muted }}>Data de nascimento</label>
                <input type="date" value={editDate} onChange={e => setEditDate(e.target.value)} className="w-full rounded-xl px-4 py-3 text-sm font-semibold outline-none" style={{ background: t.bg, color: t.txt, border: `1.5px solid ${t.border2}` }} />
              </div>
              <div className="flex gap-3 pt-1">
                <button onClick={() => setEditing(false)} className="flex-1 rounded-xl py-3 text-sm font-bold" style={{ background: t.surface2, color: t.muted }}>
                  Cancelar
                </button>
                <button onClick={saveEdit} className="flex-1 rounded-xl py-3 text-sm font-bold text-white" style={{ background: t.rose }}>
                  Salvar
                </button>
              </div>
            </div>
          ) : (
            <>
              <Row label="Nome" right={<span className="text-sm font-black" style={{ color: t.txt }}>{baby.name}</span>} />
              <Row label="Nascimento" right={<span className="text-sm font-semibold" style={{ color: t.txt2 }}>{new Date(baby.birthDate + "T12:00:00").toLocaleDateString("pt-BR")}</span>} />
              <Row label="Idade" right={<span className="text-sm font-semibold" style={{ color: t.txt2 }}>{days} dias</span>} />
              <div className="px-5 py-4">
                <button onClick={() => setEditing(true)} className="w-full rounded-2xl py-3 text-sm font-bold transition-transform active:scale-95" style={{ background: t.roseSoft, color: t.rose, border: `1px solid ${t.border}` }}>
                  Editar informações
                </button>
              </div>
            </>
          )}
        </Section>

        <Section icon={<Ico.Moon c={t.lilac} />} title="Aparência">
          <Row label="Modo noturno" desc="Confortável para mamadas de madrugada" last right={<Toggle on={dark} onToggle={onToggleDark} accentColor={t.lilac} />} />
        </Section>

        <Section icon={<Ico.Bell c={t.rose} />} title="Notificações">
          <Row label="Lembretes educativos" desc="Dicas diárias sobre amamentação" right={<Toggle on={notifs} onToggle={() => setNotifs(!notifs)} />} />
          <Row label="Desafio dos 15 dias" desc="Apoio especial na fase mais delicada" last right={<Toggle on={challenge} onToggle={() => setChallenge(!challenge)} />} />
        </Section>

        <Section icon={<Ico.Shield c={t.lilac} />} title="Privacidade">
          <div className="space-y-4 px-5 py-4">
            <div>
              <p className="mb-3 text-sm font-black" style={{ color: t.txt }}>Sua privacidade importa</p>
              <div className="space-y-2.5">
                {[
                  "Dados de saúde nunca coletados sem consentimento explícito",
                  "Localização protegida e nunca armazenada nos servidores",
                  "Informações estatísticas são sempre completamente anônimas",
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-2.5">
                    <div className="mt-0.5 flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full" style={{ background: t.lilac }}>
                      <Ico.Check c="white" />
                    </div>
                    <p className="text-xs font-semibold leading-relaxed" style={{ color: t.txt2 }}>{item}</p>
                  </div>
                ))}
              </div>
            </div>
            <button className="w-full rounded-2xl py-3.5 text-sm font-bold transition-transform active:scale-95" style={{ background: t.lilacSoft, color: t.lilac, border: `1px solid ${t.border}` }}>
              Ler política de privacidade →
            </button>
          </div>
        </Section>

        <div className="flex items-center gap-3 rounded-2xl px-4 py-3.5" style={{ background: t.surface, border: `1px solid ${t.border}` }}>
          <Ico.Wifi c={t.peach} />
          <div className="flex-1">
            <p className="text-sm font-bold" style={{ color: t.txt }}>Sincronização via Wi-Fi</p>
            <p className="text-xs font-medium" style={{ color: t.muted }}>Economiza dados móveis automaticamente</p>
          </div>
          <Pill color="#388E3C" bg="#E8F5E9">Ativo</Pill>
        </div>
      </div>
    </div>
  );
}

function BottomNav({ screen, onNavigate }: { screen: Screen; onNavigate: (s: Screen) => void }) {
  const items: { id: Screen; label: string; icon: (active: boolean) => React.ReactNode }[] = [
    { id: "home", label: "Início", icon: a => <Ico.Home c={a ? t.rose : t.faint} /> },
    { id: "content", label: "Conteúdos", icon: a => <Ico.Book c={a ? t.lilac : t.faint} /> },
    { id: "banks", label: "BLH", icon: a => <Ico.Drop c={a ? t.peach : t.faint} size={6} /> },
    { id: "settings", label: "Config.", icon: a => <Ico.Gear c={a ? t.rose : t.faint} /> },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 flex items-end justify-around px-2 pb-safe pt-2" style={{ background: t.surface, borderTop: `1.5px solid ${t.border}`, maxWidth: "430px", margin: "0 auto", paddingBottom: "max(12px, env(safe-area-inset-bottom))" }}>
      {items.map(item => {
        const active = screen === item.id;
        return (
          <button key={item.id} onClick={() => onNavigate(item.id)} className="flex flex-col items-center gap-1.5 rounded-2xl px-4 pb-1.5 pt-2.5 transition-all duration-200" style={{ background: active ? (item.id === "banks" ? t.peachSoft : item.id === "content" ? t.lilacSoft : t.roseSoft) : "transparent" }}>
            {item.icon(active)}
            <span className="text-xs font-black" style={{ color: active ? (item.id === "banks" ? t.peach : item.id === "content" ? t.lilac : t.rose) : t.faint }}>{item.label}</span>
          </button>
        );
      })}
    </div>
  );
}

function StatusBar() {
  return (
    <div className="flex flex-shrink-0 items-center justify-between px-6 pb-1 pt-3" style={{ background: t.bg }}>
      <span className="text-xs font-black" style={{ color: t.muted }}>9:41</span>
      <div className="h-6 w-28 rounded-full" style={{ background: t.surface2 }} />
      <div className="flex items-center gap-1.5">
        <div className="flex h-4 items-end gap-[2px]">
          {[3,5,7,9].map((h,i) => <div key={i} className="w-[3px] rounded-sm" style={{ height: h, background: t.rose }} />)}
        </div>
        <Ico.Wifi c={t.rose} />
        <span className="text-xs font-black" style={{ color: t.rose }}>87%</span>
      </div>
    </div>
  );
}

export default function Page() {
  const [splash, setSplash] = useState(true);
  const [screen, setScreen] = useState<Screen>("home");
  const [dark, setDark] = useState(false);
  const [conn, setConn] = useState<ConnState>("online");
  const [favorites, setFavs] = useState<Set<string>>(new Set());
  const [baby, setBaby] = useState<Baby>({ name: "Luna", birthDate: "2026-08-20" });

  const toggleFav = useCallback((id: string) => {
    setFavs(prev => {
      const s = new Set(prev);
      s.has(id) ? s.delete(id) : s.add(id);
      return s;
    });
  }, []);

  return (
    <div className={dark ? "dark" : ""} style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: dark ? "#0D0818" : "#E8D4F4" }}>
      <div style={{ width: "min(430px, 100vw)", height: "min(932px, 100vh)", position: "relative", overflow: "hidden", borderRadius: "clamp(0px, 3vw, 3rem)", boxShadow: dark ? "0 48px 96px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,255,255,0.06)" : "0 48px 96px rgba(61,36,64,0.28), 0 0 0 1px rgba(255,255,255,0.8)", display: "flex", flexDirection: "column", background: t.bg }}>
        {splash ? (
          <SplashScreen onDone={() => setSplash(false)} />
        ) : (
          <>
            <StatusBar />
            <div className="relative min-h-0 flex-1 overflow-hidden">
              {screen === "home" && <HomeScreen baby={baby} favorites={favorites} onFavorite={toggleFav} conn={conn} onNavigate={setScreen} />}
              {screen === "content" && <ContentScreen favorites={favorites} onFavorite={toggleFav} />}
              {screen === "banks" && <BanksScreen />}
              {screen === "settings" && <SettingsScreen dark={dark} onToggleDark={() => setDark(d => !d)} baby={baby} onBabyChange={setBaby} />}
              <BottomNav screen={screen} onNavigate={setScreen} />
            </div>
          </>
        )}
      </div>
    </div>
  );
}
