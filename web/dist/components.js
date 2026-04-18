function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Shared primitives. Exported on window at bottom. */

const useMedia = query => {
  const getMatches = () => window.matchMedia(query).matches;
  const [matches, setMatches] = React.useState(getMatches);
  React.useEffect(() => {
    const media = window.matchMedia(query);
    const onChange = () => setMatches(media.matches);
    onChange();
    if (media.addEventListener) {
      media.addEventListener("change", onChange);
      return () => media.removeEventListener("change", onChange);
    }
    media.addListener(onChange);
    return () => media.removeListener(onChange);
  }, [query]);
  return matches;
};

/* ---------- tiny icons (use inline SVG, shape-level only) ---------- */
const Icon = ({
  name,
  size = 16,
  stroke = 1.5,
  style,
  ...rest
}) => {
  const s = size;
  const common = {
    width: s,
    height: s,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: stroke,
    strokeLinecap: "round",
    strokeLinejoin: "round",
    style,
    ...rest
  };
  switch (name) {
    case "arrow-right":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M5 12h14M13 6l6 6-6 6"
      }));
    case "arrow-up-right":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M7 17 17 7M8 7h9v9"
      }));
    case "download":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M12 3v13M6 11l6 6 6-6M4 21h16"
      }));
    case "github":
      return /*#__PURE__*/React.createElement("svg", _extends({
        width: s,
        height: s,
        viewBox: "0 0 24 24",
        fill: "currentColor",
        style: style
      }, rest), /*#__PURE__*/React.createElement("path", {
        d: "M12 .5A11.5 11.5 0 0 0 .5 12c0 5.08 3.29 9.4 7.86 10.92.57.1.78-.25.78-.55v-1.94c-3.2.7-3.87-1.37-3.87-1.37-.52-1.33-1.28-1.68-1.28-1.68-1.05-.71.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.76 2.7 1.25 3.36.96.1-.75.4-1.25.73-1.54-2.55-.29-5.24-1.28-5.24-5.7 0-1.26.45-2.28 1.18-3.08-.12-.29-.51-1.46.11-3.04 0 0 .97-.31 3.18 1.18a11 11 0 0 1 5.79 0c2.21-1.49 3.18-1.18 3.18-1.18.62 1.58.23 2.75.11 3.04.73.8 1.18 1.82 1.18 3.08 0 4.43-2.69 5.4-5.25 5.69.41.36.78 1.06.78 2.14v3.17c0 .3.21.66.79.55A11.5 11.5 0 0 0 23.5 12 11.5 11.5 0 0 0 12 .5z"
      }));
    case "box":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M21 8 12 3 3 8v8l9 5 9-5V8Z"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M3.3 7.5 12 12l8.7-4.5M12 12v9"
      }));
    case "terminal":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "m4 8 4 4-4 4M11 16h8"
      }), /*#__PURE__*/React.createElement("rect", {
        x: "2",
        y: "4",
        width: "20",
        height: "16",
        rx: "2"
      }));
    case "layers":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "m12 3 9 5-9 5-9-5 9-5Z"
      }), /*#__PURE__*/React.createElement("path", {
        d: "m3 13 9 5 9-5M3 18l9 5 9-5"
      }));
    case "shield":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M12 3 4 6v6c0 5 3.5 8.5 8 9 4.5-.5 8-4 8-9V6l-8-3Z"
      }));
    case "bolt":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M13 2 3 14h7l-1 8 10-12h-7l1-8Z"
      }));
    case "play":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        fill: "currentColor",
        stroke: "none"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M7 5v14l12-7L7 5Z"
      }));
    case "stop":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        fill: "currentColor",
        stroke: "none"
      }), /*#__PURE__*/React.createElement("rect", {
        x: "6",
        y: "6",
        width: "12",
        height: "12",
        rx: "1"
      }));
    case "plus":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M12 5v14M5 12h14"
      }));
    case "check":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "m5 12 5 5 9-10"
      }));
    case "copy":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("rect", {
        x: "8",
        y: "8",
        width: "12",
        height: "12",
        rx: "2"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"
      }));
    case "folder":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7Z"
      }));
    case "chip":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("rect", {
        x: "5",
        y: "5",
        width: "14",
        height: "14",
        rx: "2"
      }), /*#__PURE__*/React.createElement("rect", {
        x: "9",
        y: "9",
        width: "6",
        height: "6"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M2 9h3M2 15h3M19 9h3M19 15h3M9 2v3M15 2v3M9 19v3M15 19v3"
      }));
    case "spark":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("path", {
        d: "M12 3v6M12 15v6M3 12h6M15 12h6"
      }));
    case "dot":
      return /*#__PURE__*/React.createElement("svg", _extends({
        width: s,
        height: s,
        viewBox: "0 0 10 10",
        style: style
      }, rest), /*#__PURE__*/React.createElement("circle", {
        cx: "5",
        cy: "5",
        r: "3",
        fill: "currentColor"
      }));
    case "dots":
      return /*#__PURE__*/React.createElement("svg", common, /*#__PURE__*/React.createElement("circle", {
        cx: "5",
        cy: "12",
        r: "1.5",
        fill: "currentColor",
        stroke: "none"
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "12",
        cy: "12",
        r: "1.5",
        fill: "currentColor",
        stroke: "none"
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "19",
        cy: "12",
        r: "1.5",
        fill: "currentColor",
        stroke: "none"
      }));
    default:
      return null;
  }
};

/* ---------- Pill / Badge ---------- */
const Pill = ({
  children,
  tone = "default",
  mono = false,
  size = "sm"
}) => {
  const tones = {
    default: {
      bg: "var(--bg-2)",
      fg: "var(--ink-2)",
      border: "var(--line)"
    },
    accent: {
      bg: "var(--accent-bg)",
      fg: "var(--accent)",
      border: "color-mix(in oklch, var(--accent) 25%, transparent)"
    },
    good: {
      bg: "var(--good-bg)",
      fg: "var(--good)",
      border: "color-mix(in oklch, var(--good) 25%, transparent)"
    },
    ink: {
      bg: "var(--ink)",
      fg: "#fff",
      border: "var(--ink)"
    },
    ghost: {
      bg: "transparent",
      fg: "var(--ink-3)",
      border: "var(--line-2)"
    }
  };
  const t = tones[tone] || tones.default;
  const padY = size === "xs" ? 2 : 3;
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      padding: `${padY}px 8px`,
      background: t.bg,
      color: t.fg,
      border: `1px solid ${t.border}`,
      borderRadius: 999,
      fontFamily: mono ? "var(--font-mono)" : "var(--font-body)",
      fontSize: size === "xs" ? 10.5 : 11.5,
      fontWeight: 500,
      letterSpacing: mono ? 0 : 0.1,
      lineHeight: 1,
      whiteSpace: "nowrap"
    }
  }, children);
};

/* ---------- Button ---------- */
const Btn = ({
  variant = "solid",
  children,
  icon,
  iconRight,
  onClick,
  href,
  size = "md",
  as = "button",
  style = {},
  disabled = false,
  ...rest
}) => {
  const sizes = {
    sm: {
      pad: "7px 12px",
      fs: 13,
      h: 32,
      gap: 6,
      ic: 14
    },
    md: {
      pad: "10px 16px",
      fs: 14,
      h: 40,
      gap: 8,
      ic: 15
    },
    lg: {
      pad: "14px 22px",
      fs: 15,
      h: 48,
      gap: 10,
      ic: 16
    }
  };
  const s = sizes[size];
  const base = {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: s.gap,
    padding: s.pad,
    height: s.h,
    fontFamily: "var(--font-body)",
    fontSize: s.fs,
    fontWeight: 500,
    letterSpacing: 0.05,
    borderRadius: 10,
    cursor: "pointer",
    textDecoration: "none",
    transition: "transform 120ms ease, background 120ms ease, box-shadow 160ms ease, border-color 120ms ease",
    whiteSpace: "nowrap",
    border: "1px solid transparent"
  };
  const variants = {
    solid: {
      background: "var(--ink)",
      color: "#fff",
      boxShadow: "0 1px 0 rgba(255,255,255,0.08) inset, 0 1px 2px rgba(0,0,0,0.1)",
      borderColor: "var(--ink)"
    },
    accent: {
      background: "var(--accent)",
      color: "#fff",
      boxShadow: "0 1px 0 rgba(255,255,255,0.2) inset, 0 2px 6px color-mix(in oklch, var(--accent) 30%, transparent)",
      borderColor: "color-mix(in oklch, var(--accent) 70%, black)"
    },
    ghost: {
      background: "transparent",
      color: "var(--ink)",
      borderColor: "var(--line-2)"
    },
    soft: {
      background: "var(--surface)",
      color: "var(--ink)",
      borderColor: "var(--line)",
      boxShadow: "0 1px 0 rgba(0,0,0,0.02)"
    },
    link: {
      background: "transparent",
      color: "var(--ink)",
      padding: 0,
      height: "auto",
      border: "none"
    }
  };
  const Tag = href ? "a" : "button";
  const disabledStyle = disabled ? {
    opacity: 0.48,
    cursor: "not-allowed"
  } : {};
  return /*#__PURE__*/React.createElement(Tag, _extends({
    href: disabled ? undefined : href,
    disabled: !href ? disabled : undefined,
    "aria-disabled": href && disabled ? "true" : undefined,
    onClick: e => {
      if (disabled) {
        e.preventDefault();
        return;
      }
      onClick?.(e);
    },
    style: {
      ...base,
      ...variants[variant],
      ...disabledStyle,
      ...style
    },
    onMouseDown: e => {
      if (!disabled) e.currentTarget.style.transform = "translateY(1px)";
    },
    onMouseUp: e => {
      if (!disabled) e.currentTarget.style.transform = "translateY(0)";
    },
    onMouseLeave: e => {
      if (!disabled) e.currentTarget.style.transform = "translateY(0)";
    }
  }, rest), icon && /*#__PURE__*/React.createElement(Icon, {
    name: icon,
    size: s.ic
  }), children, iconRight && /*#__PURE__*/React.createElement(Icon, {
    name: iconRight,
    size: s.ic
  }));
};

/* ---------- Kbd ---------- */
const Kbd = ({
  children
}) => /*#__PURE__*/React.createElement("span", {
  style: {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    minWidth: 20,
    height: 22,
    padding: "0 6px",
    fontFamily: "var(--font-mono)",
    fontSize: 11,
    color: "var(--ink-2)",
    background: "var(--surface)",
    border: "1px solid var(--line-2)",
    borderBottomWidth: 2,
    borderRadius: 5,
    lineHeight: 1
  }
}, children);

/* ---------- Mac Window Chrome ---------- */
const MacWindow = ({
  title,
  children,
  tone = "light",
  style = {},
  bodyStyle = {}
}) => {
  const isDark = tone === "dark";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      background: isDark ? "#1c1b18" : "#fdfcf9",
      borderRadius: 12,
      overflow: "hidden",
      border: `1px solid ${isDark ? "#2c2a26" : "var(--line)"}`,
      boxShadow: "0 1px 1px rgba(0,0,0,0.02), 0 10px 30px rgba(0,0,0,0.08), 0 40px 80px rgba(0,0,0,0.08)",
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10,
      padding: "10px 14px",
      background: isDark ? "#23211d" : "#f1efe8",
      borderBottom: `1px solid ${isDark ? "#2c2a26" : "var(--line)"}`,
      fontFamily: "var(--font-body)",
      fontSize: 12,
      color: isDark ? "#9a968a" : "var(--ink-3)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 6
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 11,
      height: 11,
      borderRadius: "50%",
      background: "#ef7065"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 11,
      height: 11,
      borderRadius: "50%",
      background: "#f0b93f"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 11,
      height: 11,
      borderRadius: "50%",
      background: "#57c043"
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: "center",
      fontWeight: 500,
      letterSpacing: 0.2
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 51
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: bodyStyle
  }, children));
};

/* ---------- Section container ---------- */
const Section = ({
  id,
  eyebrow,
  children,
  style = {},
  pad = [120, 32]
}) => {
  const compact = useMedia("(max-width: 760px)");
  const y = compact ? Math.max(36, Math.round(pad[0] * 0.6)) : pad[0];
  const x = compact ? 18 : pad[1];
  return /*#__PURE__*/React.createElement("section", {
    id: id,
    style: {
      padding: `${y}px ${x}px`,
      maxWidth: 1280,
      margin: "0 auto",
      position: "relative",
      ...style
    }
  }, eyebrow && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-mono)",
      fontSize: 11,
      letterSpacing: 1.5,
      textTransform: "uppercase",
      color: "var(--ink-4)",
      marginBottom: 18,
      display: "flex",
      alignItems: "center",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 18,
      height: 1,
      background: "var(--line-2)"
    }
  }), eyebrow), children);
};

/* ---------- Rule / Divider ---------- */
const Rule = ({
  label,
  style = {}
}) => /*#__PURE__*/React.createElement("div", {
  style: {
    display: "flex",
    alignItems: "center",
    gap: 12,
    color: "var(--ink-4)",
    fontFamily: "var(--font-mono)",
    fontSize: 11,
    letterSpacing: 1.2,
    textTransform: "uppercase",
    ...style
  }
}, label && /*#__PURE__*/React.createElement("span", null, label), /*#__PURE__*/React.createElement("div", {
  style: {
    flex: 1,
    height: 1,
    background: "var(--line)"
  }
}));
Object.assign(window, {
  useMedia,
  Icon,
  Pill,
  Btn,
  Kbd,
  MacWindow,
  Section,
  Rule
});