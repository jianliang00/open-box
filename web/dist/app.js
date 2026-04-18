/* App entry — mounts all sections + tweaks panel */

const TweaksPanel = ({
  tweaks,
  setTweak,
  visible
}) => {
  if (!visible) return null;
  return /*#__PURE__*/React.createElement("div", {
    style: {
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
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 14,
      paddingBottom: 10,
      borderBottom: "1px solid var(--line)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 600,
      fontSize: 13
    }
  }, "Tweaks"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-mono)",
      fontSize: 10.5,
      color: "var(--ink-4)",
      letterSpacing: 1
    }
  }, "LIVE")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement("label", {
    style: {
      display: "block",
      marginBottom: 6,
      fontSize: 12,
      color: "var(--ink-3)"
    }
  }, "Accent hue \u2014 ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-mono)"
    }
  }, tweaks.accent_hue, "\xB0")), /*#__PURE__*/React.createElement("input", {
    type: "range",
    min: "0",
    max: "360",
    step: "1",
    value: tweaks.accent_hue,
    onChange: e => setTweak("accent_hue", Number(e.target.value)),
    style: {
      width: "100%"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 6,
      marginTop: 6
    }
  }, [220, 240, 170, 20, 340, 290].map(h => /*#__PURE__*/React.createElement("button", {
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
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement("label", {
    style: {
      display: "block",
      marginBottom: 8,
      fontSize: 12,
      color: "var(--ink-3)"
    }
  }, "Display style"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 6
    }
  }, [[true, "Serif italic"], [false, "Sans only"]].map(([v, lbl]) => /*#__PURE__*/React.createElement("button", {
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
  }, lbl)))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("label", {
    style: {
      display: "block",
      marginBottom: 8,
      fontSize: 12,
      color: "var(--ink-3)"
    }
  }, "Density"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 6
    }
  }, ["compact", "comfortable", "airy"].map(d => /*#__PURE__*/React.createElement("button", {
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
  }, d)))));
};
const App = () => {
  const [tweaks, setTweaks] = React.useState(window.__TWEAKS__);
  const [editMode, setEditMode] = React.useState(false);
  const setTweak = (k, v) => {
    const next = {
      ...tweaks,
      [k]: v
    };
    setTweaks(next);
    window.parent.postMessage({
      type: "__edit_mode_set_keys",
      edits: {
        [k]: v
      }
    }, "*");
  };
  React.useEffect(() => {
    const onMsg = e => {
      if (e.data?.type === "__activate_edit_mode") setEditMode(true);
      if (e.data?.type === "__deactivate_edit_mode") setEditMode(false);
    };
    window.addEventListener("message", onMsg);
    window.parent.postMessage({
      type: "__edit_mode_available"
    }, "*");
    return () => window.removeEventListener("message", onMsg);
  }, []);

  // apply tweaks
  React.useEffect(() => {
    const hue = tweaks.accent_hue;
    document.documentElement.style.setProperty("--accent", `oklch(0.62 0.16 ${hue})`);
    document.documentElement.style.setProperty("--accent-bg", `oklch(0.95 0.03 ${hue})`);
  }, [tweaks.accent_hue]);
  React.useEffect(() => {
    // Toggle serif use by adding a class
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
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Nav, null), /*#__PURE__*/React.createElement(Hero, null), /*#__PURE__*/React.createElement(Features, null), /*#__PURE__*/React.createElement(Flow, null), /*#__PURE__*/React.createElement(TerminalDemo, null), /*#__PURE__*/React.createElement(Compat, null), /*#__PURE__*/React.createElement(Release, null), /*#__PURE__*/React.createElement(FAQ, null), /*#__PURE__*/React.createElement(Footer, null), /*#__PURE__*/React.createElement(TweaksPanel, {
    tweaks: tweaks,
    setTweak: setTweak,
    visible: editMode
  }));
};
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));