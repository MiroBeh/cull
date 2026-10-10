// Cull — App icon explorations
// Six directions, each rendered as an iOS-radius squircle.

const ICON_RADIUS_RATIO = 0.224; // iOS squircle approximation
const ICON_MONO = '"Geist Mono", "JetBrains Mono", ui-monospace, monospace';
const ICON_INK = 'oklch(0.16 0.005 250)';
const ICON_AMBER = 'oklch(0.86 0.15 88)';
const ICON_KEEP = 'oklch(0.76 0.17 145)';
const ICON_DEL = 'oklch(0.68 0.21 28)';
const ICON_CREAM = 'oklch(0.97 0.012 88)';
const ICON_TEXT3 = 'oklch(0.50 0.008 250)';

function AppIcon({ size = 180, variant, label, note }) {
  const r = size * ICON_RADIUS_RATIO;
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 14,
      width: size,
    }}>
      <div style={{
        width: size, height: size, borderRadius: r, overflow: 'hidden',
        position: 'relative',
        boxShadow: '0 10px 30px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.06)',
      }}>
        {variant(size)}
      </div>
      {label && (
        <div style={{
          fontFamily: ICON_MONO, fontSize: 10, color: 'rgba(40,30,20,0.75)',
          letterSpacing: '0.18em', textTransform: 'uppercase', fontWeight: 500,
        }}>{label}</div>
      )}
      {note && (
        <div style={{
          fontFamily: '-apple-system, system-ui', fontSize: 12,
          color: 'rgba(60,50,40,0.7)', lineHeight: 1.4, textWrap: 'pretty',
        }}>{note}</div>
      )}
    </div>
  );
}

const IconMonoC = (s) => (
  <div style={{
    width: '100%', height: '100%', background: ICON_INK,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    position: 'relative',
  }}>
    <span style={{
      fontFamily: ICON_MONO, fontWeight: 500, fontSize: s * 0.74,
      color: ICON_AMBER, letterSpacing: '-0.04em', lineHeight: 1,
      marginTop: -s * 0.02,
    }}>C</span>
    <div style={{
      position: 'absolute', bottom: s * 0.13, left: 0, right: 0,
      textAlign: 'center', fontFamily: ICON_MONO, fontSize: s * 0.06,
      fontWeight: 500, letterSpacing: '0.3em', color: ICON_TEXT3,
    }}>CULL</div>
  </div>
);

const IconStack = (s) => {
  const cardW = s * 0.50, cardH = s * 0.66;
  const card = (color, tx, rot, z) => ({
    position: 'absolute', width: cardW, height: cardH,
    borderRadius: s * 0.06, background: color,
    transform: `translateX(${tx}px) rotate(${rot}deg)`,
    boxShadow: '0 4px 14px rgba(0,0,0,0.35)', zIndex: z,
  });
  return (
    <div style={{
      width: '100%', height: '100%', background: ICON_INK, position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={card(ICON_DEL, -s * 0.13, -10, 1)} />
      <div style={card(ICON_KEEP, s * 0.13, 10, 2)} />
      <div style={{
        ...card(ICON_AMBER, 0, 0, 3),
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: ICON_MONO, fontWeight: 600, fontSize: s * 0.22,
        color: ICON_INK, letterSpacing: '-0.04em',
      }}>C</div>
    </div>
  );
};

const IconCut = (s) => (
  <div style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden' }}>
    <div style={{
      position: 'absolute', inset: 0, background: ICON_KEEP,
      clipPath: 'polygon(0 0, 100% 0, 0 100%)',
    }} />
    <div style={{
      position: 'absolute', inset: 0, background: ICON_DEL,
      clipPath: 'polygon(100% 0, 100% 100%, 0 100%)',
    }} />
    <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none"
      style={{ position: 'absolute', inset: 0 }}>
      <line x1="100" y1="0" x2="0" y2="100" stroke={ICON_INK} strokeWidth="2"/>
    </svg>
    <div style={{
      position: 'absolute', inset: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: ICON_MONO, fontWeight: 600, fontSize: s * 0.38,
      color: ICON_INK, letterSpacing: '-0.04em',
    }}>C</div>
  </div>
);

const IconArrows = (s) => (
  <div style={{
    width: '100%', height: '100%', background: ICON_INK,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  }}>
    <svg width={s * 0.7} height={s * 0.7} viewBox="0 0 100 100" fill="none">
      <path d="M40 25 L15 50 L40 75" stroke={ICON_DEL} strokeWidth="8"
        strokeLinecap="round" strokeLinejoin="round"/>
      <line x1="15" y1="50" x2="42" y2="50" stroke={ICON_DEL} strokeWidth="8" strokeLinecap="round"/>
      <path d="M60 25 L85 50 L60 75" stroke={ICON_KEEP} strokeWidth="8"
        strokeLinecap="round" strokeLinejoin="round"/>
      <line x1="58" y1="50" x2="85" y2="50" stroke={ICON_KEEP} strokeWidth="8" strokeLinecap="round"/>
    </svg>
  </div>
);

const IconSlash = (s) => (
  <div style={{
    width: '100%', height: '100%', background: ICON_AMBER,
    position: 'relative', overflow: 'hidden',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  }}>
    <div style={{
      width: s * 0.55, height: s * 0.55, borderRadius: s * 0.06,
      background: ICON_INK, position: 'relative',
      boxShadow: `0 ${s * 0.02}px ${s * 0.04}px rgba(0,0,0,0.2)`,
    }}>
      <div style={{
        position: 'absolute', inset: s * 0.06, borderRadius: s * 0.03,
        backgroundImage: `repeating-linear-gradient(135deg, transparent 0 ${s * 0.025}px, oklch(0.86 0.15 88 / 0.25) ${s * 0.025}px ${s * 0.027}px)`,
      }} />
    </div>
    <div style={{
      position: 'absolute', top: '50%', left: '50%',
      width: s * 1.6, height: s * 0.04, background: ICON_INK,
      transform: 'translate(-50%, -50%) rotate(-32deg)',
      borderRadius: s * 0.02,
    }} />
  </div>
);

const IconRing = (s) => (
  <div style={{
    width: '100%', height: '100%', background: ICON_CREAM,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    position: 'relative',
  }}>
    <svg width={s * 0.78} height={s * 0.78} viewBox="0 0 100 100"
      style={{ position: 'absolute' }}>
      <circle cx="50" cy="50" r="42"
        stroke="oklch(0.16 0.005 250 / 0.08)" strokeWidth="6" fill="none"/>
      <circle cx="50" cy="50" r="42"
        stroke={ICON_INK} strokeWidth="6" fill="none"
        strokeDasharray="264" strokeDashoffset="95"
        strokeLinecap="round" transform="rotate(-90 50 50)"/>
    </svg>
    <span style={{
      fontFamily: ICON_MONO, fontWeight: 500, fontSize: s * 0.38,
      color: ICON_INK, letterSpacing: '-0.04em', marginTop: -s * 0.02,
    }}>C</span>
  </div>
);

const ICON_VARIANTS = [
  { id: 'mono-c', label: '01 · Wordmark', variant: IconMonoC,
    note: 'The Geist Mono C, amber on charcoal. Same DNA as the app — feels like a system utility.' },
  { id: 'stack',  label: '02 · Card stack', variant: IconStack,
    note: 'Three cards: delete, keep, current. The whole flow in one glyph.' },
  { id: 'cut',    label: '03 · Diagonal cut', variant: IconCut,
    note: 'Keep / delete bifurcation. Most editorial. Reads big at any size — strongest at 60px.' },
  { id: 'arrows', label: '04 · Swipe', variant: IconArrows,
    note: 'The gesture itself. Most literal — says what the app does at a glance.' },
  { id: 'slash',  label: '05 · Cut photo', variant: IconSlash,
    note: 'Light-mode option: photo with a slash through it. Stands out on a busy home screen.' },
  { id: 'ring',   label: '06 · Progress ring', variant: IconRing,
    note: 'Cream + ink. Reads as “progress through your library.” The most restrained option.' },
];

Object.assign(window, { AppIcon, ICON_VARIANTS });
