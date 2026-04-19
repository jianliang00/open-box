/* ============================================================
   Landing sections for OpenBox
   ============================================================ */

const I18N = {
  en: {
    "nav.features": "Features",
    "nav.terminal": "Terminal",
    "nav.compat": "Compatibility",
    "nav.faq": "FAQ",
    "nav.dark": "Dark",
    "nav.light": "Light",
    "nav.themeToDark": "Switch to dark theme",
    "nav.themeToLight": "Switch to light theme",
    "nav.langSwitch": "Switch language",
    "hero.badge": "NEW",
    "hero.strap": "Ready-to-use macOS 26 guest images — launch a sandbox in under 90s.",
    "hero.release": "Release notes",
    "hero.title1": "A disposable Mac,",
    "hero.title2": "opened in a box.",
    "hero.body": "OpenBox is a desktop app for creating isolated macOS sandboxes on Apple Silicon. Launch a full guest desktop, run commands, and throw it away — without ever touching your real machine.",
    "hero.download": "Download for macOS",
    "hero.source": "View source",
    "hero.status": "Apple Silicon · macOS 26+ · Apache 2.0",
    "hero.use1.title": "AGENT EXPLORATION",
    "hero.use1.body": "A safe desktop for Codex, Claude Code, and other coding agents.",
    "hero.use2.title": "APP TESTING",
    "hero.use2.body": "Install + launch unfamiliar apps without risking your main OS.",
    "hero.use3.title": "CLI WORKFLOWS",
    "hero.use3.body": "Run one-off scripts in a throwaway shell with full network isolation.",
    "hero.use4.title": "ENV REPRO",
    "hero.use4.body": "Pin exact macOS images; re-create sandbox state on demand.",
    "showcase.sandbox": "Manager",
    "showcase.desktop": "Guest desktop",
    "showcase.term": "Embedded term",
    "showcase.cap1": "Sandbox overview — list, status, configuration",
    "showcase.cap2": "Launch a full macOS guest session, then close the window to leave it running",
    "showcase.cap3": "Attach to a workload; logs and diagnostics stay scoped to the sandbox",
    "showcase.a1": "Create, start, stop,\ninspect, remove.",
    "showcase.a2": "Every sandbox pins\nan OCI image + digest.",
    "showcase.a3": "Signed + notarized\nDMG via GitHub Actions.",
    "features.eyebrow": "02 · What's in the box",
    "features.title1": "One visual app for every",
    "features.titleEm": "throwaway",
    "features.title2": "Mac you'll ever need.",
    "features.body": "Designed for the new breed of computer-using agents — and for the humans who want their main Mac left alone.",
    "features.tag1": "ISOLATION",
    "features.title1.card": "Full macOS guest, fully isolated",
    "features.body1": "Keep the agent's desktop, files, credentials, and browser state separate from your everyday Mac. Close the window — the sandbox keeps running.",
    "features.tag2": "QUICK START",
    "features.title2.card": "Ready-to-use images",
    "features.body2": "Pick a curated image. First sandbox launches in seconds; pull progress is visible per layer.",
    "features.tag3": "EMBEDDED",
    "features.title3.card": "Run commands in-app",
    "features.body3": "Open a terminal bound to a workload. Logs, exit codes, and diagnostic paths stay attached.",
    "features.tag4": "RECOVERABLE",
    "features.title4.card": "Throw it away",
    "features.body4": "Start, stop, inspect, remove. Experiments live in sandbox-scoped log paths until you delete them.",
    "features.tag5": "APPLE SILICON",
    "features.title5.card": "Built on Apple's container stack",
    "features.body5": "Wraps apple/container + apple/containerization. macOS 26 runtime target, native virtualization.",
    "features.running": "● RUNNING",
    "flow.eyebrow": "03 · Lifecycle",
    "flow.title": "Manage every sandbox state in real time.",
    "flow.body": "Start, stop, inspect, and recover sandboxes from one screen, with status and diagnostics updating as the workload changes.",
    "flow.new": "New sandbox",
    "flow.start": "Start",
    "flow.stop": "Stop",
    "flow.reset": "Reset",
    "flow.idle": "Idle",
    "flow.creating": "Creating",
    "flow.pulling": "Pulling",
    "flow.running": "Running",
    "flow.stopped": "Stopped",
    "flow.idle.note": "No sandbox yet.",
    "flow.creating.note": "Allocating guest, provisioning rootfs.",
    "flow.pulling.note": "Fetching OCI layers from ghcr.io.",
    "flow.running.note": "Desktop GUI ready; commands accepted.",
    "flow.stopped.note": "Snapshot preserved; logs retained.",
    "card.empty": "Empty",
    "card.click": "Click New sandbox ↑",
    "card.allocating": "Allocating virtualization device…",
    "card.layer": "layer 4/6 · 148 MB / 240 MB",
    "card.ready": "Desktop GUI ready.",
    "card.saved": "Snapshot saved.",
    "card.title": "OpenBox Sandbox",
    "card.runCommand": "Run Command",
    "card.stopSandbox": "Stop Sandbox",
    "card.startSandbox": "Start Sandbox",
    "card.remove": "Remove",
    "card.desktopGui": "Desktop GUI",
    "card.enabled": "Enabled",
    "card.workspace": "Workspace",
    "card.notMounted": "Not mounted",
    "terminal.eyebrow": "04 · Embedded terminal",
    "terminal.title1": "A shell bound to the",
    "terminal.titleEm": "sandbox,",
    "terminal.title2": "not your Mac.",
    "terminal.body": "Attach an interactive terminal to any running sandbox. Workload output is captured and stays scoped — network, file system, and credentials remain inside the guest.",
    "terminal.item1": "Per-sandbox PTY",
    "terminal.item1.body": "session multiplexing with tmux-like resume",
    "terminal.item2": "Log paths exposed",
    "terminal.item2.body": "diagnostic.log · runtime.log · kernel.log",
    "terminal.item3": "Host firewall respected",
    "terminal.item3.body": "no inbound sockets from guest to host",
    "terminal.item4": "Keybinds",
    "terminal.item4.body": "⌘K command palette · ⌘⇧T new tab · ⌃C interrupt",
    "terminal.replay": "Replay demo",
    "terminal.pause": "Pause",
    "terminal.resume": "Resume",
    "compat.eyebrow": "05 · Compatibility",
    "compat.badge": "Supported target",
    "compat.title": "Apple Silicon Mac",
    "compat.body": "OpenBox is validated for macOS 26 or later with macOS guest sandboxes and desktop windows.",
    "compat.runtime": "runtime: container-runtime-macos",
    "compat.source": "source build: Xcode 26+",
    "compat.intel": "Intel Macs: not targeted",
    "faq.eyebrow": "06 · FAQ",
    "faq.title1": "Questions,",
    "faq.title2": "honestly answered.",
    "faq.q1": "Is this related to Apple in any way?",
    "faq.a1": "No. OpenBox is an independent open-source project by @jianliang00. It wraps the open-source apple/container and apple/containerization packages, which Apple publishes on GitHub, but OpenBox itself isn't built, endorsed, or sanctioned by Apple.",
    "faq.q2": "What can I run inside a sandbox?",
    "faq.a2": "Anything that runs on macOS 26 on Apple Silicon, or any Linux image that resolves to container-runtime-linux. The focus is full macOS guest sandboxes — desktop session, keyboard, pointer, graphics.",
    "faq.q3": "Does it work on Intel Macs?",
    "faq.a3": "No. Apple Silicon is the current target. The underlying stack requires Apple's virtualization framework on ARM hardware.",
    "faq.q4": "How isolated is the guest?",
    "faq.a4": "The guest runs in its own VM with its own file system, credentials, and browser state. Host firewall rules still apply; OpenBox never opens inbound sockets from guest to host by default.",
    "faq.q5": "Can I use it to run AI agents?",
    "faq.a5": "Yes — that's the intended use case. Disposable macOS environments are a good place for computer-using agents to explore without touching your main setup.",
    "faq.q6": "What's the license?",
    "faq.a6": "Apache License 2.0. Fork it, ship it, embed it. Release DMGs are signed and notarized through GitHub Actions on macOS 26 runners.",
    "footer.body": "A desktop app for creating and managing isolated Mac environments. Open source — Apache 2.0 — by @jianliang00 and contributors.",
    "footer.project": "Project",
    "footer.compat": "Compatibility",
    "footer.license": "License",
    "footer.releases": "Releases",
    "footer.latest": "Latest DMG",
    "footer.changelog": "Changelog",
    "footer.actions": "Actions",
    "footer.community": "Community",
    "footer.issues": "GitHub Issues",
    "footer.discussions": "Discussions",
    "footer.source": "Source",
    "footer.copy": "© 2026 OpenBox contributors · Apache 2.0",
    "footer.note": "Not affiliated with Apple Inc. · 0.0.6-alpha"
  },
  zh: {
    "nav.features": "功能",
    "nav.terminal": "终端",
    "nav.compat": "兼容性",
    "nav.faq": "FAQ",
    "nav.dark": "深色",
    "nav.light": "浅色",
    "nav.themeToDark": "切换到深色主题",
    "nav.themeToLight": "切换到浅色主题",
    "nav.langSwitch": "切换语言",
    "hero.badge": "新",
    "hero.strap": "可直接使用的 macOS 26 客体镜像，90 秒内启动沙盒。",
    "hero.release": "查看发布",
    "hero.title1": "一台可丢弃的 Mac，",
    "hero.title2": "装进盒子里。",
    "hero.body": "OpenBox 是一个用于创建隔离 macOS 沙盒的桌面应用。启动完整客体桌面、运行命令、随时丢弃，而不影响你的真实 Mac。",
    "hero.download": "下载 macOS 版",
    "hero.source": "查看源码",
    "hero.status": "Apple Silicon · macOS 26+ · Apache 2.0",
    "hero.use1.title": "智能体探索",
    "hero.use1.body": "给 Codex、Claude Code 和其他编程智能体一个安全桌面。",
    "hero.use2.title": "应用测试",
    "hero.use2.body": "安装并启动陌生应用，不冒险污染主系统。",
    "hero.use3.title": "CLI 工作流",
    "hero.use3.body": "在一次性 shell 中运行脚本，并保持完整网络隔离。",
    "hero.use4.title": "环境复现",
    "hero.use4.body": "固定 macOS 镜像，按需重新创建沙盒状态。",
    "showcase.sandbox": "管理器",
    "showcase.desktop": "客体桌面",
    "showcase.term": "内置终端",
    "showcase.cap1": "沙盒概览：列表、状态、配置",
    "showcase.cap2": "启动完整 macOS 客体会话，关闭窗口后沙盒仍可继续运行",
    "showcase.cap3": "连接到工作负载，日志和诊断保持在沙盒作用域内",
    "showcase.a1": "创建、启动、停止、\n检查、移除。",
    "showcase.a2": "每个沙盒都固定\nOCI 镜像与 digest。",
    "showcase.a3": "通过 GitHub Actions\n签名并公证 DMG。",
    "features.eyebrow": "02 · 盒子里有什么",
    "features.title1": "一个可视化应用，管理所有",
    "features.titleEm": "一次性",
    "features.title2": "Mac。",
    "features.body": "为新一代会使用电脑的智能体设计，也为希望主力 Mac 保持干净的人设计。",
    "features.tag1": "隔离",
    "features.title1.card": "完整 macOS 客体，完全隔离",
    "features.body1": "把智能体的桌面、文件、凭据和浏览器状态与你的日常 Mac 分离。关闭窗口后，沙盒仍可运行。",
    "features.tag2": "快速启动",
    "features.title2.card": "可直接使用的镜像",
    "features.body2": "选择内置镜像，首个沙盒数秒启动，拉取进度按层可见。",
    "features.tag3": "内置",
    "features.title3.card": "在应用内运行命令",
    "features.body3": "打开绑定到工作负载的终端。日志、退出码和诊断路径都会保留。",
    "features.tag4": "可恢复",
    "features.title4.card": "用完即丢",
    "features.body4": "启动、停止、检查、移除。实验记录保存在沙盒日志路径中，直到你删除它。",
    "features.tag5": "APPLE SILICON",
    "features.title5.card": "基于 Apple container 栈",
    "features.body5": "封装 apple/container 与 apple/containerization。面向 macOS 26 运行时和原生虚拟化。",
    "features.running": "● 运行中",
    "flow.eyebrow": "03 · 生命周期",
    "flow.title": "实时管理每个沙盒状态。",
    "flow.body": "在一个界面里启动、停止、检查和恢复沙盒，状态与诊断信息会随工作负载实时更新。",
    "flow.new": "新建沙盒",
    "flow.start": "启动",
    "flow.stop": "停止",
    "flow.reset": "重置",
    "flow.idle": "空闲",
    "flow.creating": "创建中",
    "flow.pulling": "拉取中",
    "flow.running": "运行中",
    "flow.stopped": "已停止",
    "flow.idle.note": "还没有沙盒。",
    "flow.creating.note": "正在分配客体并准备 rootfs。",
    "flow.pulling.note": "正在从 ghcr.io 拉取 OCI 层。",
    "flow.running.note": "桌面 GUI 就绪，命令可用。",
    "flow.stopped.note": "快照已保存，日志已保留。",
    "card.empty": "空",
    "card.click": "点击新建沙盒 ↑",
    "card.allocating": "正在分配虚拟化设备…",
    "card.layer": "第 4/6 层 · 148 MB / 240 MB",
    "card.ready": "桌面 GUI 就绪。",
    "card.saved": "快照已保存。",
    "card.title": "OpenBox 沙盒",
    "card.runCommand": "运行命令",
    "card.stopSandbox": "停止沙盒",
    "card.startSandbox": "启动沙盒",
    "card.remove": "移除",
    "card.desktopGui": "桌面 GUI",
    "card.enabled": "已启用",
    "card.workspace": "工作区",
    "card.notMounted": "未挂载",
    "terminal.eyebrow": "04 · 内置终端",
    "terminal.title1": "shell 绑定到",
    "terminal.titleEm": "沙盒，",
    "terminal.title2": "不是你的 Mac。",
    "terminal.body": "把交互式终端连接到任何运行中的沙盒。工作负载输出会被捕获并保持在客体内，包括网络、文件系统和凭据。",
    "terminal.item1": "每沙盒 PTY",
    "terminal.item1.body": "类似 tmux 的会话复用和恢复",
    "terminal.item2": "暴露日志路径",
    "terminal.item2.body": "diagnostic.log · runtime.log · kernel.log",
    "terminal.item3": "尊重主机防火墙",
    "terminal.item3.body": "客体不会向主机开放入站 socket",
    "terminal.item4": "快捷键",
    "terminal.item4.body": "⌘K 命令面板 · ⌘⇧T 新标签 · ⌃C 中断",
    "terminal.replay": "重放演示",
    "terminal.pause": "暂停",
    "terminal.resume": "继续",
    "compat.eyebrow": "05 · 兼容性",
    "compat.badge": "支持目标",
    "compat.title": "Apple Silicon Mac",
    "compat.body": "OpenBox 已针对 macOS 26 或更高版本验证，支持 macOS 客体沙盒和桌面窗口。",
    "compat.runtime": "运行时：container-runtime-macos",
    "compat.source": "源码构建：Xcode 26+",
    "compat.intel": "Intel Mac：暂不支持",
    "faq.eyebrow": "06 · FAQ",
    "faq.title1": "常见问题，",
    "faq.title2": "直接回答。",
    "faq.q1": "这和 Apple 有关系吗？",
    "faq.a1": "没有。OpenBox 是 @jianliang00 发起的独立开源项目。它封装了 Apple 在 GitHub 上开源的 apple/container 和 apple/containerization，但 OpenBox 本身并非 Apple 构建、背书或授权。",
    "faq.q2": "沙盒里可以运行什么？",
    "faq.a2": "任何能在 Apple Silicon 的 macOS 26 上运行的内容，或能解析到 container-runtime-linux 的 Linux 镜像。重点是完整 macOS 客体沙盒，包括桌面、键盘、指针和图形。",
    "faq.q3": "支持 Intel Mac 吗？",
    "faq.a3": "不支持。Apple Silicon 是当前目标。底层栈依赖 Apple 在 ARM 硬件上的虚拟化框架。",
    "faq.q4": "隔离程度如何？",
    "faq.a4": "客体运行在自己的 VM 中，拥有独立文件系统、凭据和浏览器状态。主机防火墙规则仍然生效；OpenBox 默认不会从客体向主机开放入站 socket。",
    "faq.q5": "可以用来运行 AI 智能体吗？",
    "faq.a5": "可以，这正是主要使用场景。一次性 macOS 环境适合让使用电脑的智能体探索，而不触碰你的主系统。",
    "faq.q6": "许可证是什么？",
    "faq.a6": "Apache License 2.0。可以 fork、分发、嵌入。发布 DMG 会通过 GitHub Actions 在 macOS 26 runner 上签名并公证。",
    "footer.body": "用于创建和管理隔离 Mac 环境的桌面应用。开源，Apache 2.0，由 @jianliang00 和贡献者维护。",
    "footer.project": "项目",
    "footer.compat": "兼容性",
    "footer.license": "许可证",
    "footer.releases": "发布",
    "footer.latest": "最新 DMG",
    "footer.changelog": "变更日志",
    "footer.actions": "Actions",
    "footer.community": "社区",
    "footer.issues": "GitHub Issues",
    "footer.discussions": "Discussions",
    "footer.source": "源码",
    "footer.copy": "© 2026 OpenBox contributors · Apache 2.0",
    "footer.note": "与 Apple Inc. 无隶属关系 · 0.0.6-alpha"
  }
};

const tr = key => {
  const lang = window.__OPENBOX_LANG__ === "zh" ? "zh" : "en";
  return I18N[lang]?.[key] ?? I18N.en[key] ?? key;
};

const lines = key => tr(key).split("\n").map((line, i) => (
  <React.Fragment key={i}>{i > 0 && <br/>}{line}</React.Fragment>
));

/* ---------- NAV ---------- */
const navControlStyle = {
  height: 32,
  minWidth: 52,
  padding: "0 10px",
  borderRadius: 7,
  border: "1px solid var(--line)",
  background: "var(--surface)",
  color: "var(--ink-2)",
  fontFamily: "var(--font-body)",
  fontSize: 13,
  fontWeight: 600,
  cursor: "pointer",
};

const Nav = ({ theme = "light", lang = "en", onToggleTheme, onToggleLang }) => {
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
        <a href="#top" style={{ display: "flex", alignItems: "center", gap: 12, flexShrink: 0 }}>
          <Logo size={36} theme={theme}/>
          <span style={{ fontWeight: 700, fontSize: 21, letterSpacing: 0, lineHeight: 1 }}>OpenBox</span>
          {!compact && <Pill tone="ghost" size="xs" mono>v0.0.6 · alpha</Pill>}
        </a>
        <div style={{
          display: compact ? "none" : "flex", gap: 24, marginLeft: 24,
          fontSize: 14, color: "var(--ink-3)",
        }}>
          <a href="#features" style={{ color: "inherit" }}>{tr("nav.features")}</a>
          <a href="#terminal" style={{ color: "inherit" }}>{tr("nav.terminal")}</a>
          <a href="#compat" style={{ color: "inherit" }}>{tr("nav.compat")}</a>
          <a href="#faq" style={{ color: "inherit" }}>{tr("nav.faq")}</a>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <button
            type="button"
            onClick={onToggleTheme}
            aria-label={theme === "dark" ? tr("nav.themeToLight") : tr("nav.themeToDark")}
            title={theme === "dark" ? tr("nav.themeToLight") : tr("nav.themeToDark")}
            style={navControlStyle}>
            {theme === "dark" ? tr("nav.light") : tr("nav.dark")}
          </button>
          <button
            type="button"
            onClick={onToggleLang}
            aria-label={tr("nav.langSwitch")}
            title={tr("nav.langSwitch")}
            style={{ ...navControlStyle, minWidth: 44 }}>
            {lang === "zh" ? "EN" : "中文"}
          </button>
        </div>
        <a href="https://github.com/jianliang00/open-box" aria-label="GitHub" style={{
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          width: 34, height: 34,
          color: "var(--ink-2)",
        }}>
          <Icon name="github" size={18}/>
        </a>
      </div>
    </nav>
  );
};

/* ---------- LOGO ---------- */
const Logo = ({ size = 24, theme }) => (
  <img
    src={(theme || document.documentElement.dataset.theme) === "dark" ? "logo-web-dark.png" : "logo-web.png"}
    alt=""
    width={size}
    height={size}
    aria-hidden="true"
    draggable="false"
    style={{ display: "block", width: size, height: size }}
  />
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
          <Pill tone="accent" size="xs" mono>{tr("hero.badge")}</Pill>
          <span>{tr("hero.strap")}</span>
          <a href="https://github.com/jianliang00/open-box/releases/latest" style={{ color: "var(--ink-2)", textDecoration: "underline", textDecorationColor: "var(--line-2)", textUnderlineOffset: 3 }}>
            {tr("hero.release")} →
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
            {tr("hero.title1")}<br/>
            <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400, letterSpacing: "-0.01em" }}>
              {tr("hero.title2")}
            </span>
          </h1>

          <p style={{
            fontSize: compact ? 17 : 20, lineHeight: 1.45, color: "var(--ink-3)",
            maxWidth: 680, margin: "0 0 36px 0", fontWeight: 400,
          }}>
            {tr("hero.body")}
          </p>

          <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap", marginBottom: 24 }}>
            <Btn variant="accent" size="lg" icon="download" href="https://github.com/jianliang00/open-box/releases/latest">
              {tr("hero.download")}
            </Btn>
            <Btn variant="ghost" size="lg" icon="github" iconRight="arrow-up-right" href="https://github.com/jianliang00/open-box">
              {tr("hero.source")}
            </Btn>
            <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "var(--ink-4)", marginLeft: compact ? 0 : 8 }}>
              <Icon name="check" size={14}/> {tr("hero.status")}
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
            [tr("hero.use1.title"), tr("hero.use1.body")],
            [tr("hero.use2.title"), tr("hero.use2.body")],
            [tr("hero.use3.title"), tr("hero.use3.body")],
            [tr("hero.use4.title"), tr("hero.use4.body")],
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
        {copied ? (window.__OPENBOX_LANG__ === "zh" ? "已复制" : "copied") : (window.__OPENBOX_LANG__ === "zh" ? "复制" : "copy")}
      </span>
    </button>
  );
};

/* ---------- HERO SHOWCASE: tabbed window ---------- */
const HeroShowcase = () => {
  const [tab, setTab] = React.useState("sandbox");
  const compact = useMedia("(max-width: 760px)");
  const tabs = [
    { id: "sandbox", label: tr("showcase.sandbox"), img: "showcase/openbox-showcase-1.png", cap: tr("showcase.cap1") },
    { id: "desktop", label: tr("showcase.desktop"), img: "showcase/openbox-showcase-2.png", cap: tr("showcase.cap2") },
    { id: "term",    label: tr("showcase.term"),    img: "showcase/openbox-showcase-3.png", cap: tr("showcase.cap3") },
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
            text={lines("showcase.a1")}
          />
          <Annotation
            style={{ top: 260, right: -8, textAlign: "right", alignItems: "flex-end" }}
            label="02"
            text={lines("showcase.a2")}
          />
          <Annotation
            style={{ bottom: -12, left: "30%" }}
            label="03"
            text={lines("showcase.a3")}
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

      <div style={{
        maxWidth: 1180,
        overflow: "hidden",
        border: "1px solid var(--line)",
        borderRadius: 12,
        boxShadow: "0 1px 1px rgba(0,0,0,0.02), 0 10px 30px rgba(0,0,0,0.08), 0 40px 80px rgba(0,0,0,0.08)",
      }}>
        <div style={{ position: "relative", aspectRatio: "2940/1716", background: "#f5f5f7" }}>
          <img src={active.img} alt={active.label}
            style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }}/>
        </div>
      </div>

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
      icon: "box", tag: tr("features.tag1"),
      title: tr("features.title1.card"),
      body: tr("features.body1"),
      big: true,
    },
    {
      icon: "bolt", tag: tr("features.tag2"),
      title: tr("features.title2.card"),
      body: tr("features.body2"),
    },
    {
      icon: "terminal", tag: tr("features.tag3"),
      title: tr("features.title3.card"),
      body: tr("features.body3"),
    },
    {
      icon: "layers", tag: tr("features.tag4"),
      title: tr("features.title4.card"),
      body: tr("features.body4"),
    },
    {
      icon: "chip", tag: tr("features.tag5"),
      title: tr("features.title5.card"),
      body: tr("features.body5"),
    },
  ];
  return (
    <Section id="features" eyebrow={tr("features.eyebrow")}>
      <div style={{
        display: "flex", justifyContent: "space-between",
        alignItems: "flex-end", gap: 24, marginBottom: 48, flexWrap: "wrap",
      }}>
        <h2 style={{
          fontSize: "clamp(40px, 5vw, 64px)", fontWeight: 500,
          letterSpacing: "-0.03em", lineHeight: 1.0, margin: 0,
          maxWidth: 720, textWrap: "balance",
        }}>
          {tr("features.title1")}{" "}
          <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 }}>
            {tr("features.titleEm")}
          </span>{" "}
          {tr("features.title2")}
        </h2>
        <p style={{ color: "var(--ink-3)", fontSize: 15, maxWidth: 360, margin: 0, lineHeight: 1.5 }}>
          {tr("features.body")}
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
    { gridColumn: "span 3" },
    { gridColumn: "span 3" },
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
      <Pill tone="good" size="xs">{tr("features.running")}</Pill>
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
    { id: "idle",     label: tr("flow.idle"),      color: "var(--ink-4)",   note: tr("flow.idle.note") },
    { id: "creating", label: tr("flow.creating"),  color: "var(--warn)",    note: tr("flow.creating.note") },
    { id: "pulling",  label: tr("flow.pulling"),   color: "var(--accent)",  note: tr("flow.pulling.note") },
    { id: "running",  label: tr("flow.running"),   color: "var(--good)",    note: tr("flow.running.note") },
    { id: "stopped",  label: tr("flow.stopped"),   color: "var(--ink-3)",   note: tr("flow.stopped.note") },
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
    <Section id="lifecycle" eyebrow={tr("flow.eyebrow")}>
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1.1fr 1fr", gap: compact ? 32 : 48, alignItems: "center" }}>
        <div>
          <h2 style={{
            fontSize: "clamp(36px, 4.5vw, 56px)", fontWeight: 500,
            letterSpacing: "-0.025em", lineHeight: 1.05, margin: "0 0 20px 0",
            textWrap: "balance",
          }}>
            {tr("flow.title")}
          </h2>
          <p style={{ color: "var(--ink-3)", fontSize: 16, lineHeight: 1.55, margin: "0 0 28px 0", maxWidth: 480 }}>
            {tr("flow.body")}
          </p>

          {/* controls */}
          <div style={{ display: "flex", gap: 10, marginBottom: 20, flexWrap: "wrap" }}>
            <Btn variant="accent" size="sm" icon="plus" onClick={() => setState("creating")}>{tr("flow.new")}</Btn>
            <Btn variant="ghost" size="sm" icon={state === "running" ? "stop" : "play"} onClick={() => setState(state === "running" ? "stopped" : "running")} disabled={state === "creating" || state === "pulling"}>
              {state === "running" ? tr("flow.stop") : tr("flow.start")}
            </Btn>
            <Btn variant="ghost" size="sm" onClick={() => setState("idle")}>{tr("flow.reset")}</Btn>
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
    idle:     { pill: [tr("card.empty"), "var(--ink-3)", "var(--bg-2)"],  progress: 0,   body: tr("card.click") },
    creating: { pill: [tr("flow.creating"), "var(--warn)", "oklch(0.95 0.04 60)"], progress: 15, body: tr("card.allocating") },
    pulling:  { pill: [tr("flow.pulling"), "var(--accent)", "var(--accent-bg)"], progress: 62, body: tr("card.layer") },
    running:  { pill: [tr("flow.running"), "var(--good)", "var(--good-bg)"], progress: 100, body: tr("card.ready") },
    stopped:  { pill: [tr("flow.stopped"), "var(--ink-3)", "var(--bg-2)"],  progress: 0,   body: tr("card.saved") },
  };
  const m = map[state];

  return (
    <MacWindow title="OpenBox — openbox-sandbox-376036f9" style={{ borderRadius: 12 }}>
      <div style={{ padding: 24, background: "var(--surface)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
          <div style={{
            width: 44, height: 44, borderRadius: 10,
            background: "var(--ink)", color: "#fff",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name="box" size={20}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 600 }}>{tr("card.title")}</div>
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
            [tr("card.desktopGui"), state === "running" ? `${tr("card.enabled")} ✓` : tr("card.enabled")],
            [tr("card.workspace"), tr("card.notMounted")],
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
          <Btn variant="soft" size="sm" icon="terminal" disabled={state !== "running"}>{tr("card.runCommand")}</Btn>
          <Btn variant={state === "running" ? "soft" : "accent"} size="sm" icon={state === "running" ? "stop" : "play"}>
            {state === "running" ? tr("card.stopSandbox") : tr("card.startSandbox")}
          </Btn>
          <div style={{ flex: 1 }}/>
          <Btn variant="ghost" size="sm">{tr("card.remove")}</Btn>
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
    <Section id="terminal" eyebrow={tr("terminal.eyebrow")}>
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 1.3fr", gap: compact ? 32 : 48, alignItems: "center" }}>
        <div>
          <h2 style={{
            fontSize: "clamp(36px, 4.5vw, 56px)", fontWeight: 500,
            letterSpacing: "-0.025em", lineHeight: 1.05, margin: "0 0 20px 0",
          }}>
            {tr("terminal.title1")}{" "}
            <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 }}>{tr("terminal.titleEm")}</span>{" "}
            {tr("terminal.title2")}
          </h2>
          <p style={{ color: "var(--ink-3)", fontSize: 16, lineHeight: 1.55, margin: "0 0 24px 0", maxWidth: 480 }}>
            {tr("terminal.body")}
          </p>
          <ul style={{ margin: 0, padding: 0, listStyle: "none", display: "flex", flexDirection: "column", gap: 10 }}>
            {[
              [tr("terminal.item1"), tr("terminal.item1.body")],
              [tr("terminal.item2"), tr("terminal.item2.body")],
              [tr("terminal.item3"), tr("terminal.item3.body")],
              [tr("terminal.item4"), tr("terminal.item4.body")],
            ].map(([k,v]) => (
              <li key={k} style={{ display: "flex", alignItems: "baseline", gap: 12, fontSize: 14, color: "var(--ink-2)" }}>
                <Icon name="check" size={14} style={{ color: "var(--accent)", flexShrink: 0 }}/>
                <span><b style={{ fontWeight: 600 }}>{k}</b> — <span style={{ color: "var(--ink-3)" }}>{v}</span></span>
              </li>
            ))}
          </ul>
          <div style={{ marginTop: 28, display: "flex", gap: 8 }}>
            <Btn variant="soft" size="sm" onClick={restart} icon="play">{tr("terminal.replay")}</Btn>
            <Btn variant="ghost" size="sm" onClick={() => setRunning(r => !r)} icon={running ? "stop" : "play"}>
              {running ? tr("terminal.pause") : tr("terminal.resume")}
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
  return (
    <Section id="compat" eyebrow={tr("compat.eyebrow")} style={{ paddingTop: 80, paddingBottom: 72 }}>
      <div style={{
        display: "flex",
        flexDirection: compact ? "column" : "row",
        alignItems: compact ? "flex-start" : "center",
        justifyContent: "space-between",
        gap: compact ? 22 : 40,
        padding: compact ? "24px 22px" : "30px 34px",
        background: "var(--surface)",
        border: "1px solid var(--line)",
        borderRadius: 12,
        boxShadow: "0 16px 40px rgba(0,0,0,0.05)",
      }}>
        <div>
          <Pill tone="good" size="xs">{tr("compat.badge")}</Pill>
          <h2 style={{
            fontSize: "clamp(28px, 3.4vw, 42px)", fontWeight: 600,
            letterSpacing: 0, lineHeight: 1.08, margin: "14px 0 10px 0",
          }}>
            {tr("compat.title")}
          </h2>
          <p style={{ color: "var(--ink-3)", fontSize: 15, lineHeight: 1.55, margin: 0, maxWidth: 620 }}>
            {tr("compat.body")}
          </p>
        </div>
        <div style={{
          fontFamily: "var(--font-mono)",
          fontSize: 12,
          lineHeight: 1.8,
          color: "var(--ink-3)",
          minWidth: compact ? "auto" : 280,
        }}>
          {tr("compat.runtime")}<br/>
          {tr("compat.source")}<br/>
          {tr("compat.intel")}
        </div>
      </div>
    </Section>
  );
};

/* ---------- FAQ ---------- */
const FAQ = () => {
  const compact = useMedia("(max-width: 760px)");
  const items = [
    [tr("faq.q1"), tr("faq.a1")],
    [tr("faq.q2"), tr("faq.a2")],
    [tr("faq.q3"), tr("faq.a3")],
    [tr("faq.q4"), tr("faq.a4")],
    [tr("faq.q5"), tr("faq.a5")],
    [tr("faq.q6"), tr("faq.a6")],
  ];
  const [open, setOpen] = React.useState(0);
  return (
    <Section id="faq" eyebrow={tr("faq.eyebrow")} style={{ paddingTop: 60 }}>
      <div style={{ display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 2fr", gap: compact ? 28 : 48 }}>
        <h2 style={{
          fontSize: "clamp(36px, 4.5vw, 56px)", fontWeight: 500,
          letterSpacing: "-0.025em", lineHeight: 1.0, margin: 0,
        }}>
          {tr("faq.title1")} <span style={{ fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 }}>{tr("faq.title2")}</span>
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
    [tr("footer.project"), [
      ["README", "https://github.com/jianliang00/open-box#readme"],
      [tr("footer.compat"), "COMPATIBILITY.md"],
      [tr("footer.license"), "https://github.com/jianliang00/open-box/blob/main/LICENSE"],
    ]],
    [tr("footer.releases"), [
      [tr("footer.latest"), "https://github.com/jianliang00/open-box/releases/latest"],
      [tr("footer.changelog"), "https://github.com/jianliang00/open-box/releases/tag/0.0.6"],
      [tr("footer.actions"), "https://github.com/jianliang00/open-box/actions"],
    ]],
    [tr("footer.community"), [
      [tr("footer.issues"), "https://github.com/jianliang00/open-box/issues"],
      [tr("footer.discussions"), "https://github.com/jianliang00/open-box/discussions"],
      [tr("footer.source"), "https://github.com/jianliang00/open-box"],
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
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 14 }}>
            <Logo size={32}/>
            <span style={{ fontWeight: 700, fontSize: 20, lineHeight: 1 }}>OpenBox</span>
          </div>
          <p style={{ color: "var(--ink-3)", fontSize: 13.5, lineHeight: 1.55, maxWidth: 340, margin: 0 }}>
            {tr("footer.body")}
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
        <span>{tr("footer.copy")}</span>
        <span>{tr("footer.note")}</span>
      </div>
    </footer>
  );
};

Object.assign(window, { Nav, Hero, Features, Flow, TerminalDemo, Compat, FAQ, Footer, Logo });
