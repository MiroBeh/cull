// Cull — all screens
// Utilitarian dark aesthetic: Geist + Geist Mono, binary keep/delete colors,
// amber for storage stat, hairline dividers, dense lists.

const C = {
  bg: 'oklch(0.16 0.005 250)',
  surface: 'oklch(0.21 0.006 250)',
  surface2: 'oklch(0.26 0.007 250)',
  surfaceUp: 'oklch(0.30 0.008 250)',
  line: 'oklch(0.32 0.008 250 / 0.6)',
  lineSolid: 'oklch(0.32 0.008 250)',
  text: 'oklch(0.97 0.003 90)',
  text2: 'oklch(0.72 0.008 250)',
  text3: 'oklch(0.50 0.008 250)',
  text4: 'oklch(0.38 0.008 250)',
  keep: 'oklch(0.76 0.17 145)',
  keepDim: 'oklch(0.76 0.17 145 / 0.14)',
  del: 'oklch(0.68 0.21 28)',
  delDim: 'oklch(0.68 0.21 28 / 0.14)',
  amber: 'oklch(0.86 0.15 88)',
  amberDim: 'oklch(0.86 0.15 88 / 0.14)',
};

const SANS = '"Geist", "Inter", -apple-system, system-ui, sans-serif';
const MONO = '"Geist Mono", "JetBrains Mono", ui-monospace, "SF Mono", monospace';

// ─────────────────────────────────────────────────────────────
// Atoms
// ─────────────────────────────────────────────────────────────

function Mono({ children, size = 11, color, weight = 500, tracking = 0.08, style = {} }) {
  return (
    <span style={{
      fontFamily: MONO, fontSize: size, fontWeight: weight,
      letterSpacing: `${tracking}em`, textTransform: 'uppercase',
      color: color || C.text3, fontFeatureSettings: '"tnum" 1, "ss01" 1',
      whiteSpace: 'nowrap', display: 'inline-block',
      ...style,
    }}>{children}</span>
  );
}

function MonoNum({ children, size = 14, color, weight = 500, style = {} }) {
  return (
    <span style={{
      fontFamily: MONO, fontSize: size, fontWeight: weight,
      letterSpacing: '-0.01em', color: color || C.text,
      fontFeatureSettings: '"tnum" 1', whiteSpace: 'nowrap',
      display: 'inline-block',
      ...style,
    }}>{children}</span>
  );
}

function Hairline({ vertical = false, color, style = {} }) {
  return (
    <div style={{
      background: color || C.line,
      ...(vertical ? { width: 1, alignSelf: 'stretch' } : { height: 1, width: '100%' }),
      ...style,
    }} />
  );
}

function Bar({ pct, color, height = 3, bg }) {
  return (
    <div style={{
      width: '100%', height, background: bg || 'oklch(0.32 0.008 250 / 0.4)',
      borderRadius: 999, overflow: 'hidden',
    }}>
      <div style={{
        width: `${pct}%`, height: '100%', background: color || C.text,
        borderRadius: 999,
      }} />
    </div>
  );
}

function StatusChrome({ dark = true }) {
  // We use the IOSDevice's built-in status bar, this is just for inset reservations.
  return null;
}

// ─────────────────────────────────────────────────────────────
// Photo placeholder — utilitarian stripe + monogram
// ─────────────────────────────────────────────────────────────
function PhotoPlaceholder({ kind = 'A', tone = 0, rotate = 0, radius = 18, label, sublabel }) {
  // Stylized "photo" content. tone in 0..6 picks a hue.
  const hues = [25, 80, 140, 200, 260, 320, 10];
  const h = hues[tone % hues.length];
  const baseL = 0.42;
  const bg1 = `oklch(${baseL} 0.08 ${h})`;
  const bg2 = `oklch(${baseL - 0.12} 0.06 ${h})`;
  const stripe = `oklch(${baseL + 0.04} 0.10 ${h} / 0.5)`;

  return (
    <div style={{
      width: '100%', height: '100%', borderRadius: radius, overflow: 'hidden',
      position: 'relative', transform: `rotate(${rotate}deg)`,
      background: `linear-gradient(135deg, ${bg1}, ${bg2})`,
    }}>
      {/* diagonal stripes */}
      <div style={{
        position: 'absolute', inset: 0,
        backgroundImage: `repeating-linear-gradient(135deg, transparent 0 18px, ${stripe} 18px 19px)`,
        opacity: 0.7,
      }} />
      {/* large monogram */}
      <div style={{
        position: 'absolute', inset: 0, display: 'flex',
        alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{
          fontFamily: MONO, fontWeight: 500, fontSize: 110,
          color: 'rgba(255,255,255,0.16)', letterSpacing: '-0.04em',
        }}>{kind}</div>
      </div>
      {/* corner metadata */}
      {label && (
        <div style={{
          position: 'absolute', top: 12, left: 14, right: 14,
          display: 'flex', justifyContent: 'space-between',
          fontFamily: MONO, fontSize: 10, letterSpacing: '0.1em',
          color: 'rgba(255,255,255,0.7)', textTransform: 'uppercase',
        }}>
          <span>{label}</span>
          {sublabel && <span>{sublabel}</span>}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Icons (minimal, geometric, stroke)
// ─────────────────────────────────────────────────────────────
const Icon = {
  gear: (c = 'currentColor', s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <circle cx="12" cy="12" r="3" />
      <path d="M12 2v3M12 19v3M4.93 4.93l2.12 2.12M16.95 16.95l2.12 2.12M2 12h3M19 12h3M4.93 19.07l2.12-2.12M16.95 7.05l2.12-2.12" strokeLinecap="round"/>
    </svg>
  ),
  chev: (c = 'currentColor', s = 14, dir = 'right') => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2"
      style={{ transform: dir === 'left' ? 'rotate(180deg)' : dir === 'down' ? 'rotate(90deg)' : 'none' }}>
      <path d="M9 6l6 6-6 6" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  play: (c = 'currentColor', s = 14) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M7 4l13 8-13 8z"/>
    </svg>
  ),
  check: (c = 'currentColor', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12l5 5L20 6" />
    </svg>
  ),
  x: (c = 'currentColor', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round">
      <path d="M6 6l12 12M18 6L6 18" />
    </svg>
  ),
  undo: (c = 'currentColor', s = 16) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 8l4-4M3 8l4 4M3 8h11a6 6 0 010 12h-3" />
    </svg>
  ),
  trash: (c = 'currentColor', s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13M10 11v6M14 11v6" />
    </svg>
  ),
  swipe: (c = 'currentColor', s = 80) => (
    <svg width={s} height={s} viewBox="0 0 80 80" fill="none" stroke={c} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
      <rect x="22" y="14" width="36" height="48" rx="6"/>
      <path d="M14 30l8 8-8 8M66 30l-8 8 8 8" />
      <path d="M28 38h-6M58 38h-6" />
    </svg>
  ),
  stack: (c = 'currentColor', s = 80) => (
    <svg width={s} height={s} viewBox="0 0 80 80" fill="none" stroke={c} strokeWidth="1.4" strokeLinejoin="round">
      <rect x="14" y="22" width="40" height="46" rx="5" opacity="0.35"/>
      <rect x="22" y="16" width="40" height="46" rx="5" opacity="0.6"/>
      <rect x="30" y="10" width="40" height="46" rx="5"/>
      <circle cx="42" cy="24" r="3" />
      <path d="M30 46l8-8 8 8 10-10 14 14" />
    </svg>
  ),
  spark: (c = 'currentColor', s = 80) => (
    <svg width={s} height={s} viewBox="0 0 80 80" fill="none" stroke={c} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M40 10v60M10 40h60M22 22l36 36M58 22L22 58" opacity="0.35"/>
      <circle cx="40" cy="40" r="14" fill={c} stroke="none"/>
    </svg>
  ),
};

// ─────────────────────────────────────────────────────────────
// Tiny status-bar reserve (the IOSDevice already paints the real one)
// ─────────────────────────────────────────────────────────────
const STATUS_PAD = 54;

// ═════════════════════════════════════════════════════════════
// 1. HOME / MONTH LIST
// ═════════════════════════════════════════════════════════════
function ScreenHome() {
  const months = [
    { m: 'April', y: '2026', total: 124, left: 48, freed: 0.28 },
    { m: 'March', y: '2026', total: 211, left: 87, freed: 0.42 },
    { m: 'February', y: '2026', total: 290, left: 155, freed: 0 },
    { m: 'January', y: '2026', total: 240, left: 116, freed: 0 },
    { m: 'December', y: '2025', total: 312, left: 92, freed: 0.88 },
    { m: 'November', y: '2025', total: 220, left: 0, freed: 1.4, done: true },
    { m: 'October', y: '2025', total: 178, left: 84, freed: 0 },
    { m: 'September', y: '2025', total: 412, left: 314, freed: 0 },
  ];

  return (
    <div style={{
      height: '100%', background: C.bg, color: C.text, fontFamily: SANS,
      display: 'flex', flexDirection: 'column',
      paddingTop: STATUS_PAD,
    }}>
      {/* Top bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '14px 24px 0',
      }}>
        <Mono size={11} tracking={0.22} color={C.text}>CULL</Mono>
        <div style={{
          width: 32, height: 32, borderRadius: 999, background: C.surface,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: C.text2,
        }}>{Icon.gear(C.text2, 15)}</div>
      </div>

      {/* Hero: recoverable storage */}
      <div style={{ padding: '36px 24px 20px' }}>
        <Mono size={10} tracking={0.22} color={C.text3}>RECOVERABLE</Mono>
        <div style={{ marginTop: 10, display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <span style={{
            fontFamily: MONO, fontSize: 64, fontWeight: 500, color: C.amber,
            letterSpacing: '-0.04em', lineHeight: 1,
            fontFeatureSettings: '"tnum" 1',
          }}>8.4</span>
          <span style={{
            fontFamily: MONO, fontSize: 22, fontWeight: 500, color: C.amber,
            letterSpacing: '0.02em',
          }}>GB</span>
        </div>
        <div style={{ marginTop: 10, color: C.text2, fontSize: 13, fontWeight: 400 }}>
          across <MonoNum size={13} color={C.text}>1,896</MonoNum> unreviewed photos
        </div>
      </div>

      {/* Continue CTA */}
      <div style={{ padding: '0 16px 22px' }}>
        <div style={{
          background: C.surface, borderRadius: 14, padding: '14px 16px',
          display: 'flex', alignItems: 'center', gap: 14,
          border: `1px solid ${C.lineSolid}`,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10, background: C.amberDim,
            color: C.amber, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{Icon.play(C.amber, 14)}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 15, fontWeight: 500, color: C.text, lineHeight: 1.2 }}>
              Continue April
            </div>
            <Mono size={10} tracking={0.14} color={C.text3} style={{ marginTop: 4, display: 'block' }}>
              76 ⁄ 124 · 124 MB FREED
            </Mono>
          </div>
          <div style={{ width: 80 }}>
            <Bar pct={61} color={C.amber} />
          </div>
        </div>
      </div>

      {/* By month header */}
      <div style={{
        display: 'flex', justifyContent: 'space-between',
        padding: '0 24px 10px',
      }}>
        <Mono size={10} tracking={0.22} color={C.text3}>BY MONTH</Mono>
        <Mono size={10} tracking={0.22} color={C.text4}>UNREVIEWED · FREED</Mono>
      </div>

      {/* Month list */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '0 16px 16px' }}>
        <div style={{
          background: C.surface, borderRadius: 14, overflow: 'hidden',
          border: `1px solid ${C.lineSolid}`,
        }}>
          {months.map((m, i) => {
            const reviewed = m.total - m.left;
            const pct = (reviewed / m.total) * 100;
            return (
              <div key={i}>
                <div style={{
                  display: 'flex', alignItems: 'center',
                  padding: '12px 16px', gap: 12, minHeight: 52,
                }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                      <span style={{ fontSize: 15, fontWeight: 500, color: m.done ? C.text3 : C.text }}>
                        {m.m}
                      </span>
                      <MonoNum size={11} color={C.text4}>{m.y}</MonoNum>
                      {m.done && (
                        <span style={{ marginLeft: 4, color: C.keep, display: 'inline-flex' }}>
                          {Icon.check(C.keep, 12)}
                        </span>
                      )}
                    </div>
                    <div style={{ marginTop: 6, width: 84 }}>
                      <Bar pct={pct} color={m.done ? C.keep : C.text2} height={2} />
                    </div>
                  </div>
                  <div style={{
                    textAlign: 'right', flexShrink: 0,
                    display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 2,
                  }}>
                    <MonoNum size={14} color={m.done ? C.text3 : C.text}>
                      {m.left.toString().padStart(3, '\u2007')}
                    </MonoNum>
                    {m.freed > 0 && (
                      <Mono size={10} tracking={0.08} color={C.amber}>
                        {`+${m.freed.toFixed(2)} GB`}
                      </Mono>
                    )}
                  </div>
                  <div style={{ color: C.text4 }}>{Icon.chev(C.text4, 12)}</div>
                </div>
                {i < months.length - 1 && <Hairline />}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 2. SWIPE / REVIEW SCREEN
// ═════════════════════════════════════════════════════════════
function ScreenSwipe({ tilt = 0 }) {
  // tilt > 0 = leaning right (keep), tilt < 0 = leaning left (delete)
  const isKeep = tilt > 0;
  const isDel = tilt < 0;
  const tiltAbs = Math.abs(tilt);

  return (
    <div style={{
      height: '100%', background: C.bg, color: C.text, fontFamily: SANS,
      display: 'flex', flexDirection: 'column', position: 'relative',
      paddingTop: STATUS_PAD,
    }}>
      {/* Top bar */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 20px 6px',
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 999, background: C.surface,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: C.text2,
        }}>{Icon.chev(C.text2, 13, 'left')}</div>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 15, fontWeight: 500, color: C.text, lineHeight: 1 }}>April</div>
          <Mono size={9} tracking={0.18} color={C.text3} style={{ marginTop: 3, display: 'block' }}>2026</Mono>
        </div>
        <div style={{
          padding: '6px 12px', borderRadius: 999, background: C.surface,
          color: C.text2, fontFamily: MONO, fontSize: 11, fontWeight: 500,
          letterSpacing: '0.06em',
        }}>END</div>
      </div>

      {/* Progress strip */}
      <div style={{ padding: '8px 20px 0' }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between', marginBottom: 6,
        }}>
          <Mono size={10} tracking={0.14} color={C.text3}>16 / 48</Mono>
          <Mono size={10} tracking={0.14} color={C.amber}>+124 MB FREED</Mono>
        </div>
        <Bar pct={(16 / 48) * 100} color={C.text} height={2} />
      </div>

      {/* Card stack area */}
      <div style={{
        flex: 1, position: 'relative',
        margin: '20px 0 0',
        padding: '0 20px',
        display: 'flex', alignItems: 'flex-start', justifyContent: 'center',
      }}>
        {/* Side rails: delete / keep targets */}
        <div style={{
          position: 'absolute', top: 30, bottom: 100, left: 6, width: 14,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          gap: 10, color: isDel ? C.del : C.text4,
          transition: 'color 150ms',
        }}>
          <div style={{
            color: isDel ? C.del : C.text4,
          }}>{Icon.trash(isDel ? C.del : C.text4, 14)}</div>
          <Mono size={9} tracking={0.32} color={isDel ? C.del : C.text4}
            style={{ writingMode: 'vertical-rl', transform: 'rotate(180deg)' }}>
            DELETE
          </Mono>
        </div>
        <div style={{
          position: 'absolute', top: 30, bottom: 100, right: 6, width: 14,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          gap: 10, color: isKeep ? C.keep : C.text4,
          transition: 'color 150ms',
        }}>
          <div>{Icon.check(isKeep ? C.keep : C.text4, 16)}</div>
          <Mono size={9} tracking={0.32} color={isKeep ? C.keep : C.text4}
            style={{ writingMode: 'vertical-rl' }}>
            KEEP
          </Mono>
        </div>

        {/* Stack: 3 cards */}
        <div style={{
          position: 'relative', width: '100%', maxWidth: 320,
          aspectRatio: '3 / 4',
        }}>
          {/* Card -2 (peek) */}
          <div style={{
            position: 'absolute', inset: 0, transform: 'scale(0.88) translateY(28px)',
            opacity: 0.5,
          }}>
            <PhotoPlaceholder kind="S" tone={3} />
          </div>
          {/* Card -1 (peek) */}
          <div style={{
            position: 'absolute', inset: 0, transform: 'scale(0.94) translateY(14px)',
            opacity: 0.75,
          }}>
            <PhotoPlaceholder kind="P" tone={1} />
          </div>
          {/* Active card */}
          <div style={{
            position: 'absolute', inset: 0,
            transform: `translateX(${tilt * 2}px) rotate(${tilt * 0.08}deg)`,
            transition: 'transform 220ms cubic-bezier(.2,.7,.3,1)',
            filter: 'drop-shadow(0 18px 30px rgba(0,0,0,0.4))',
          }}>
            <PhotoPlaceholder
              kind="L"
              tone={0}
              label="IMG_4823"
              sublabel="13·APR"
            />
            {/* Decision overlay */}
            {isKeep && tiltAbs > 30 && (
              <div style={{
                position: 'absolute', top: 20, left: 20,
                padding: '6px 12px', border: `2px solid ${C.keep}`,
                borderRadius: 6, transform: 'rotate(-8deg)',
                fontFamily: MONO, fontSize: 18, fontWeight: 600,
                letterSpacing: '0.08em', color: C.keep,
                background: 'rgba(0,0,0,0.3)',
              }}>KEEP</div>
            )}
            {isDel && tiltAbs > 30 && (
              <div style={{
                position: 'absolute', top: 20, right: 20,
                padding: '6px 12px', border: `2px solid ${C.del}`,
                borderRadius: 6, transform: 'rotate(8deg)',
                fontFamily: MONO, fontSize: 18, fontWeight: 600,
                letterSpacing: '0.08em', color: C.del,
                background: 'rgba(0,0,0,0.3)',
              }}>DELETE</div>
            )}
          </div>
        </div>
      </div>

      {/* Metadata strip */}
      <div style={{
        padding: '14px 24px 6px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <Mono size={11} tracking={0.08} color={C.text2}>13·APR·2026 · 16:42</Mono>
          <div style={{ marginTop: 4 }}>
            <Mono size={9} tracking={0.14} color={C.text4}>3.4 MB · 4032×3024 · HEIC</Mono>
          </div>
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6, color: C.text3,
          padding: '6px 10px', background: C.surface, borderRadius: 999,
          border: `1px solid ${C.lineSolid}`,
        }}>
          {Icon.undo(C.text2, 13)}
          <Mono size={10} tracking={0.12} color={C.text2}>UNDO</Mono>
        </div>
      </div>

      {/* Bottom dot indicators / batch decisions */}
      <div style={{
        padding: '6px 24px 28px',
        display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6,
      }}>
        {[...Array(20)].map((_, i) => (
          <div key={i} style={{
            width: i === 15 ? 16 : 4, height: 4, borderRadius: 999,
            background: i < 16 ? (i % 5 === 0 ? C.del : C.keep) : C.surface2,
            opacity: i === 15 ? 1 : (i < 16 ? 0.7 : 1),
          }} />
        ))}
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 3. END-OF-MONTH
// ═════════════════════════════════════════════════════════════
function ScreenEnd() {
  return (
    <div style={{
      height: '100%', background: C.bg, color: C.text, fontFamily: SANS,
      display: 'flex', flexDirection: 'column',
      paddingTop: STATUS_PAD,
    }}>
      {/* Top bar */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', padding: '14px 24px 0',
      }}>
        <Mono size={11} tracking={0.22} color={C.text3}>SESSION · 04·26</Mono>
        <Mono size={11} tracking={0.22} color={C.text3}>14:23</Mono>
      </div>

      {/* Hero */}
      <div style={{ padding: '40px 24px 0' }}>
        <div style={{
          fontSize: 40, fontWeight: 500, color: C.text, lineHeight: 1.05,
          letterSpacing: '-0.02em',
        }}>
          April done.
        </div>
        <div style={{ marginTop: 6, fontSize: 16, color: C.text3 }}>
          You cleared 48 photos in 6 minutes.
        </div>
      </div>

      {/* Freed amount */}
      <div style={{ padding: '30px 24px 0' }}>
        <Mono size={10} tracking={0.22} color={C.text3}>STORAGE FREED</Mono>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 8 }}>
          <span style={{
            fontFamily: MONO, fontSize: 80, fontWeight: 500, color: C.amber,
            letterSpacing: '-0.04em', lineHeight: 0.95,
            fontFeatureSettings: '"tnum" 1',
          }}>1.24</span>
          <span style={{
            fontFamily: MONO, fontSize: 28, fontWeight: 500, color: C.amber,
          }}>GB</span>
        </div>
      </div>

      {/* Stats grid */}
      <div style={{ padding: '32px 16px 0' }}>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr',
          background: C.surface, borderRadius: 14, overflow: 'hidden',
          border: `1px solid ${C.lineSolid}`,
        }}>
          <StatCell label="KEPT" value="19" color={C.keep} />
          <StatCell label="DELETED" value="29" color={C.del} borderLeft />
          <StatCell label="LARGEST" value="48 MB" color={C.text} borderTop />
          <StatCell label="AVG · MB" value="26.1" color={C.text} borderTop borderLeft />
        </div>
      </div>

      {/* Decision distribution */}
      <div style={{ padding: '24px 24px 0' }}>
        <Mono size={10} tracking={0.22} color={C.text3}>DECISIONS</Mono>
        <div style={{
          marginTop: 10, height: 8, borderRadius: 999,
          display: 'flex', overflow: 'hidden', gap: 2,
        }}>
          <div style={{ flex: 29, background: C.del, borderRadius: '999px 0 0 999px' }} />
          <div style={{ flex: 19, background: C.keep, borderRadius: '0 999px 999px 0' }} />
        </div>
        <div style={{
          marginTop: 8, display: 'flex', justifyContent: 'space-between',
        }}>
          <Mono size={10} tracking={0.12} color={C.del}>29 DELETED · 60%</Mono>
          <Mono size={10} tracking={0.12} color={C.keep}>19 KEPT · 40%</Mono>
        </div>
      </div>

      <div style={{ flex: 1 }} />

      {/* CTAs */}
      <div style={{
        padding: '16px 16px 28px',
        display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        <button style={{
          background: C.text, color: C.bg, border: 'none', borderRadius: 14,
          padding: '16px', fontFamily: SANS, fontSize: 15, fontWeight: 500,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span>Continue to March</span>
          <Mono size={10} tracking={0.14} color={C.bg}>87 LEFT ↗</Mono>
        </button>
        <button style={{
          background: 'transparent', color: C.text2, border: `1px solid ${C.lineSolid}`,
          borderRadius: 14, padding: '14px', fontFamily: SANS, fontSize: 14, fontWeight: 500,
        }}>
          Back to library
        </button>
      </div>
    </div>
  );
}

function StatCell({ label, value, color, borderLeft, borderTop }) {
  return (
    <div style={{
      padding: '16px 16px',
      borderLeft: borderLeft ? `1px solid ${C.lineSolid}` : 'none',
      borderTop: borderTop ? `1px solid ${C.lineSolid}` : 'none',
    }}>
      <Mono size={10} tracking={0.18} color={C.text3}>{label}</Mono>
      <div style={{
        marginTop: 8, fontFamily: MONO, fontSize: 26, fontWeight: 500, color,
        letterSpacing: '-0.02em', fontFeatureSettings: '"tnum" 1',
      }}>{value}</div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 4–6. ONBOARDING (3 screens)
// ═════════════════════════════════════════════════════════════
function ScreenOnboard({ step = 1 }) {
  const slides = [
    {
      Icon: Icon.stack,
      eyebrow: 'CULL · v1.0',
      title: 'Cull your camera roll.',
      body: 'Tens of thousands of photos. One swipe per decision. Reclaim the gigabytes you forgot you were paying for.',
    },
    {
      Icon: Icon.swipe,
      eyebrow: 'MECHANICS',
      title: 'Swipe to decide.',
      body: 'Right keeps. Left deletes. Down skips. Tap to inspect. Long-press to undo. Photos you keep are remembered for 90 days.',
    },
    {
      Icon: Icon.spark,
      eyebrow: 'PERMISSION',
      title: 'One thing first.',
      body: 'Cull needs access to your photo library. Nothing leaves your device. Deletions land in Recently Deleted — recoverable for 30 days.',
    },
  ];
  const s = slides[step - 1];
  const isLast = step === 3;

  return (
    <div style={{
      height: '100%', background: C.bg, color: C.text, fontFamily: SANS,
      display: 'flex', flexDirection: 'column',
      paddingTop: STATUS_PAD,
    }}>
      {/* Skip + step counter */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', padding: '14px 24px 0',
      }}>
        <Mono size={11} tracking={0.22} color={C.text3}>{s.eyebrow}</Mono>
        <Mono size={11} tracking={0.22} color={C.text3}>{step.toString().padStart(2, '0')} / 03</Mono>
      </div>

      {/* Body */}
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        padding: '40px 28px 0', justifyContent: 'flex-start',
      }}>
        <div style={{
          width: 96, height: 96, borderRadius: 24, background: C.surface,
          border: `1px solid ${C.lineSolid}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: C.text, marginBottom: 36,
        }}>
          {s.Icon(C.text, 56)}
        </div>
        <div style={{
          fontSize: 34, fontWeight: 500, color: C.text, lineHeight: 1.05,
          letterSpacing: '-0.025em',
        }}>
          {s.title}
        </div>
        <div style={{
          marginTop: 16, fontSize: 15, color: C.text2, lineHeight: 1.5,
          maxWidth: 320, textWrap: 'pretty',
        }}>
          {s.body}
        </div>
      </div>

      {/* Step indicator + CTA */}
      <div style={{ padding: '0 24px 28px' }}>
        <div style={{ display: 'flex', gap: 6, marginBottom: 20 }}>
          {[0, 1, 2].map((i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 999,
              background: i < step ? C.text : C.surface2,
            }} />
          ))}
        </div>
        <button style={{
          width: '100%', padding: '16px', borderRadius: 14, border: 'none',
          background: isLast ? C.amber : C.text,
          color: C.bg, fontFamily: SANS, fontSize: 15, fontWeight: 500,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <span>{isLast ? 'Grant access' : 'Continue'}</span>
          <Mono size={10} tracking={0.14} color={C.bg}>
            {isLast ? 'BEGIN ↗' : `→ ${(step + 1).toString().padStart(2, '0')}`}
          </Mono>
        </button>
        {!isLast && (
          <div style={{
            marginTop: 14, textAlign: 'center',
          }}>
            <Mono size={10} tracking={0.18} color={C.text3}>SKIP</Mono>
          </div>
        )}
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 7. SETTINGS
// ═════════════════════════════════════════════════════════════
function ScreenSettings() {
  return (
    <div style={{
      height: '100%', background: C.bg, color: C.text, fontFamily: SANS,
      display: 'flex', flexDirection: 'column',
      paddingTop: STATUS_PAD,
    }}>
      {/* Top bar */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        padding: '12px 20px 0',
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 999, background: C.surface,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{Icon.x(C.text2, 14)}</div>
        <div style={{ fontSize: 15, fontWeight: 500, color: C.text }}>Settings</div>
        <div style={{ width: 32 }} />
      </div>

      <div style={{ padding: '28px 16px 16px', flex: 1, overflow: 'auto' }}>

        <SectionHeader label="REVIEW HISTORY" right="90·DAY MEMORY" />
        <Group>
          <Row left="Photos remembered" right={<MonoNum size={14}>1,247</MonoNum>} />
          <Hairline />
          <Row left="Memory window" right={<MonoNum size={14} color={C.text2}>90 D</MonoNum>} />
          <Hairline />
          <Row left="Oldest entry" right={<Mono size={11} color={C.text2}>13·JAN·26</Mono>} />
        </Group>

        <Spacer />

        <SectionHeader label="LIFETIME" />
        <Group>
          <Row left="Photos culled" right={<MonoNum size={14} color={C.text}>4,812</MonoNum>} />
          <Hairline />
          <Row left="Storage freed" right={<MonoNum size={14} color={C.amber}>32.6 GB</MonoNum>} />
          <Hairline />
          <Row left="Time spent" right={<MonoNum size={14} color={C.text2}>3 h 18 m</MonoNum>} />
        </Group>

        <Spacer />

        <SectionHeader label="BEHAVIOR" />
        <Group>
          <RowToggle left="Haptics" on />
          <Hairline />
          <RowToggle left="Confirm before delete" on={false} />
          <Hairline />
          <RowToggle left="Show metadata strip" on />
        </Group>

        <Spacer />

        <Group destructive>
          <Row
            left={<span style={{ color: C.del }}>Reset review history</span>}
            right={<Mono size={10} color={C.del}>CLEAR 1,247 ↗</Mono>}
          />
        </Group>

        <div style={{
          padding: '24px 8px 8px', display: 'flex',
          justifyContent: 'space-between',
        }}>
          <Mono size={10} tracking={0.18} color={C.text4}>CULL 1.0.3</Mono>
          <Mono size={10} tracking={0.18} color={C.text4}>BUILD 248</Mono>
        </div>

      </div>
    </div>
  );
}

function SectionHeader({ label, right }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', padding: '0 8px 8px',
    }}>
      <Mono size={10} tracking={0.22} color={C.text3}>{label}</Mono>
      {right && <Mono size={10} tracking={0.22} color={C.text4}>{right}</Mono>}
    </div>
  );
}

function Group({ children, destructive }) {
  return (
    <div style={{
      background: C.surface, borderRadius: 14,
      border: `1px solid ${destructive ? 'oklch(0.68 0.21 28 / 0.3)' : C.lineSolid}`,
      overflow: 'hidden',
    }}>{children}</div>
  );
}

function Row({ left, right }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '13px 16px', minHeight: 46,
    }}>
      <div style={{ fontSize: 14, color: C.text, fontWeight: 400 }}>{left}</div>
      <div>{right}</div>
    </div>
  );
}

function RowToggle({ left, on }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '13px 16px', minHeight: 46,
    }}>
      <div style={{ fontSize: 14, color: C.text }}>{left}</div>
      <div style={{
        width: 36, height: 22, borderRadius: 999,
        background: on ? C.keep : C.surface2,
        border: `1px solid ${on ? C.keep : C.lineSolid}`,
        position: 'relative', transition: 'all 150ms',
      }}>
        <div style={{
          position: 'absolute', top: 2, left: on ? 16 : 2,
          width: 16, height: 16, borderRadius: 999,
          background: on ? C.bg : C.text2,
          transition: 'all 150ms',
        }} />
      </div>
    </div>
  );
}

function Spacer() {
  return <div style={{ height: 22 }} />;
}

Object.assign(window, {
  ScreenHome, ScreenSwipe, ScreenEnd, ScreenOnboard, ScreenSettings,
});
