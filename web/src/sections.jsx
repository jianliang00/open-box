/* ============================================================
   Landing sections for OpenBox
   ============================================================ */

/* ---------- NAV ---------- */
const Nav = () => {
  const [scrolled, setScrolled] = React.useState(false);
  const compact = useMedia("(max-width: 760px)");
  React.useEffect(() => {
    const on = () => setScrolled(window.scrollY > 12);
    window.addEventListener("scroll", on);
    return () => window.removeEventListener("scroll", on);
  }, []);
  return (
    <nav style={{
      position: "sticky", top: 0, zIndex: 50,
      background: scrolled ? "color-mix(in oklch, var(--bg) 85%, transparent)" : "transparent",
      backdropFilter: scrolled ? "blur(14px) saturate(140%)" : "none",
      WebkitBackdropFilter: scrolled ? "blur(14px) saturate(140%)" : "none",
      borderBottom: scrolled ? "1px solid var(--line)" : "1px solid transparent",
      transition: "background 160ms ease, border-color 160ms ease",
    }}>
      <div style={{
        maxWidth: 1280, margin: "0 auto", padding: compact ? "12px 18px" : "14px 32px",
        display: "flex", alignItems: "center", gap: compact ? 12 : 28,
      }}>
        <a href="#top" style={{ display: "flex", alignItems: "center", gap: 10, flexShrink: 0 }}>
          <Logo size={22}/>
          <span style={{ fontWeight: 600, fontSize: 15, letterSpacing: -0.2 }}>OpenBox</span>
          {!compact && <Pill tone="ghost" size="xs" mono>v0.0.6 · alpha</Pill>}
        </a>
        <div style={{
          display: compact ? "none" : "flex", gap: 24, marginLeft: 24,
          fontSize: 14, color: "var(--ink-3)",
        }}>
          <a href="#features" style={{ color: "inherit" }}>Features</a>
          <a href="#terminal" style={{ color: "inherit" }}>Terminal</a>
          <a href="#compat" style={{ color: "inherit" }}>Compatibility</a>
          <a href="#faq" style={{ color: "inherit" }}>FAQ</a>
        </div>
        <div style={{ flex: 1 }}/>
        <a href="https://github.com/jianliang00/open-box" aria-label="GitHub" style={{
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          width: 34, height: 34,
          color: "var(--ink-2)",
        }}>
          <Icon name="github" size={18}/>
        </a>
        <Btn variant="solid" size="sm" icon="download" href="#download">{compact ? "Download" : "Download DMG"}</Btn>
      </div>
    </nav>
  );
};

/* ---------- LOGO (original, geometric — nested cubes) ---------- */
const Logo = ({ size = 24 }) => (
  <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
    <rect x="1.5" y="1.5" width="29" height="29" rx="6.5"
      fill="var(--ink)" stroke="var(--ink)" strokeWidth="1"/>
    <g transform="translate(16 17)">
      {/* outer cube outline */}
      <path d="M 0 -9 L 8 -5 L 8 5 L 0 9 L -8 5 L -8 -5 Z"
        stroke="#f6f5f1" strokeWidth="1.2" fill="none"/>
      <path d="M -8 -5 L 0 -1 L 8 -5 M 0 -1 L 0 9"
        stroke="#f6f5f1" strokeWidth="1.2" fill="none"/>
      {/* inner accent cube */}
      <path d="M 0 -4 L 4 -2 L 4 3 L 0 5 L -4 3 L -4 -2 Z"
        fill="var(--accent)" opacity="0.95"/>
    </g>
  </svg>
);

/* ---------- HERO ---------- */
const Hero = () => {
  const compact = useMedia("(max-width: 760px)");
  return (
    <section id="top" style={{ position: "relative", overflow: "hidden" }}>
      <Section pad={[72, 32]} style={{ paddingBottom: 48 }}>
        {/* top strap */}
        <div style={{
          display: "flex", alignItems: compact ? "flex-start" : "center", gap: 12, marginBottom: compact ? 34 : 56,
          fontFamily: "var(--font-mono)", fontSize: 12, color: "var(--ink-4)",
          flexWrap: "wrap",
        }}>
          <Pill tone="accent" size="xs" mono>NEW</Pill>
          <span>Ready-to-use macOS 26 guest images — launch a sandbox in under 90s.</span>
          <a href="#download" style={{ color: "var(--ink-2)", textDecoration: "underline", textDecorationColor: "var(--line-2)", textUnderlineOffset: 3 }}>
            Read release notes →
          </a>
        </div>

        {/* headline */}
        <div style={{ maxWidth: 980 }}>
          <h1 style={{
            fontFamily: "var(--font-body)",
            fontSize: compact ? "clamp(42px, 13vw, 64px)" : "clamp(52px, 8vw, 104px)",
            lineHeight: 0.96, fontWeight: 500,
            letterSpacing: "-0.035em",
            margin: "0 0 28px 0",
            textWrap: "balance",
          }}>
            A disposable Mac,<br/>
            <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400, letterSpacing: "-0.01em" }}>
              opened in a box.
            </span>
          </h1>

          <p style={{
            fontSize: compact ? 17 : 20, lineHeight: 1.45, color: "var(--ink-3)",
            maxWidth: 680, margin: "0 0 36px 0", fontWeight: 400,
          }}>
            OpenBox is a desktop app for creating isolated macOS sandboxes on Apple Silicon.
            Launch a full guest desktop, run commands, and throw it away — without ever touching your real machine.
          </p>

          <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap", marginBottom: 24 }}>
            <Btn variant="accent" size="lg" icon="download" href="https://github.com/jianliang00/open-box/releases/latest">
              Download for macOS
            </Btn>
            <Btn variant="ghost" size="lg" icon="github" iconRight="arrow-up-right" href="https://github.com/jianliang00/open-box">
              View source
            </Btn>
            <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "var(--ink-4)", marginLeft: compact ? 0 : 8 }}>
              <Icon name="check" size={14}/> Apple&nbsp;Silicon · macOS&nbsp;26+ · Apache&nbsp;2.0
            </div>
          </div>

        </div>
      </Section>

      {/* showcase window — bleed */}
      <Section pad={[24, 32]} style={{ paddingTop: 24 }}>
        <HeroShowcase/>
      </Section>

      {/* logo bar / used for */}
      <Section pad={[40, 32]} style={{ paddingTop: 8, paddingBottom: 40 }}>
        <div style={{
          display: "grid", gridTemplateColumns: compact ? "1fr" : "repeat(4, 1fr)", gap: 0,
          borderTop: "1px solid var(--line)", borderBottom: "1px solid var(--line)",
        }}>
          {[
            ["AGENT EXPLORATION", "A safe desktop for Codex, Claude Code, and other coding agents."],
            ["APP TESTING",       "Install + launch unfamiliar apps without risking your main OS."],
            ["CLI WORKFLOWS",     "Run one-off scripts in a throwaway shell with full network isolation."],
            ["ENV REPRO",         "Pin exact macOS images; re-create sandbox state on demand."],
          ].map(([k, v], i) => (
            <div key={k} style={{
              padding: "28px 24px",
              borderLeft: !compact && i !== 0 ? "1px solid var(--line)" : "none",
              borderTop: compact && i !== 0 ? "1px solid var(--line)" : "none",
            }}>
              <div style={{ fontFamily: "var(--font-mono)", fontSize: 10.5, letterSpacing: 1.5, color: "var(--ink-4)", marginBottom: 10 }}>
                {String(i+1).padStart(2,"0")} · {k}
              </div>
              <div style={{ fontSize: 14, color: "var(--ink-2)", lineHeight: 1.45 }}>{v}</div>
            </div>
          ))}
        </div>
      </Section>
    </section>
  );
};

/* ---------- Copy line ---------- */
const CopyLine = ({ text }) => {
  const [copied, setCopied] = React.useState(false);
  const copy = () => {
    navigator.clipboard?.writeText(text);
    setCopied(true); setTimeout(() => setCopied(false), 1400);
  };
  return (
    <button onClick={copy} style={{
      display: "inline-flex", alignItems: "center", gap: 12,
      padding: "10px 14px",
      background: "var(--surface)",
      border: "1px solid var(--line)",
      borderRadius: 10,
      fontFamily: "var(--font-mono)", fontSize: 13,
      color: "var(--ink-2)", cursor: "pointer",
    }}>
      <span style={{ color: "var(--accent)" }}>$</span>
      <span>{text}</span>
      <span style={{ width: 1, height: 16, background: "var(--line)", margin: "0 4px" }}/>
      <span style={{ display: "inline-flex", alignItems: "center", gap: 6, color: "var(--ink-4)", fontSize: 12 }}>
        <Icon name={copied ? "check" : "copy"} size={13}/>
        {copied ? "copied" : "copy"}
      </span>
    </button>
  );
};

/* ---------- HERO SHOWCASE: tabbed window ---------- */
const HeroShowcase = () => {
  const [tab, setTab] = React.useState("app");
  const compact = useMedia("(max-width: 760px)");
  const tabs = [
    { id: "app",     label: "Manager",       img: "showcase/openbox-showcase-1.png", cap: "Sandbox overview — list, status, configuration" },
    { id: "desktop", label: "Guest desktop", img: "showcase/openbox-showcase-2.png", cap: "Launch a full macOS guest session, then close the window to leave it running" },
    { id: "term",    label: "Embedded term", img: "showcase/openbox-showcase-3.png", cap: "Attach to a workload; logs and diagnostics stay scoped to the sandbox" },
  ];
  const active = tabs.find(t => t.id === tab);

  return (
    <div style={{ position: "relative" }}>
      {/* floating annotations */}
      {!compact && (
        <>
          <Annotation
            style={{ top: 60, left: -4 }}
            label="01"
            text={<>Create, start, stop,<br/>inspect, remove.</>}
          />
          <Annotation
            style={{ top: 260, right: -8, textAlign: "right", alignItems: "flex-end" }}
            label="02"
            text={<>Every sandbox pins<br/>an OCI image + digest.</>}
          />
          <Annotation
            style={{ bottom: -12, left: "30%" }}
            label="03"
            text={<>Signed + notarized<br/>DMG via GitHub Actions.</>}
          />
        </>
      )}

      <div style={{
        display: "flex", gap: 6, marginBottom: 14,
        padding: 4, background: "var(--bg-2)",
        border: "1px solid var(--line)",
        borderRadius: 10, width: compact ? "100%" : "fit-content",
        overflowX: "auto",
      }}>
        {tabs.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} aria-pressed={tab === t.id} style={{
            padding: "7px 14px",
            fontFamily: "var(--font-mono)", fontSize: 12,
            background: tab === t.id ? "var(--surface)" : "transparent",
            border: tab === t.id ? "1px solid var(--line)" : "1px solid transparent",
            borderRadius: 7, cursor: "pointer",
            color: tab === t.id ? "var(--ink)" : "var(--ink-3)",
            boxShadow: tab === t.id ? "0 1px 1px rgba(0,0,0,0.04)" : "none",
          }}>
            <span style={{ color: "var(--ink-4)", marginRight: 8 }}>{t.id}</span>
            {t.label}
          </button>
        ))}
      </div>

      <MacWindow title="OpenBox" style={{ maxWidth: 1180 }}>
        <div style={{ position: "relative", aspectRatio: "2940/1716", background: "#f5f5f7" }}>
          <img src={active.img} alt={active.label}
            style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }}/>
        </div>
      </MacWindow>

      <div style={{
        marginTop: 14, display: "flex", justifyContent: "space-between", gap: 8,
        flexDirection: compact ? "column" : "row",
        fontFamily: "var(--font-mono)", fontSize: 12, color: "var(--ink-4)",
      }}>
        <span>fig. {tabs.findIndex(t => t.id === tab) + 1} — {active.cap}</span>
        <span>{tabs.findIndex(t => t.id === tab) + 1}/{tabs.length}</span>
      </div>
    </div>
  );
};

const Annotation = ({ style, label, text }) => (
  <div style={{
    position: "absolute", zIndex: 2,
    display: "flex", flexDirection: "column", gap: 6,
    fontFamily: "var(--font-mono)", fontSize: 11,
    color: "var(--ink-3)", pointerEvents: "none",
    ...style
  }}>
    <span style={{
      width: 22, height: 22, borderRadius: "50%",
      display: "inline-flex", alignItems: "center", justifyContent: "center",
      background: "var(--ink)", color: "#fff",
      fontSize: 10, fontWeight: 600,
    }}>{label}</span>
    <span>{text}</span>
  </div>
);

/* ---------- FEATURES GRID ---------- */
const Features = () => {
  const compact = useMedia("(max-width: 760px)");
  const medium = useMedia("(max-width: 1020px)");
  const items = [
    {
      icon: "box", tag: "ISOLATION",
      title: "Full macOS guest, fully isolated",
      body: "Keep the agent's desktop, files, credentials, and browser state separate from your everyday Mac. Close the window — the sandbox keeps running.",
      big: true,
    },
    {
      icon: "bolt", tag: "QUICK START",
      title: "Ready-to-use images",
      body: "Pick a curated image. First sandbox launches in seconds; pull progress is visible per layer.",
    },
    {
      icon: "terminal", tag: "EMBEDDED",
      title: "Run commands in-app",
      body: "Open a terminal bound to a workload. Logs, exit codes, and diagnostic paths stay attached.",
    },
    {
      icon: "layers", tag: "RECOVERABLE",
      title: "Throw it away",
      body: "Start, stop, inspect, remove. Experiments live in sandbox-scoped log paths until you delete them.",
    },
    {
      icon: "chip", tag: "APPLE SILICON",
      title: "Built on Apple's container stack",
      body: "Wraps apple/container + apple/containerization. macOS 26 runtime target, native virtualization.",
    },
    {
      icon: "shield", tag: "SIGNED",
      title: "Signed & notarized releases",
      body: "Every semver tag builds a notarized DMG on macOS 26 via GitHub Actions. No surprise binaries.",
    },
  ];
  return (
    <Section id="features" eyebrow="02 · What's in the box">
      <div style={{
        display: "flex", justifyContent: "space-between",
        alignItems: "flex-end", gap: 24, marginBottom: 48, flexWrap: "wrap",
      }}>
        <h2 style={{
          fontSize: "clamp(40px, 5vw, 64px)", fontWeight: 500,
          letterSpacing: "-0.03em", lineHeight: 1.0, margin: 0,
          maxWidth: 720, textWrap: "balance",
        }}>
          One visual app for every{" "}
          <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 }}>
            throwaway
          </span>{" "}
          Mac you'll ever need.
        </h2>
        <p style={{ color: "var(--ink-3)", fontSize: 15, maxWidth: 360, margin: 0, lineHeight: 1.5 }}>
          Designed for the new breed of computer-using agents — and for the humans who want their main Mac left alone.
        </p>
      </div>

      <div style={{
        display: "grid",
        gridTemplateColumns: compact ? "1fr" : medium ? "repeat(2, 1fr)" : "repeat(6, 1fr)",
        gridAutoRows: "minmax(220px, auto)",
        gap: 0,
        border: "1px solid var(--line)",
        borderRadius: 14, overflow: "hidden",
        background: "var(--surface)",
      }}>
        {items.map((it, i) => (
          <FeatureCell key={i} {...it} index={i}/>
        ))}
      </div>
    </Section>
  );
};

const FeatureCell = ({ icon, tag, title, body, big, index }) => {
  const compact = useMedia("(max-width: 760px)");
  const medium = useMedia("(max-width: 1020px)");
  // Explicit layout: item 0 big (span 3 rows 2?). Simpler: alternating sizes
  const layouts = [
    { gridColumn: "span 3", gridRow: "span 2" }, // big left
    { gridColumn: "span 3" },
    { gridColumn: "span 3" },
    { gridColumn: "span 2" },
    { gridColumn: "span 2" },
    { gridColumn: "span 2" },
  ];
  const layout = compact
    ? { gridColumn: "span 1", gridRow: "span 1" }
    : medium
      ? { gridColumn: big ? "span 2" : "span 1", gridRow: "span 1" }
      : layouts[index] || {};
  return (
    <div style={{
      ...layout,
      padding: 28,
      borderLeft: "1px solid var(--line)",
      borderTop: "1px solid var(--line)",
      marginLeft: -1, marginTop: -1,
      display: "flex", flexDirection: "column", gap: 14,
      position: "relative",
    }}>
      <div style={{
        fontFamily: "var(--font-mono)", fontSize: 11, letterSpacing: 1.2,
        color: "var(--ink-4)", display: "flex", alignItems: "center", gap: 8,
      }}>
        <span style={{
          width: 28, height: 28, borderRadius: 7,
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          background: big ? "var(--accent)" : "var(--bg-2)",
          color: big ? "#fff" : "var(--ink-2)",
        }}>
          <Icon name={icon} size={15}/>
        </span>
        <span>{tag}</span>
      </div>
      <h3 style={{
        fontSize: big ? 30 : 20, fontWeight: 500, margin: 0,
        letterSpacing: "-0.015em", lineHeight: 1.15,
        maxWidth: big ? 480 : "none",
      }}>{title}</h3>
      <p style={{
        color: "var(--ink-3)", fontSize: big ? 15 : 14,
        lineHeight: 1.55, margin: 0, maxWidth: 480,
      }}>{body}</p>
      {big && <FeatureIllustration/>}
    </div>
  );
};

const FeatureIllustration = () => (
  <div style={{
    marginTop: "auto", padding: 20,
    background: "var(--bg)",
    border: "1px dashed var(--line-2)",
    borderRadius: 10,
    display: "flex", gap: 14, alignItems: "center",
  }}>
    <div style={{
      width: 46, height: 46, borderRadius: 10,
      background: "var(--ink)",
      display: "flex", alignItems: "center", justifyContent: "center",
    }}>
      <Icon name="box" size={20} stroke={1.4} style={{ color: "#fff" }}/>
    </div>
    <div style={{ flex: 1 }}>
      <div style={{ fontSize: 13, fontWeight: 500, marginBottom: 3 }}>openbox-dev-agent</div>
      <div style={{ fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-4)" }}>
        ghcr.io/jianliang00/macos-dev-agent:26.3
      </div>
    </div>
    <div style={{ display: "flex", flexDirection: "column", gap: 6, alignItems: "flex-end" }}>
      <Pill tone="good" size="xs">● RUNNING</Pill>
      <span style={{ fontFamily: "var(--font-mono)", fontSize: 10.5, color: "var(--ink-4)" }}>
        up 14m · 4 vCPU / 8GB
      </span>
    </div>
  </div>
);

/* ---------- FLOW — interactive sandbox lifecycle ---------- */
const Flow = () => {
  const [state, setState] = React.useState("idle"); // idle -> creating -> pulling -> running -> stopped
  const compact = useMedia("(max-width: 760px)");
  const states = [
    { id: "idle",     label: "Idle",      color: "var(--ink-4)",   note: "No sandbox yet." },
    { id: "creating", label: "Creating",  color: "var(--warn)",    note: "Allocating guest, provisioning rootfs." },
    { id: "pulling",  label: "Pulling",   color: "var(--accent)",  note: "Fetching OCI layers from ghcr.io." },
    { id: "running",  label: "Running",   color: "var(--good)",    note: "Desktop GUI ready; commands accepted." },
    { id: "stopped",  label: "Stopped",   color: "var(--ink-3)",   note: "Snapshot preserved; logs retained." },
  ];
  const idx = states.findIndex(s => s.id === state);

  React.useEffect(() => {
    if (state === "running" || state === "stopped" || state === "idle") return;
    const t = setTimeout(() => {
      if (state === "creating") setState("pulling");
      else if (state === "pulling") setState("running");
    }, 1400);
    return () => clearTimeout(t);
  }, [state]);

  return (
    <Section id="lifecycle" eyebrow="03 · Lifecycle">
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1.1fr 1fr", gap: compact ? 32 : 48, alignItems: "center" }}>
        <div>
          <h2 style={{
            fontSize: "clamp(36px, 4.5vw, 56px)", fontWeight: 500,
            letterSpacing: "-0.025em", lineHeight: 1.05, margin: "0 0 20px 0",
            textWrap: "balance",
          }}>
            From click to running desktop in five states.
          </h2>
          <p style={{ color: "var(--ink-3)", fontSize: 16, lineHeight: 1.55, margin: "0 0 28px 0", maxWidth: 480 }}>
            OpenBox exposes the sandbox state machine as first-class UI. Every transition is visible, recoverable, and annotated with diagnostics.
          </p>

          {/* controls */}
          <div style={{ display: "flex", gap: 10, marginBottom: 20, flexWrap: "wrap" }}>
            <Btn variant="accent" size="sm" icon="plus" onClick={() => setState("creating")}>New sandbox</Btn>
            <Btn variant="ghost" size="sm" icon={state === "running" ? "stop" : "play"} onClick={() => setState(state === "running" ? "stopped" : "running")} disabled={state === "creating" || state === "pulling"}>
              {state === "running" ? "Stop" : "Start"}
            </Btn>
            <Btn variant="ghost" size="sm" onClick={() => setState("idle")}>Reset</Btn>
          </div>

          {/* state list */}
          <div style={{ display: "flex", flexDirection: "column", gap: 0 }}>
            {states.map((s, i) => {
              const active = s.id === state;
              const past = i < idx;
              return (
                <div key={s.id} style={{
                  display: "flex", gap: 14, alignItems: "center",
                  padding: "10px 0",
                  borderTop: i === 0 ? "1px solid var(--line)" : "none",
                  borderBottom: "1px solid var(--line)",
                  opacity: active ? 1 : 0.55,
                }}>
                  <span style={{
                    fontFamily: "var(--font-mono)", fontSize: 10.5, color: "var(--ink-4)", width: 22,
                  }}>0{i+1}</span>
                  <span style={{
                    width: 10, height: 10, borderRadius: "50%",
                    background: active ? s.color : past ? "var(--ink-3)" : "var(--line-2)",
                    boxShadow: active ? `0 0 0 4px color-mix(in oklch, ${s.color} 20%, transparent)` : "none",
                    transition: "all 200ms",
                  }}/>
                  <span style={{ fontSize: 14, fontWeight: active ? 500 : 400, width: 90 }}>{s.label}</span>
                  <span style={{ fontSize: 13, color: "var(--ink-3)", fontFamily: "var(--font-mono)", flex: 1 }}>{s.note}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* right: sandbox card preview */}
        <SandboxCard state={state}/>
      </div>
    </Section>
  );
};

const SandboxCard = ({ state }) => {
  const compact = useMedia("(max-width: 760px)");
  const map = {
    idle:     { pill: ["Empty", "var(--ink-3)", "var(--bg-2)"],  progress: 0,   body: "Click New sandbox ↑" },
    creating: { pill: ["Creating", "var(--warn)", "oklch(0.95 0.04 60)"], progress: 15, body: "Allocating virtualization device…" },
    pulling:  { pill: ["Pulling", "var(--accent)", "var(--accent-bg)"], progress: 62, body: "layer 4/6 · 148 MB / 240 MB" },
    running:  { pill: ["Running", "var(--good)", "var(--good-bg)"], progress: 100, body: "Desktop GUI ready." },
    stopped:  { pill: ["Stopped", "var(--ink-3)", "var(--bg-2)"],  progress: 0,   body: "Snapshot saved." },
  };
  const m = map[state];

  return (
    <MacWindow title="OpenBox — openbox-sandbox-376036f9" style={{ borderRadius: 12 }}>
      <div style={{ padding: 24, background: "#fdfcf9" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
          <div style={{
            width: 44, height: 44, borderRadius: 10,
            background: "var(--ink)", color: "#fff",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name="box" size={20}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 600 }}>OpenBox Sandbox</div>
            <div style={{ fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-4)" }}>
              openbox-openbox-sandbox-376036f9
            </div>
          </div>
          <span style={{
            display: "inline-flex", alignItems: "center", gap: 6,
            padding: "4px 10px", borderRadius: 999,
            background: m.pill[2], color: m.pill[1],
            border: `1px solid color-mix(in oklch, ${m.pill[1]} 30%, transparent)`,
            fontSize: 11.5, fontWeight: 500,
          }}>
            <span style={{ width: 6, height: 6, borderRadius: "50%", background: m.pill[1] }}/>
            {m.pill[0]}
          </span>
        </div>

        {/* progress */}
        <div style={{
          height: 6, background: "var(--bg-2)", borderRadius: 6,
          overflow: "hidden", marginBottom: 10,
        }}>
          <div style={{
            width: `${m.progress}%`, height: "100%",
            background: state === "running" ? "var(--good)" : state === "pulling" ? "var(--accent)" : "var(--warn)",
            transition: "width 700ms ease, background 300ms",
          }}/>
        </div>
        <div style={{ fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-3)", marginBottom: 20 }}>
          {m.body}
        </div>

        {/* spec grid */}
        <div style={{
          display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 1fr",
          gap: 0, border: "1px solid var(--line)", borderRadius: 8,
          fontSize: 12.5, background: "var(--surface)",
        }}>
          {[
            ["OCI Image", "ghcr.io/jianliang00/\nmacos-dev-agent:26.3", true],
            ["Runtime", "container-runtime-macos"],
            ["Platform", "darwin/arm64"],
            ["Resources", "4 vCPU · 8GB RAM"],
            ["Desktop GUI", state === "running" ? "Enabled ✓" : "Enabled"],
            ["Workspace", "Not mounted"],
          ].map(([k, v, mono], i) => (
            <div key={k} style={{
              padding: "10px 14px",
              borderTop: compact ? (i === 0 ? "none" : "1px solid var(--line)") : i >= 2 ? "1px solid var(--line)" : "none",
              borderLeft: !compact && i % 2 === 1 ? "1px solid var(--line)" : "none",
            }}>
              <div style={{ fontFamily: "var(--font-mono)", fontSize: 10, letterSpacing: 1.2, color: "var(--ink-4)", marginBottom: 3 }}>
                {k.toUpperCase()}
              </div>
              <div style={{
                fontFamily: mono ? "var(--font-mono)" : "var(--font-body)",
                fontSize: mono ? 11.5 : 12.5,
                color: mono ? "var(--accent)" : "var(--ink-2)",
                whiteSpace: mono ? "pre" : "normal",
                lineHeight: 1.3,
              }}>{v}</div>
            </div>
          ))}
        </div>

        {/* actions */}
        <div style={{ display: "flex", gap: 8, marginTop: 16, flexWrap: "wrap" }}>
          <Btn variant="soft" size="sm" icon="terminal" disabled={state !== "running"}>Run Command</Btn>
          <Btn variant={state === "running" ? "soft" : "accent"} size="sm" icon={state === "running" ? "stop" : "play"}>
            {state === "running" ? "Stop Sandbox" : "Start Sandbox"}
          </Btn>
          <div style={{ flex: 1 }}/>
          <Btn variant="ghost" size="sm">Remove</Btn>
        </div>
      </div>
    </MacWindow>
  );
};

/* ---------- TERMINAL DEMO ---------- */
const TerminalDemo = () => {
  const compact = useMedia("(max-width: 760px)");
  const script = [
    { t: "prompt", text: "sw_vers" },
    { t: "out", text: "ProductName:    macOS\nProductVersion: 26.3\nBuildVersion:   25E205" },
    { t: "prompt", text: "whoami && hostname" },
    { t: "out", text: "sandbox\nopenbox-sandbox-376036f9" },
    { t: "prompt", text: "# run the agent — fully isolated" },
    { t: "prompt", text: "codex --dangerously-bypass-approvals 'play me a focus mix'" },
    { t: "out", text: "→ Opening Safari in the guest desktop…\n→ Searching YouTube for 'deep focus music'…\n→ Started playlist. You can close this window." },
    { t: "prompt", text: "█" },
  ];
  const [lineIdx, setLineIdx] = React.useState(0);
  const [charIdx, setCharIdx] = React.useState(0);
  const [running, setRunning] = React.useState(true);

  React.useEffect(() => {
    if (!running) return;
    if (lineIdx >= script.length) return;
    const line = script[lineIdx];
    if (charIdx < line.text.length) {
      const speed = line.t === "out" ? 8 : 38;
      const tm = setTimeout(() => setCharIdx(c => c + 1), speed + Math.random() * 20);
      return () => clearTimeout(tm);
    } else {
      const pause = line.t === "out" ? 400 : 240;
      const tm = setTimeout(() => { setLineIdx(i => i + 1); setCharIdx(0); }, pause);
      return () => clearTimeout(tm);
    }
  }, [lineIdx, charIdx, running]);

  const restart = () => { setLineIdx(0); setCharIdx(0); setRunning(true); };

  const rendered = script.slice(0, lineIdx + 1).map((line, i) => {
    const text = i === lineIdx ? line.text.slice(0, charIdx) : line.text;
    return { ...line, text, complete: i < lineIdx };
  });

  return (
    <Section id="terminal" eyebrow="04 · Embedded terminal">
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 1.3fr", gap: compact ? 32 : 48, alignItems: "center" }}>
        <div>
          <h2 style={{
            fontSize: "clamp(36px, 4.5vw, 56px)", fontWeight: 500,
            letterSpacing: "-0.025em", lineHeight: 1.05, margin: "0 0 20px 0",
          }}>
            A shell bound to the{" "}
            <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 }}>sandbox,</span>{" "}
            not your Mac.
          </h2>
          <p style={{ color: "var(--ink-3)", fontSize: 16, lineHeight: 1.55, margin: "0 0 24px 0", maxWidth: 480 }}>
            Attach an interactive terminal to any running sandbox. Workload output is captured and
            stays scoped — network, file system, and credentials remain inside the guest.
          </p>
          <ul style={{ margin: 0, padding: 0, listStyle: "none", display: "flex", flexDirection: "column", gap: 10 }}>
            {[
              ["Per-sandbox PTY","session multiplexing with tmux-like resume"],
              ["Log paths exposed","diagnostic.log · runtime.log · kernel.log"],
              ["Host firewall respected","no inbound sockets from guest to host"],
              ["Keybinds","⌘K command palette · ⌘⇧T new tab · ⌃C interrupt"],
            ].map(([k,v]) => (
              <li key={k} style={{ display: "flex", alignItems: "baseline", gap: 12, fontSize: 14, color: "var(--ink-2)" }}>
                <Icon name="check" size={14} style={{ color: "var(--accent)", flexShrink: 0 }}/>
                <span><b style={{ fontWeight: 600 }}>{k}</b> — <span style={{ color: "var(--ink-3)" }}>{v}</span></span>
              </li>
            ))}
          </ul>
          <div style={{ marginTop: 28, display: "flex", gap: 8 }}>
            <Btn variant="soft" size="sm" onClick={restart} icon="play">Replay demo</Btn>
            <Btn variant="ghost" size="sm" onClick={() => setRunning(r => !r)} icon={running ? "stop" : "play"}>
              {running ? "Pause" : "Resume"}
            </Btn>
          </div>
        </div>

        <MacWindow tone="dark" title="zsh — openbox-sandbox-376036f9" style={{ height: compact ? 380 : 460 }}>
          <div style={{
            padding: "18px 22px",
            fontFamily: "var(--font-mono)", fontSize: 13,
            color: "#e7e5de", height: "100%",
            overflowY: "auto", lineHeight: 1.5,
            background: "#1c1b18",
          }}>
            {rendered.map((ln, i) => (
              <div key={i} style={{ whiteSpace: "pre-wrap" }}>
                {ln.t === "prompt" ? (
                  <>
                    <span style={{ color: "var(--accent)" }}>sandbox</span>
                    <span style={{ color: "#9a968a" }}> ~ </span>
                    <span style={{ color: "#f0b93f" }}>$</span>{" "}
                    <span style={{ color: ln.text.startsWith("#") ? "#7f7a6e" : "#f7f5ef" }}>
                      {ln.text}
                    </span>
                  </>
                ) : (
                  <span style={{ color: "#c3bfb3" }}>{ln.text}</span>
                )}
              </div>
            ))}
          </div>
        </MacWindow>
      </div>
    </Section>
  );
};

/* ---------- COMPATIBILITY ---------- */
const Compat = () => {
  const compact = useMedia("(max-width: 760px)");
  const rows = [
    ["Hardware",             "Apple Silicon Mac",                     "good"],
    ["Runtime OS",           "macOS 26 or later",                     "good"],
    ["Source build",         "Xcode 26 or later",                     "good"],
    ["Linux sandboxes",      "OCI · container-runtime-linux",         "good"],
    ["macOS guest sandboxes","container-runtime-macos images",        "good"],
    ["Guest desktop (macOS)","Enable at sandbox creation",            "good"],
    ["Guest desktop (Linux)","Future area",                           "warn"],
    ["Intel Macs",           "Not the current target",                "muted"],
  ];
  return (
    <Section id="compat" eyebrow="05 · Compatibility" style={{ paddingTop: 80 }}>
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 2fr", gap: compact ? 28 : 48 }}>
        <div>
          <h2 style={{
            fontSize: "clamp(32px, 4vw, 48px)", fontWeight: 500,
            letterSpacing: "-0.02em", lineHeight: 1.05, margin: "0 0 16px 0",
          }}>
            Built on the supported stack.
          </h2>
          <p style={{ color: "var(--ink-3)", fontSize: 15, lineHeight: 1.55, margin: "0 0 20px 0" }}>
            OpenBox follows the runtime requirements of Apple's container stack. Release validation
            treats <b>macOS 26 on Apple Silicon</b> as the supported target.
          </p>
          <div style={{
            padding: 16, background: "var(--bg-2)",
            border: "1px solid var(--line)", borderRadius: 10,
            fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-3)", lineHeight: 1.6,
          }}>
            <div style={{ color: "var(--ink-4)", marginBottom: 6 }}>// dependency notes</div>
            pinned: jianliang00/container<br/>
            upstream: apple/container<br/>
            lower-level: apple/containerization
          </div>
        </div>

        <div style={{
          border: "1px solid var(--line)", borderRadius: 14,
          overflow: "hidden", background: "var(--surface)",
        }}>
          {rows.map(([k, v, tone], i) => (
            <div key={k} style={{
              display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 1.5fr auto",
              padding: "16px 20px", gap: compact ? 8 : 16,
              borderTop: i === 0 ? "none" : "1px solid var(--line)",
              alignItems: "center",
              background: i % 2 === 1 ? "var(--bg)" : "transparent",
            }}>
              <span style={{ fontSize: 14, fontWeight: 500 }}>{k}</span>
              <span style={{ fontSize: 13.5, color: "var(--ink-3)", fontFamily: "var(--font-mono)" }}>{v}</span>
              <Pill tone={tone === "good" ? "good" : tone === "warn" ? "default" : "ghost"} size="xs">
                {tone === "good" ? "Supported" : tone === "warn" ? "Future" : "Not targeted"}
              </Pill>
            </div>
          ))}
        </div>
      </div>
    </Section>
  );
};

/* ---------- RELEASE / CTA ---------- */
const Release = () => {
  const compact = useMedia("(max-width: 760px)");
  return (
    <Section id="download" eyebrow="06 · Download" style={{ paddingTop: 60 }}>
      <div style={{
        position: "relative",
        background: "var(--ink)", color: "#f6f5f1",
        borderRadius: 20, padding: compact ? "42px 24px" : "72px 56px",
        overflow: "hidden",
      }}>
        {/* bg pattern */}
        <div style={{
          position: "absolute", inset: 0,
          backgroundImage: "radial-gradient(circle at 85% 20%, color-mix(in oklch, var(--accent) 40%, transparent), transparent 50%)",
          opacity: 0.7, pointerEvents: "none",
        }}/>
        <div style={{ position: "relative", display: "grid", gridTemplateColumns: compact ? "1fr" : "1.3fr 1fr", gap: compact ? 28 : 48, alignItems: "center" }}>
          <div>
            <div style={{ fontFamily: "var(--font-mono)", fontSize: 11, letterSpacing: 1.5, color: "#8a857a", marginBottom: 20 }}>
              LATEST RELEASE
            </div>
            <h2 style={{
              fontSize: "clamp(44px, 5.5vw, 72px)", fontWeight: 500,
              letterSpacing: "-0.03em", lineHeight: 1.0, margin: "0 0 24px 0",
              textWrap: "balance",
            }}>
              Ready for your first{" "}
              <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400, color: "color-mix(in oklch, var(--accent) 70%, white)" }}>
                throwaway Mac.
              </span>
            </h2>
            <p style={{ color: "#b8b3a7", fontSize: 17, lineHeight: 1.5, maxWidth: 540, margin: "0 0 36px 0" }}>
              Signed and notarized, straight from the GitHub Actions pipeline. Apache 2.0.
              Early alpha — expect rough edges and please file them.
            </p>
            <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>
              <Btn variant="accent" size="lg" icon="download" href="https://github.com/jianliang00/open-box/releases/latest">
                OpenBox-0.0.6.dmg
              </Btn>
              <Btn variant="ghost" size="lg" icon="github" href="https://github.com/jianliang00/open-box" style={{ borderColor: "#3a3731", color: "#f6f5f1" }}>
                Build from source
              </Btn>
            </div>
            <div style={{ marginTop: 24, display: "flex", gap: compact ? 10 : 20, flexWrap: "wrap", fontSize: 12.5, color: "#8a857a", fontFamily: "var(--font-mono)" }}>
              <span>sha256: f657…e4ea</span>
              <span>·</span>
              <span>macOS 26+</span>
              <span>·</span>
              <span>arm64</span>
              <span>·</span>
              <span>154.5 MB</span>
            </div>
          </div>
          <ReleaseBadge/>
        </div>
      </div>
    </Section>
  );
};

const ReleaseBadge = () => (
  <div style={{
    border: "1px solid #3a3731",
    borderRadius: 14,
    padding: 24,
    background: "color-mix(in oklch, #1c1b18 70%, transparent)",
  }}>
    <div style={{ fontFamily: "var(--font-mono)", fontSize: 11, color: "#8a857a", letterSpacing: 1.2, marginBottom: 14 }}>
      RELEASE NOTES · 0.0.6
    </div>
    {[
      ["+", "Added built-in macOS base image"],
      ["+", "Signed and notarized DMG release asset"],
      ["+", "Showcase screenshots refreshed"],
      ["·", "Full changelog links 0.0.5...0.0.6"],
      ["·", "Early alpha release for Apple Silicon Macs"],
    ].map(([m, t], i) => (
      <div key={i} style={{ display: "flex", gap: 10, padding: "7px 0", fontSize: 13, color: "#d0ccbf", borderBottom: i < 4 ? "1px solid #2c2a26" : "none" }}>
        <span style={{ fontFamily: "var(--font-mono)", width: 14, color: m === "+" ? "color-mix(in oklch, var(--accent) 70%, white)" : "#6b675e" }}>{m}</span>
        <span>{t}</span>
      </div>
    ))}
  </div>
);

/* ---------- FAQ ---------- */
const FAQ = () => {
  const compact = useMedia("(max-width: 760px)");
  const items = [
    ["Is this related to Apple in any way?",
     "No. OpenBox is an independent open-source project by @jianliang00. It wraps the open-source apple/container and apple/containerization packages, which Apple publishes on GitHub, but OpenBox itself isn't built, endorsed, or sanctioned by Apple."],
    ["What can I run inside a sandbox?",
     "Anything that runs on macOS 26 on Apple Silicon, or any Linux image that resolves to container-runtime-linux. The focus is full macOS guest sandboxes — desktop session, keyboard, pointer, graphics."],
    ["Does it work on Intel Macs?",
     "No. Apple Silicon is the current target. The underlying stack requires Apple's virtualization framework on ARM hardware."],
    ["How isolated is the guest?",
     "The guest runs in its own VM with its own file system, credentials, and browser state. Host firewall rules still apply; OpenBox never opens inbound sockets from guest to host by default."],
    ["Can I use it to run AI agents?",
     "Yes — that's the intended use case. Disposable macOS environments are a good place for computer-using agents to explore without touching your main setup."],
    ["What's the license?",
     "Apache License 2.0. Fork it, ship it, embed it. Release DMGs are signed and notarized through GitHub Actions on macOS 26 runners."],
  ];
  const [open, setOpen] = React.useState(0);
  return (
    <Section id="faq" eyebrow="07 · FAQ" style={{ paddingTop: 60 }}>
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 2fr", gap: compact ? 28 : 48 }}>
        <h2 style={{
          fontSize: "clamp(36px, 4.5vw, 56px)", fontWeight: 500,
          letterSpacing: "-0.025em", lineHeight: 1.0, margin: 0,
        }}>
          Questions, <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 }}>honestly answered.</span>
        </h2>
        <div style={{ borderTop: "1px solid var(--line)" }}>
          {items.map(([q, a], i) => (
            <div key={i} style={{ borderBottom: "1px solid var(--line)" }}>
              <button
                onClick={() => setOpen(open === i ? -1 : i)}
                aria-expanded={open === i}
                aria-controls={`faq-answer-${i}`}
                style={{
                  width: "100%", padding: compact ? "18px 0" : "22px 0",
                  display: "flex", alignItems: "center", gap: 20,
                  background: "transparent", border: "none",
                  cursor: "pointer", textAlign: "left",
                  fontFamily: "var(--font-body)", color: "var(--ink)",
                }}>
                <span style={{ fontFamily: "var(--font-mono)", fontSize: 12, color: "var(--ink-4)", width: 28 }}>
                  {String(i+1).padStart(2,"0")}
                </span>
                <span style={{ fontSize: 17, fontWeight: 500, flex: 1 }}>{q}</span>
                <Icon name="plus" size={16} style={{
                  transform: open === i ? "rotate(45deg)" : "rotate(0)",
                  transition: "transform 200ms ease",
                }}/>
              </button>
              <div id={`faq-answer-${i}`} style={{
                maxHeight: open === i ? 300 : 0, overflow: "hidden",
                transition: "max-height 260ms ease",
              }}>
                <p style={{
                  paddingLeft: compact ? 0 : 48, paddingBottom: 22, margin: 0,
                  color: "var(--ink-3)", fontSize: 15, lineHeight: 1.6, maxWidth: 680,
                }}>{a}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Section>
  );
};

/* ---------- FOOTER ---------- */
const Footer = () => {
  const compact = useMedia("(max-width: 760px)");
  const groups = [
    ["Project", [
      ["README", "https://github.com/jianliang00/open-box#readme"],
      ["Compatibility", "COMPATIBILITY.md"],
      ["License", "https://github.com/jianliang00/open-box/blob/main/LICENSE"],
    ]],
    ["Releases", [
      ["Latest DMG", "https://github.com/jianliang00/open-box/releases/latest"],
      ["Changelog", "https://github.com/jianliang00/open-box/releases/tag/0.0.6"],
      ["Actions", "https://github.com/jianliang00/open-box/actions"],
    ]],
    ["Community", [
      ["GitHub Issues", "https://github.com/jianliang00/open-box/issues"],
      ["Discussions", "https://github.com/jianliang00/open-box/discussions"],
      ["Source", "https://github.com/jianliang00/open-box"],
    ]],
  ];

  return (
    <footer style={{
      borderTop: "1px solid var(--line)",
      padding: compact ? "42px 18px 28px" : "56px 32px 32px",
      maxWidth: 1280, margin: "0 auto",
    }}>
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "2fr 1fr 1fr 1fr", gap: compact ? 28 : 48, marginBottom: 48 }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
            <Logo size={22}/>
            <span style={{ fontWeight: 600, fontSize: 15 }}>OpenBox</span>
          </div>
          <p style={{ color: "var(--ink-3)", fontSize: 13.5, lineHeight: 1.55, maxWidth: 340, margin: 0 }}>
            A desktop app for creating and managing isolated Mac environments.
            Open source — Apache 2.0 — by @jianliang00 and contributors.
          </p>
        </div>
        {groups.map(([title, links]) => (
          <div key={title}>
            <div style={{ fontFamily: "var(--font-mono)", fontSize: 11, letterSpacing: 1.2, color: "var(--ink-4)", marginBottom: 14 }}>
              {title.toUpperCase()}
            </div>
            <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: 8 }}>
              {links.map(([label, href]) => <li key={label}><a href={href} style={{ color: "var(--ink-2)", fontSize: 14 }}>{label}</a></li>)}
            </ul>
          </div>
        ))}
      </div>
      <div style={{
        paddingTop: 24, borderTop: "1px solid var(--line)",
        display: "flex", justifyContent: "space-between", gap: 12,
        flexDirection: compact ? "column" : "row",
        fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-4)",
      }}>
        <span>© 2026 OpenBox contributors · Apache 2.0</span>
        <span>Not affiliated with Apple Inc. · 0.0.6-alpha</span>
      </div>
    </footer>
  );
};

Object.assign(window, { Nav, Hero, Features, Flow, TerminalDemo, Compat, Release, FAQ, Footer, Logo });
