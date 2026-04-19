/* App entry — mounts all sections + tweaks panel */

const TweaksPanel = ({ tweaks, setTweak, visible }) => {
  if (!visible) return null;
  return (
    <div style={{
      position: "fixed", bottom: 20, right: 20, zIndex: 100,
      width: 280, padding: 18,
      background: "var(--surface)",
      border: "1px solid var(--line)",
      borderRadius: 12,
      boxShadow: "0 20px 50px rgba(0,0,0,0.12)",
      fontFamily: "var(--font-body)", fontSize: 13,
    }}>
      <div style={{
        display: "flex", justifyContent: "space-between", alignItems: "center",
        marginBottom: 14, paddingBottom: 10, borderBottom: "1px solid var(--line)",
      }}>
        <span style={{ fontWeight: 600, fontSize: 13 }}>Tweaks</span>
        <span style={{ fontFamily: "var(--font-mono)", fontSize: 10.5, color: "var(--ink-4)", letterSpacing: 1 }}>LIVE</span>
      </div>

      <div style={{ marginBottom: 14 }}>
        <label style={{ display: "block", marginBottom: 6, fontSize: 12, color: "var(--ink-3)" }}>
          Accent hue — <span style={{ fontFamily: "var(--font-mono)" }}>{tweaks.accent_hue}°</span>
        </label>
        <input
          type="range" min="0" max="360" step="1"
          value={tweaks.accent_hue}
          onChange={e => setTweak("accent_hue", Number(e.target.value))}
          style={{ width: "100%" }}
        />
        <div style={{ display: "flex", gap: 6, marginTop: 6 }}>
          {[220, 240, 170, 20, 340, 290].map(h => (
            <button key={h} onClick={() => setTweak("accent_hue", h)}
              style={{
                width: 28, height: 20, borderRadius: 4, cursor: "pointer",
                background: `oklch(0.62 0.16 ${h})`,
                border: tweaks.accent_hue === h ? "2px solid var(--ink)" : "1px solid var(--line)",
              }}/>
          ))}
        </div>
      </div>

      <div style={{ marginBottom: 14 }}>
        <label style={{ display: "block", marginBottom: 8, fontSize: 12, color: "var(--ink-3)" }}>Display style</label>
        <div style={{ display: "flex", gap: 6 }}>
          {[[true, "Serif italic"], [false, "Sans only"]].map(([v, lbl]) => (
            <button key={String(v)} onClick={() => setTweak("display_serif", v)}
              style={{
                flex: 1, padding: "7px 10px", fontSize: 12, cursor: "pointer",
                background: tweaks.display_serif === v ? "var(--ink)" : "transparent",
                color: tweaks.display_serif === v ? "#fff" : "var(--ink-2)",
                border: "1px solid " + (tweaks.display_serif === v ? "var(--ink)" : "var(--line-2)"),
                borderRadius: 6,
              }}>{lbl}</button>
          ))}
        </div>
      </div>

      <div>
        <label style={{ display: "block", marginBottom: 8, fontSize: 12, color: "var(--ink-3)" }}>Density</label>
        <div style={{ display: "flex", gap: 6 }}>
          {["compact", "comfortable", "airy"].map(d => (
            <button key={d} onClick={() => setTweak("density", d)}
              style={{
                flex: 1, padding: "7px 10px", fontSize: 12, cursor: "pointer", textTransform: "capitalize",
                background: tweaks.density === d ? "var(--ink)" : "transparent",
                color: tweaks.density === d ? "#fff" : "var(--ink-2)",
                border: "1px solid " + (tweaks.density === d ? "var(--ink)" : "var(--line-2)"),
                borderRadius: 6,
              }}>{d}</button>
          ))}
        </div>
      </div>
    </div>
  );
};

const App = () => {
  const [tweaks, setTweaks] = React.useState(window.__TWEAKS__);
  const [editMode, setEditMode] = React.useState(false);
  const [theme, setTheme] = React.useState(() => {
    try {
      return localStorage.getItem("openbox-theme") || document.documentElement.dataset.theme || "light";
    } catch (_) {
      return document.documentElement.dataset.theme || "light";
    }
  });
  const [lang, setLang] = React.useState(() => {
    try {
      return localStorage.getItem("openbox-lang") || window.__OPENBOX_LANG__ || "en";
    } catch (_) {
      return window.__OPENBOX_LANG__ || "en";
    }
  });

  const setTweak = (k, v) => {
    const next = { ...tweaks, [k]: v };
    setTweaks(next);
    window.parent.postMessage({ type: "__edit_mode_set_keys", edits: { [k]: v } }, "*");
  };
  const toggleTheme = () => setTheme(value => value === "dark" ? "light" : "dark");
  const toggleLang = () => setLang(value => value === "zh" ? "en" : "zh");

  React.useEffect(() => {
    const onMsg = (e) => {
      if (e.data?.type === "__activate_edit_mode") setEditMode(true);
      if (e.data?.type === "__deactivate_edit_mode") setEditMode(false);
    };
    window.addEventListener("message", onMsg);
    window.parent.postMessage({ type: "__edit_mode_available" }, "*");
    return () => window.removeEventListener("message", onMsg);
  }, []);

  // apply tweaks
  React.useEffect(() => {
    const hue = tweaks.accent_hue;
    document.documentElement.style.setProperty("--accent", theme === "dark" ? `oklch(0.70 0.16 ${hue})` : `oklch(0.62 0.16 ${hue})`);
    document.documentElement.style.setProperty("--accent-bg", theme === "dark" ? `oklch(0.24 0.05 ${hue})` : `oklch(0.95 0.03 ${hue})`);
  }, [tweaks.accent_hue, theme]);

  React.useEffect(() => {
    // Toggle serif use by adding a class
    document.documentElement.dataset.serif = tweaks.display_serif ? "on" : "off";
    if (!tweaks.display_serif) {
      const style = document.getElementById("serif-override") || (() => {
        const s = document.createElement("style"); s.id = "serif-override";
        document.head.appendChild(s); return s;
      })();
      style.textContent = `[data-serif="off"] span[style*="var(--font-serif)"] { font-family: var(--font-body) !important; font-style: normal !important; }`;
    } else {
      const s = document.getElementById("serif-override");
      if (s) s.textContent = "";
    }
  }, [tweaks.display_serif]);

  React.useEffect(() => {
    const d = tweaks.density;
    const scale = d === "compact" ? 0.9 : d === "airy" ? 1.15 : 1;
    document.documentElement.style.setProperty("--density-scale", scale);
  }, [tweaks.density]);

  React.useEffect(() => {
    document.documentElement.dataset.theme = theme;
    const themeColor = theme === "dark" ? "#11120f" : "#f6f5f1";
    document.querySelector('meta[name="theme-color"]')?.setAttribute("content", themeColor);
    try { localStorage.setItem("openbox-theme", theme); } catch (_) {}
  }, [theme]);

  React.useEffect(() => {
    window.__OPENBOX_LANG__ = lang;
    document.documentElement.lang = lang === "zh" ? "zh-CN" : "en";
    const title = lang === "zh"
      ? "OpenBox — 隔离 Mac 沙盒，一个可视化应用"
      : "OpenBox — Isolated Mac sandboxes, one visual app";
    const description = lang === "zh"
      ? "OpenBox 用于在 Apple Silicon 上创建隔离的 macOS 沙盒，支持客体桌面、命令执行和一次性环境。"
      : "OpenBox creates isolated macOS sandboxes on Apple Silicon, with guest desktop sessions, command execution, and disposable environments for agents and app tests.";
    document.title = title;
    document.querySelector('meta[name="description"]')?.setAttribute("content", description);
    document.querySelector('meta[property="og:title"]')?.setAttribute("content", title);
    document.querySelector('meta[property="og:description"]')?.setAttribute("content", description);
    document.querySelector('meta[name="twitter:title"]')?.setAttribute("content", title);
    document.querySelector('meta[name="twitter:description"]')?.setAttribute("content", description);
    try { localStorage.setItem("openbox-lang", lang); } catch (_) {}
  }, [lang]);

  document.documentElement.dataset.theme = theme;
  window.__OPENBOX_LANG__ = lang;

  return (
    <>
      <Nav theme={theme} lang={lang} onToggleTheme={toggleTheme} onToggleLang={toggleLang}/>
      <Hero/>
      <Features/>
      <Flow/>
      <TerminalDemo/>
      <Compat/>
      <FAQ/>
      <Footer/>
      <TweaksPanel tweaks={tweaks} setTweak={setTweak} visible={editMode}/>
    </>
  );
};

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
