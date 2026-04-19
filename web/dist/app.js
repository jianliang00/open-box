const TweaksPanel = ({ tweaks, setTweak, visible }) => {
  if (!visible) return null;
  return /* @__PURE__ */ React.createElement("div", { style: {
    position: "fixed",
    bottom: 20,
    right: 20,
    zIndex: 100,
    width: 280,
    padding: 18,
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 12,
    boxShadow: "0 20px 50px rgba(0,0,0,0.12)",
    fontFamily: "var(--font-body)",
    fontSize: 13
  } }, /* @__PURE__ */ React.createElement("div", { style: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 14,
    paddingBottom: 10,
    borderBottom: "1px solid var(--line)"
  } }, /* @__PURE__ */ React.createElement("span", { style: { fontWeight: 600, fontSize: 13 } }, "Tweaks"), /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-mono)", fontSize: 10.5, color: "var(--ink-4)", letterSpacing: 1 } }, "LIVE")), /* @__PURE__ */ React.createElement("div", { style: { marginBottom: 14 } }, /* @__PURE__ */ React.createElement("label", { style: { display: "block", marginBottom: 6, fontSize: 12, color: "var(--ink-3)" } }, "Accent hue \u2014 ", /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-mono)" } }, tweaks.accent_hue, "\xB0")), /* @__PURE__ */ React.createElement(
    "input",
    {
      type: "range",
      min: "0",
      max: "360",
      step: "1",
      value: tweaks.accent_hue,
      onChange: (e) => setTweak("accent_hue", Number(e.target.value)),
      style: { width: "100%" }
    }
  ), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", gap: 6, marginTop: 6 } }, [220, 240, 170, 20, 340, 290].map((h) => /* @__PURE__ */ React.createElement(
    "button",
    {
      key: h,
      onClick: () => setTweak("accent_hue", h),
      style: {
        width: 28,
        height: 20,
        borderRadius: 4,
        cursor: "pointer",
        background: `oklch(0.62 0.16 ${h})`,
        border: tweaks.accent_hue === h ? "2px solid var(--ink)" : "1px solid var(--line)"
      }
    }
  )))), /* @__PURE__ */ React.createElement("div", { style: { marginBottom: 14 } }, /* @__PURE__ */ React.createElement("label", { style: { display: "block", marginBottom: 8, fontSize: 12, color: "var(--ink-3)" } }, "Display style"), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", gap: 6 } }, [[true, "Serif italic"], [false, "Sans only"]].map(([v, lbl]) => /* @__PURE__ */ React.createElement(
    "button",
    {
      key: String(v),
      onClick: () => setTweak("display_serif", v),
      style: {
        flex: 1,
        padding: "7px 10px",
        fontSize: 12,
        cursor: "pointer",
        background: tweaks.display_serif === v ? "var(--ink)" : "transparent",
        color: tweaks.display_serif === v ? "#fff" : "var(--ink-2)",
        border: "1px solid " + (tweaks.display_serif === v ? "var(--ink)" : "var(--line-2)"),
        borderRadius: 6
      }
    },
    lbl
  )))), /* @__PURE__ */ React.createElement("div", null, /* @__PURE__ */ React.createElement("label", { style: { display: "block", marginBottom: 8, fontSize: 12, color: "var(--ink-3)" } }, "Density"), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", gap: 6 } }, ["compact", "comfortable", "airy"].map((d) => /* @__PURE__ */ React.createElement(
    "button",
    {
      key: d,
      onClick: () => setTweak("density", d),
      style: {
        flex: 1,
        padding: "7px 10px",
        fontSize: 12,
        cursor: "pointer",
        textTransform: "capitalize",
        background: tweaks.density === d ? "var(--ink)" : "transparent",
        color: tweaks.density === d ? "#fff" : "var(--ink-2)",
        border: "1px solid " + (tweaks.density === d ? "var(--ink)" : "var(--line-2)"),
        borderRadius: 6
      }
    },
    d
  )))));
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
  const toggleTheme = () => setTheme((value) => value === "dark" ? "light" : "dark");
  const toggleLang = () => setLang((value) => value === "zh" ? "en" : "zh");
  React.useEffect(() => {
    const onMsg = (e) => {
      var _a, _b;
      if (((_a = e.data) == null ? void 0 : _a.type) === "__activate_edit_mode") setEditMode(true);
      if (((_b = e.data) == null ? void 0 : _b.type) === "__deactivate_edit_mode") setEditMode(false);
    };
    window.addEventListener("message", onMsg);
    window.parent.postMessage({ type: "__edit_mode_available" }, "*");
    return () => window.removeEventListener("message", onMsg);
  }, []);
  React.useEffect(() => {
    const hue = tweaks.accent_hue;
    document.documentElement.style.setProperty("--accent", theme === "dark" ? `oklch(0.70 0.16 ${hue})` : `oklch(0.62 0.16 ${hue})`);
    document.documentElement.style.setProperty("--accent-bg", theme === "dark" ? `oklch(0.24 0.05 ${hue})` : `oklch(0.95 0.03 ${hue})`);
  }, [tweaks.accent_hue, theme]);
  React.useEffect(() => {
    document.documentElement.dataset.serif = tweaks.display_serif ? "on" : "off";
    if (!tweaks.display_serif) {
      const style = document.getElementById("serif-override") || (() => {
        const s = document.createElement("style");
        s.id = "serif-override";
        document.head.appendChild(s);
        return s;
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
    var _a;
    document.documentElement.dataset.theme = theme;
    const themeColor = theme === "dark" ? "#11120f" : "#f6f5f1";
    (_a = document.querySelector('meta[name="theme-color"]')) == null ? void 0 : _a.setAttribute("content", themeColor);
    try {
      localStorage.setItem("openbox-theme", theme);
    } catch (_) {
    }
  }, [theme]);
  React.useEffect(() => {
    var _a, _b, _c, _d, _e;
    window.__OPENBOX_LANG__ = lang;
    document.documentElement.lang = lang === "zh" ? "zh-CN" : "en";
    const title = lang === "zh" ? "OpenBox \u2014 \u9694\u79BB Mac \u6C99\u76D2\uFF0C\u4E00\u4E2A\u53EF\u89C6\u5316\u5E94\u7528" : "OpenBox \u2014 Isolated Mac sandboxes, one visual app";
    const description = lang === "zh" ? "OpenBox \u7528\u4E8E\u5728 Apple Silicon \u4E0A\u521B\u5EFA\u9694\u79BB\u7684 macOS \u6C99\u76D2\uFF0C\u652F\u6301\u5BA2\u4F53\u684C\u9762\u3001\u547D\u4EE4\u6267\u884C\u548C\u4E00\u6B21\u6027\u73AF\u5883\u3002" : "OpenBox creates isolated macOS sandboxes on Apple Silicon, with guest desktop sessions, command execution, and disposable environments for agents and app tests.";
    document.title = title;
    (_a = document.querySelector('meta[name="description"]')) == null ? void 0 : _a.setAttribute("content", description);
    (_b = document.querySelector('meta[property="og:title"]')) == null ? void 0 : _b.setAttribute("content", title);
    (_c = document.querySelector('meta[property="og:description"]')) == null ? void 0 : _c.setAttribute("content", description);
    (_d = document.querySelector('meta[name="twitter:title"]')) == null ? void 0 : _d.setAttribute("content", title);
    (_e = document.querySelector('meta[name="twitter:description"]')) == null ? void 0 : _e.setAttribute("content", description);
    try {
      localStorage.setItem("openbox-lang", lang);
    } catch (_) {
    }
  }, [lang]);
  document.documentElement.dataset.theme = theme;
  window.__OPENBOX_LANG__ = lang;
  return /* @__PURE__ */ React.createElement(React.Fragment, null, /* @__PURE__ */ React.createElement(Nav, { theme, lang, onToggleTheme: toggleTheme, onToggleLang: toggleLang }), /* @__PURE__ */ React.createElement(Hero, null), /* @__PURE__ */ React.createElement(Features, null), /* @__PURE__ */ React.createElement(Flow, null), /* @__PURE__ */ React.createElement(TerminalDemo, null), /* @__PURE__ */ React.createElement(Compat, null), /* @__PURE__ */ React.createElement(FAQ, null), /* @__PURE__ */ React.createElement(Footer, null), /* @__PURE__ */ React.createElement(TweaksPanel, { tweaks, setTweak, visible: editMode }));
};
ReactDOM.createRoot(document.getElementById("root")).render(/* @__PURE__ */ React.createElement(App, null));
