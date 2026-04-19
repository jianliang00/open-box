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
    "hero.strap": "Ready-to-use macOS 26 guest images \u2014 launch a sandbox in under 90s.",
    "hero.release": "Release notes",
    "hero.title1": "A disposable Mac,",
    "hero.title2": "opened in a box.",
    "hero.body": "OpenBox is a desktop app for creating isolated macOS sandboxes on Apple Silicon. Launch a full guest desktop, run commands, and throw it away \u2014 without ever touching your real machine.",
    "hero.download": "Download for macOS",
    "hero.source": "View source",
    "hero.status": "Apple Silicon \xB7 macOS 26+ \xB7 Apache 2.0",
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
    "showcase.cap1": "Sandbox overview \u2014 list, status, configuration",
    "showcase.cap2": "Launch a full macOS guest session, then close the window to leave it running",
    "showcase.cap3": "Attach to a workload; logs and diagnostics stay scoped to the sandbox",
    "showcase.a1": "Create, start, stop,\ninspect, remove.",
    "showcase.a2": "Every sandbox pins\nan OCI image + digest.",
    "showcase.a3": "Signed + notarized\nDMG via GitHub Actions.",
    "features.eyebrow": "02 \xB7 What's in the box",
    "features.title1": "One visual app for every",
    "features.titleEm": "throwaway",
    "features.title2": "Mac you'll ever need.",
    "features.body": "Designed for the new breed of computer-using agents \u2014 and for the humans who want their main Mac left alone.",
    "features.tag1": "ISOLATION",
    "features.title1.card": "Full macOS guest, fully isolated",
    "features.body1": "Keep the agent's desktop, files, credentials, and browser state separate from your everyday Mac. Close the window \u2014 the sandbox keeps running.",
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
    "features.running": "\u25CF RUNNING",
    "flow.eyebrow": "03 \xB7 Lifecycle",
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
    "card.click": "Click New sandbox \u2191",
    "card.allocating": "Allocating virtualization device\u2026",
    "card.layer": "layer 4/6 \xB7 148 MB / 240 MB",
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
    "terminal.eyebrow": "04 \xB7 Embedded terminal",
    "terminal.title1": "A shell bound to the",
    "terminal.titleEm": "sandbox,",
    "terminal.title2": "not your Mac.",
    "terminal.body": "Attach an interactive terminal to any running sandbox. Workload output is captured and stays scoped \u2014 network, file system, and credentials remain inside the guest.",
    "terminal.item1": "Per-sandbox PTY",
    "terminal.item1.body": "session multiplexing with tmux-like resume",
    "terminal.item2": "Log paths exposed",
    "terminal.item2.body": "diagnostic.log \xB7 runtime.log \xB7 kernel.log",
    "terminal.item3": "Host firewall respected",
    "terminal.item3.body": "no inbound sockets from guest to host",
    "terminal.item4": "Keybinds",
    "terminal.item4.body": "\u2318K command palette \xB7 \u2318\u21E7T new tab \xB7 \u2303C interrupt",
    "terminal.replay": "Replay demo",
    "terminal.pause": "Pause",
    "terminal.resume": "Resume",
    "compat.eyebrow": "05 \xB7 Compatibility",
    "compat.badge": "Supported target",
    "compat.title": "Apple Silicon Mac",
    "compat.body": "OpenBox is validated for macOS 26 or later with macOS guest sandboxes and desktop windows.",
    "compat.runtime": "runtime: container-runtime-macos",
    "compat.source": "source build: Xcode 26+",
    "compat.intel": "Intel Macs: not targeted",
    "faq.eyebrow": "06 \xB7 FAQ",
    "faq.title1": "Questions,",
    "faq.title2": "honestly answered.",
    "faq.q1": "Is this related to Apple in any way?",
    "faq.a1": "No. OpenBox is an independent open-source project by @jianliang00. It wraps the open-source apple/container and apple/containerization packages, which Apple publishes on GitHub, but OpenBox itself isn't built, endorsed, or sanctioned by Apple.",
    "faq.q2": "What can I run inside a sandbox?",
    "faq.a2": "Anything that runs on macOS 26 on Apple Silicon, or any Linux image that resolves to container-runtime-linux. The focus is full macOS guest sandboxes \u2014 desktop session, keyboard, pointer, graphics.",
    "faq.q3": "Does it work on Intel Macs?",
    "faq.a3": "No. Apple Silicon is the current target. The underlying stack requires Apple's virtualization framework on ARM hardware.",
    "faq.q4": "How isolated is the guest?",
    "faq.a4": "The guest runs in its own VM with its own file system, credentials, and browser state. Host firewall rules still apply; OpenBox never opens inbound sockets from guest to host by default.",
    "faq.q5": "Can I use it to run AI agents?",
    "faq.a5": "Yes \u2014 that's the intended use case. Disposable macOS environments are a good place for computer-using agents to explore without touching your main setup.",
    "faq.q6": "What's the license?",
    "faq.a6": "Apache License 2.0. Fork it, ship it, embed it. Release DMGs are signed and notarized through GitHub Actions on macOS 26 runners.",
    "footer.body": "A desktop app for creating and managing isolated Mac environments. Open source \u2014 Apache 2.0 \u2014 by @jianliang00 and contributors.",
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
    "footer.copy": "\xA9 2026 OpenBox contributors \xB7 Apache 2.0",
    "footer.note": "Not affiliated with Apple Inc. \xB7 0.0.6-alpha"
  },
  zh: {
    "nav.features": "\u529F\u80FD",
    "nav.terminal": "\u7EC8\u7AEF",
    "nav.compat": "\u517C\u5BB9\u6027",
    "nav.faq": "FAQ",
    "nav.dark": "\u6DF1\u8272",
    "nav.light": "\u6D45\u8272",
    "nav.themeToDark": "\u5207\u6362\u5230\u6DF1\u8272\u4E3B\u9898",
    "nav.themeToLight": "\u5207\u6362\u5230\u6D45\u8272\u4E3B\u9898",
    "nav.langSwitch": "\u5207\u6362\u8BED\u8A00",
    "hero.badge": "\u65B0",
    "hero.strap": "\u53EF\u76F4\u63A5\u4F7F\u7528\u7684 macOS 26 \u5BA2\u4F53\u955C\u50CF\uFF0C90 \u79D2\u5185\u542F\u52A8\u6C99\u76D2\u3002",
    "hero.release": "\u67E5\u770B\u53D1\u5E03",
    "hero.title1": "\u4E00\u53F0\u53EF\u4E22\u5F03\u7684 Mac\uFF0C",
    "hero.title2": "\u88C5\u8FDB\u76D2\u5B50\u91CC\u3002",
    "hero.body": "OpenBox \u662F\u4E00\u4E2A\u7528\u4E8E\u521B\u5EFA\u9694\u79BB macOS \u6C99\u76D2\u7684\u684C\u9762\u5E94\u7528\u3002\u542F\u52A8\u5B8C\u6574\u5BA2\u4F53\u684C\u9762\u3001\u8FD0\u884C\u547D\u4EE4\u3001\u968F\u65F6\u4E22\u5F03\uFF0C\u800C\u4E0D\u5F71\u54CD\u4F60\u7684\u771F\u5B9E Mac\u3002",
    "hero.download": "\u4E0B\u8F7D macOS \u7248",
    "hero.source": "\u67E5\u770B\u6E90\u7801",
    "hero.status": "Apple Silicon \xB7 macOS 26+ \xB7 Apache 2.0",
    "hero.use1.title": "\u667A\u80FD\u4F53\u63A2\u7D22",
    "hero.use1.body": "\u7ED9 Codex\u3001Claude Code \u548C\u5176\u4ED6\u7F16\u7A0B\u667A\u80FD\u4F53\u4E00\u4E2A\u5B89\u5168\u684C\u9762\u3002",
    "hero.use2.title": "\u5E94\u7528\u6D4B\u8BD5",
    "hero.use2.body": "\u5B89\u88C5\u5E76\u542F\u52A8\u964C\u751F\u5E94\u7528\uFF0C\u4E0D\u5192\u9669\u6C61\u67D3\u4E3B\u7CFB\u7EDF\u3002",
    "hero.use3.title": "CLI \u5DE5\u4F5C\u6D41",
    "hero.use3.body": "\u5728\u4E00\u6B21\u6027 shell \u4E2D\u8FD0\u884C\u811A\u672C\uFF0C\u5E76\u4FDD\u6301\u5B8C\u6574\u7F51\u7EDC\u9694\u79BB\u3002",
    "hero.use4.title": "\u73AF\u5883\u590D\u73B0",
    "hero.use4.body": "\u56FA\u5B9A macOS \u955C\u50CF\uFF0C\u6309\u9700\u91CD\u65B0\u521B\u5EFA\u6C99\u76D2\u72B6\u6001\u3002",
    "showcase.sandbox": "\u7BA1\u7406\u5668",
    "showcase.desktop": "\u5BA2\u4F53\u684C\u9762",
    "showcase.term": "\u5185\u7F6E\u7EC8\u7AEF",
    "showcase.cap1": "\u6C99\u76D2\u6982\u89C8\uFF1A\u5217\u8868\u3001\u72B6\u6001\u3001\u914D\u7F6E",
    "showcase.cap2": "\u542F\u52A8\u5B8C\u6574 macOS \u5BA2\u4F53\u4F1A\u8BDD\uFF0C\u5173\u95ED\u7A97\u53E3\u540E\u6C99\u76D2\u4ECD\u53EF\u7EE7\u7EED\u8FD0\u884C",
    "showcase.cap3": "\u8FDE\u63A5\u5230\u5DE5\u4F5C\u8D1F\u8F7D\uFF0C\u65E5\u5FD7\u548C\u8BCA\u65AD\u4FDD\u6301\u5728\u6C99\u76D2\u4F5C\u7528\u57DF\u5185",
    "showcase.a1": "\u521B\u5EFA\u3001\u542F\u52A8\u3001\u505C\u6B62\u3001\n\u68C0\u67E5\u3001\u79FB\u9664\u3002",
    "showcase.a2": "\u6BCF\u4E2A\u6C99\u76D2\u90FD\u56FA\u5B9A\nOCI \u955C\u50CF\u4E0E digest\u3002",
    "showcase.a3": "\u901A\u8FC7 GitHub Actions\n\u7B7E\u540D\u5E76\u516C\u8BC1 DMG\u3002",
    "features.eyebrow": "02 \xB7 \u76D2\u5B50\u91CC\u6709\u4EC0\u4E48",
    "features.title1": "\u4E00\u4E2A\u53EF\u89C6\u5316\u5E94\u7528\uFF0C\u7BA1\u7406\u6240\u6709",
    "features.titleEm": "\u4E00\u6B21\u6027",
    "features.title2": "Mac\u3002",
    "features.body": "\u4E3A\u65B0\u4E00\u4EE3\u4F1A\u4F7F\u7528\u7535\u8111\u7684\u667A\u80FD\u4F53\u8BBE\u8BA1\uFF0C\u4E5F\u4E3A\u5E0C\u671B\u4E3B\u529B Mac \u4FDD\u6301\u5E72\u51C0\u7684\u4EBA\u8BBE\u8BA1\u3002",
    "features.tag1": "\u9694\u79BB",
    "features.title1.card": "\u5B8C\u6574 macOS \u5BA2\u4F53\uFF0C\u5B8C\u5168\u9694\u79BB",
    "features.body1": "\u628A\u667A\u80FD\u4F53\u7684\u684C\u9762\u3001\u6587\u4EF6\u3001\u51ED\u636E\u548C\u6D4F\u89C8\u5668\u72B6\u6001\u4E0E\u4F60\u7684\u65E5\u5E38 Mac \u5206\u79BB\u3002\u5173\u95ED\u7A97\u53E3\u540E\uFF0C\u6C99\u76D2\u4ECD\u53EF\u8FD0\u884C\u3002",
    "features.tag2": "\u5FEB\u901F\u542F\u52A8",
    "features.title2.card": "\u53EF\u76F4\u63A5\u4F7F\u7528\u7684\u955C\u50CF",
    "features.body2": "\u9009\u62E9\u5185\u7F6E\u955C\u50CF\uFF0C\u9996\u4E2A\u6C99\u76D2\u6570\u79D2\u542F\u52A8\uFF0C\u62C9\u53D6\u8FDB\u5EA6\u6309\u5C42\u53EF\u89C1\u3002",
    "features.tag3": "\u5185\u7F6E",
    "features.title3.card": "\u5728\u5E94\u7528\u5185\u8FD0\u884C\u547D\u4EE4",
    "features.body3": "\u6253\u5F00\u7ED1\u5B9A\u5230\u5DE5\u4F5C\u8D1F\u8F7D\u7684\u7EC8\u7AEF\u3002\u65E5\u5FD7\u3001\u9000\u51FA\u7801\u548C\u8BCA\u65AD\u8DEF\u5F84\u90FD\u4F1A\u4FDD\u7559\u3002",
    "features.tag4": "\u53EF\u6062\u590D",
    "features.title4.card": "\u7528\u5B8C\u5373\u4E22",
    "features.body4": "\u542F\u52A8\u3001\u505C\u6B62\u3001\u68C0\u67E5\u3001\u79FB\u9664\u3002\u5B9E\u9A8C\u8BB0\u5F55\u4FDD\u5B58\u5728\u6C99\u76D2\u65E5\u5FD7\u8DEF\u5F84\u4E2D\uFF0C\u76F4\u5230\u4F60\u5220\u9664\u5B83\u3002",
    "features.tag5": "APPLE SILICON",
    "features.title5.card": "\u57FA\u4E8E Apple container \u6808",
    "features.body5": "\u5C01\u88C5 apple/container \u4E0E apple/containerization\u3002\u9762\u5411 macOS 26 \u8FD0\u884C\u65F6\u548C\u539F\u751F\u865A\u62DF\u5316\u3002",
    "features.running": "\u25CF \u8FD0\u884C\u4E2D",
    "flow.eyebrow": "03 \xB7 \u751F\u547D\u5468\u671F",
    "flow.title": "\u5B9E\u65F6\u7BA1\u7406\u6BCF\u4E2A\u6C99\u76D2\u72B6\u6001\u3002",
    "flow.body": "\u5728\u4E00\u4E2A\u754C\u9762\u91CC\u542F\u52A8\u3001\u505C\u6B62\u3001\u68C0\u67E5\u548C\u6062\u590D\u6C99\u76D2\uFF0C\u72B6\u6001\u4E0E\u8BCA\u65AD\u4FE1\u606F\u4F1A\u968F\u5DE5\u4F5C\u8D1F\u8F7D\u5B9E\u65F6\u66F4\u65B0\u3002",
    "flow.new": "\u65B0\u5EFA\u6C99\u76D2",
    "flow.start": "\u542F\u52A8",
    "flow.stop": "\u505C\u6B62",
    "flow.reset": "\u91CD\u7F6E",
    "flow.idle": "\u7A7A\u95F2",
    "flow.creating": "\u521B\u5EFA\u4E2D",
    "flow.pulling": "\u62C9\u53D6\u4E2D",
    "flow.running": "\u8FD0\u884C\u4E2D",
    "flow.stopped": "\u5DF2\u505C\u6B62",
    "flow.idle.note": "\u8FD8\u6CA1\u6709\u6C99\u76D2\u3002",
    "flow.creating.note": "\u6B63\u5728\u5206\u914D\u5BA2\u4F53\u5E76\u51C6\u5907 rootfs\u3002",
    "flow.pulling.note": "\u6B63\u5728\u4ECE ghcr.io \u62C9\u53D6 OCI \u5C42\u3002",
    "flow.running.note": "\u684C\u9762 GUI \u5C31\u7EEA\uFF0C\u547D\u4EE4\u53EF\u7528\u3002",
    "flow.stopped.note": "\u5FEB\u7167\u5DF2\u4FDD\u5B58\uFF0C\u65E5\u5FD7\u5DF2\u4FDD\u7559\u3002",
    "card.empty": "\u7A7A",
    "card.click": "\u70B9\u51FB\u65B0\u5EFA\u6C99\u76D2 \u2191",
    "card.allocating": "\u6B63\u5728\u5206\u914D\u865A\u62DF\u5316\u8BBE\u5907\u2026",
    "card.layer": "\u7B2C 4/6 \u5C42 \xB7 148 MB / 240 MB",
    "card.ready": "\u684C\u9762 GUI \u5C31\u7EEA\u3002",
    "card.saved": "\u5FEB\u7167\u5DF2\u4FDD\u5B58\u3002",
    "card.title": "OpenBox \u6C99\u76D2",
    "card.runCommand": "\u8FD0\u884C\u547D\u4EE4",
    "card.stopSandbox": "\u505C\u6B62\u6C99\u76D2",
    "card.startSandbox": "\u542F\u52A8\u6C99\u76D2",
    "card.remove": "\u79FB\u9664",
    "card.desktopGui": "\u684C\u9762 GUI",
    "card.enabled": "\u5DF2\u542F\u7528",
    "card.workspace": "\u5DE5\u4F5C\u533A",
    "card.notMounted": "\u672A\u6302\u8F7D",
    "terminal.eyebrow": "04 \xB7 \u5185\u7F6E\u7EC8\u7AEF",
    "terminal.title1": "shell \u7ED1\u5B9A\u5230",
    "terminal.titleEm": "\u6C99\u76D2\uFF0C",
    "terminal.title2": "\u4E0D\u662F\u4F60\u7684 Mac\u3002",
    "terminal.body": "\u628A\u4EA4\u4E92\u5F0F\u7EC8\u7AEF\u8FDE\u63A5\u5230\u4EFB\u4F55\u8FD0\u884C\u4E2D\u7684\u6C99\u76D2\u3002\u5DE5\u4F5C\u8D1F\u8F7D\u8F93\u51FA\u4F1A\u88AB\u6355\u83B7\u5E76\u4FDD\u6301\u5728\u5BA2\u4F53\u5185\uFF0C\u5305\u62EC\u7F51\u7EDC\u3001\u6587\u4EF6\u7CFB\u7EDF\u548C\u51ED\u636E\u3002",
    "terminal.item1": "\u6BCF\u6C99\u76D2 PTY",
    "terminal.item1.body": "\u7C7B\u4F3C tmux \u7684\u4F1A\u8BDD\u590D\u7528\u548C\u6062\u590D",
    "terminal.item2": "\u66B4\u9732\u65E5\u5FD7\u8DEF\u5F84",
    "terminal.item2.body": "diagnostic.log \xB7 runtime.log \xB7 kernel.log",
    "terminal.item3": "\u5C0A\u91CD\u4E3B\u673A\u9632\u706B\u5899",
    "terminal.item3.body": "\u5BA2\u4F53\u4E0D\u4F1A\u5411\u4E3B\u673A\u5F00\u653E\u5165\u7AD9 socket",
    "terminal.item4": "\u5FEB\u6377\u952E",
    "terminal.item4.body": "\u2318K \u547D\u4EE4\u9762\u677F \xB7 \u2318\u21E7T \u65B0\u6807\u7B7E \xB7 \u2303C \u4E2D\u65AD",
    "terminal.replay": "\u91CD\u653E\u6F14\u793A",
    "terminal.pause": "\u6682\u505C",
    "terminal.resume": "\u7EE7\u7EED",
    "compat.eyebrow": "05 \xB7 \u517C\u5BB9\u6027",
    "compat.badge": "\u652F\u6301\u76EE\u6807",
    "compat.title": "Apple Silicon Mac",
    "compat.body": "OpenBox \u5DF2\u9488\u5BF9 macOS 26 \u6216\u66F4\u9AD8\u7248\u672C\u9A8C\u8BC1\uFF0C\u652F\u6301 macOS \u5BA2\u4F53\u6C99\u76D2\u548C\u684C\u9762\u7A97\u53E3\u3002",
    "compat.runtime": "\u8FD0\u884C\u65F6\uFF1Acontainer-runtime-macos",
    "compat.source": "\u6E90\u7801\u6784\u5EFA\uFF1AXcode 26+",
    "compat.intel": "Intel Mac\uFF1A\u6682\u4E0D\u652F\u6301",
    "faq.eyebrow": "06 \xB7 FAQ",
    "faq.title1": "\u5E38\u89C1\u95EE\u9898\uFF0C",
    "faq.title2": "\u76F4\u63A5\u56DE\u7B54\u3002",
    "faq.q1": "\u8FD9\u548C Apple \u6709\u5173\u7CFB\u5417\uFF1F",
    "faq.a1": "\u6CA1\u6709\u3002OpenBox \u662F @jianliang00 \u53D1\u8D77\u7684\u72EC\u7ACB\u5F00\u6E90\u9879\u76EE\u3002\u5B83\u5C01\u88C5\u4E86 Apple \u5728 GitHub \u4E0A\u5F00\u6E90\u7684 apple/container \u548C apple/containerization\uFF0C\u4F46 OpenBox \u672C\u8EAB\u5E76\u975E Apple \u6784\u5EFA\u3001\u80CC\u4E66\u6216\u6388\u6743\u3002",
    "faq.q2": "\u6C99\u76D2\u91CC\u53EF\u4EE5\u8FD0\u884C\u4EC0\u4E48\uFF1F",
    "faq.a2": "\u4EFB\u4F55\u80FD\u5728 Apple Silicon \u7684 macOS 26 \u4E0A\u8FD0\u884C\u7684\u5185\u5BB9\uFF0C\u6216\u80FD\u89E3\u6790\u5230 container-runtime-linux \u7684 Linux \u955C\u50CF\u3002\u91CD\u70B9\u662F\u5B8C\u6574 macOS \u5BA2\u4F53\u6C99\u76D2\uFF0C\u5305\u62EC\u684C\u9762\u3001\u952E\u76D8\u3001\u6307\u9488\u548C\u56FE\u5F62\u3002",
    "faq.q3": "\u652F\u6301 Intel Mac \u5417\uFF1F",
    "faq.a3": "\u4E0D\u652F\u6301\u3002Apple Silicon \u662F\u5F53\u524D\u76EE\u6807\u3002\u5E95\u5C42\u6808\u4F9D\u8D56 Apple \u5728 ARM \u786C\u4EF6\u4E0A\u7684\u865A\u62DF\u5316\u6846\u67B6\u3002",
    "faq.q4": "\u9694\u79BB\u7A0B\u5EA6\u5982\u4F55\uFF1F",
    "faq.a4": "\u5BA2\u4F53\u8FD0\u884C\u5728\u81EA\u5DF1\u7684 VM \u4E2D\uFF0C\u62E5\u6709\u72EC\u7ACB\u6587\u4EF6\u7CFB\u7EDF\u3001\u51ED\u636E\u548C\u6D4F\u89C8\u5668\u72B6\u6001\u3002\u4E3B\u673A\u9632\u706B\u5899\u89C4\u5219\u4ECD\u7136\u751F\u6548\uFF1BOpenBox \u9ED8\u8BA4\u4E0D\u4F1A\u4ECE\u5BA2\u4F53\u5411\u4E3B\u673A\u5F00\u653E\u5165\u7AD9 socket\u3002",
    "faq.q5": "\u53EF\u4EE5\u7528\u6765\u8FD0\u884C AI \u667A\u80FD\u4F53\u5417\uFF1F",
    "faq.a5": "\u53EF\u4EE5\uFF0C\u8FD9\u6B63\u662F\u4E3B\u8981\u4F7F\u7528\u573A\u666F\u3002\u4E00\u6B21\u6027 macOS \u73AF\u5883\u9002\u5408\u8BA9\u4F7F\u7528\u7535\u8111\u7684\u667A\u80FD\u4F53\u63A2\u7D22\uFF0C\u800C\u4E0D\u89E6\u78B0\u4F60\u7684\u4E3B\u7CFB\u7EDF\u3002",
    "faq.q6": "\u8BB8\u53EF\u8BC1\u662F\u4EC0\u4E48\uFF1F",
    "faq.a6": "Apache License 2.0\u3002\u53EF\u4EE5 fork\u3001\u5206\u53D1\u3001\u5D4C\u5165\u3002\u53D1\u5E03 DMG \u4F1A\u901A\u8FC7 GitHub Actions \u5728 macOS 26 runner \u4E0A\u7B7E\u540D\u5E76\u516C\u8BC1\u3002",
    "footer.body": "\u7528\u4E8E\u521B\u5EFA\u548C\u7BA1\u7406\u9694\u79BB Mac \u73AF\u5883\u7684\u684C\u9762\u5E94\u7528\u3002\u5F00\u6E90\uFF0CApache 2.0\uFF0C\u7531 @jianliang00 \u548C\u8D21\u732E\u8005\u7EF4\u62A4\u3002",
    "footer.project": "\u9879\u76EE",
    "footer.compat": "\u517C\u5BB9\u6027",
    "footer.license": "\u8BB8\u53EF\u8BC1",
    "footer.releases": "\u53D1\u5E03",
    "footer.latest": "\u6700\u65B0 DMG",
    "footer.changelog": "\u53D8\u66F4\u65E5\u5FD7",
    "footer.actions": "Actions",
    "footer.community": "\u793E\u533A",
    "footer.issues": "GitHub Issues",
    "footer.discussions": "Discussions",
    "footer.source": "\u6E90\u7801",
    "footer.copy": "\xA9 2026 OpenBox contributors \xB7 Apache 2.0",
    "footer.note": "\u4E0E Apple Inc. \u65E0\u96B6\u5C5E\u5173\u7CFB \xB7 0.0.6-alpha"
  }
};
const tr = (key) => {
  var _a, _b, _c;
  const lang = window.__OPENBOX_LANG__ === "zh" ? "zh" : "en";
  return (_c = (_b = (_a = I18N[lang]) == null ? void 0 : _a[key]) != null ? _b : I18N.en[key]) != null ? _c : key;
};
const lines = (key) => tr(key).split("\n").map((line, i) => /* @__PURE__ */ React.createElement(React.Fragment, { key: i }, i > 0 && /* @__PURE__ */ React.createElement("br", null), line));
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
  cursor: "pointer"
};
const Nav = ({ theme = "light", lang = "en", onToggleTheme, onToggleLang }) => {
  const [scrolled, setScrolled] = React.useState(false);
  const compact = useMedia("(max-width: 760px)");
  React.useEffect(() => {
    const on = () => setScrolled(window.scrollY > 12);
    window.addEventListener("scroll", on);
    return () => window.removeEventListener("scroll", on);
  }, []);
  return /* @__PURE__ */ React.createElement("nav", { style: {
    position: "sticky",
    top: 0,
    zIndex: 50,
    background: scrolled ? "color-mix(in oklch, var(--bg) 85%, transparent)" : "transparent",
    backdropFilter: scrolled ? "blur(14px) saturate(140%)" : "none",
    WebkitBackdropFilter: scrolled ? "blur(14px) saturate(140%)" : "none",
    borderBottom: scrolled ? "1px solid var(--line)" : "1px solid transparent",
    transition: "background 160ms ease, border-color 160ms ease"
  } }, /* @__PURE__ */ React.createElement("div", { style: {
    maxWidth: 1280,
    margin: "0 auto",
    padding: compact ? "12px 18px" : "14px 32px",
    display: "flex",
    alignItems: "center",
    gap: compact ? 12 : 28
  } }, /* @__PURE__ */ React.createElement("a", { href: "#top", style: { display: "flex", alignItems: "center", gap: 12, flexShrink: 0 } }, /* @__PURE__ */ React.createElement(Logo, { size: 36, theme }), /* @__PURE__ */ React.createElement("span", { style: { fontWeight: 700, fontSize: 21, letterSpacing: 0, lineHeight: 1 } }, "OpenBox"), !compact && /* @__PURE__ */ React.createElement(Pill, { tone: "ghost", size: "xs", mono: true }, "v0.0.6 \xB7 alpha")), /* @__PURE__ */ React.createElement("div", { style: {
    display: compact ? "none" : "flex",
    gap: 24,
    marginLeft: 24,
    fontSize: 14,
    color: "var(--ink-3)"
  } }, /* @__PURE__ */ React.createElement("a", { href: "#features", style: { color: "inherit" } }, tr("nav.features")), /* @__PURE__ */ React.createElement("a", { href: "#terminal", style: { color: "inherit" } }, tr("nav.terminal")), /* @__PURE__ */ React.createElement("a", { href: "#compat", style: { color: "inherit" } }, tr("nav.compat")), /* @__PURE__ */ React.createElement("a", { href: "#faq", style: { color: "inherit" } }, tr("nav.faq"))), /* @__PURE__ */ React.createElement("div", { style: { flex: 1 } }), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 8 } }, /* @__PURE__ */ React.createElement(
    "button",
    {
      type: "button",
      onClick: onToggleTheme,
      "aria-label": theme === "dark" ? tr("nav.themeToLight") : tr("nav.themeToDark"),
      title: theme === "dark" ? tr("nav.themeToLight") : tr("nav.themeToDark"),
      style: navControlStyle
    },
    theme === "dark" ? tr("nav.light") : tr("nav.dark")
  ), /* @__PURE__ */ React.createElement(
    "button",
    {
      type: "button",
      onClick: onToggleLang,
      "aria-label": tr("nav.langSwitch"),
      title: tr("nav.langSwitch"),
      style: { ...navControlStyle, minWidth: 44 }
    },
    lang === "zh" ? "EN" : "\u4E2D\u6587"
  )), /* @__PURE__ */ React.createElement("a", { href: "https://github.com/jianliang00/open-box", "aria-label": "GitHub", style: {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    width: 34,
    height: 34,
    color: "var(--ink-2)"
  } }, /* @__PURE__ */ React.createElement(Icon, { name: "github", size: 18 }))));
};
const Logo = ({ size = 24, theme }) => /* @__PURE__ */ React.createElement(
  "img",
  {
    src: (theme || document.documentElement.dataset.theme) === "dark" ? "logo-web-dark.png" : "logo-web.png",
    alt: "",
    width: size,
    height: size,
    "aria-hidden": "true",
    draggable: "false",
    style: { display: "block", width: size, height: size }
  }
);
const Hero = () => {
  const compact = useMedia("(max-width: 760px)");
  return /* @__PURE__ */ React.createElement("section", { id: "top", style: { position: "relative", overflow: "hidden" } }, /* @__PURE__ */ React.createElement(Section, { pad: [72, 32], style: { paddingBottom: 48 } }, /* @__PURE__ */ React.createElement("div", { style: {
    display: "flex",
    alignItems: compact ? "flex-start" : "center",
    gap: 12,
    marginBottom: compact ? 34 : 56,
    fontFamily: "var(--font-mono)",
    fontSize: 12,
    color: "var(--ink-4)",
    flexWrap: "wrap"
  } }, /* @__PURE__ */ React.createElement(Pill, { tone: "accent", size: "xs", mono: true }, tr("hero.badge")), /* @__PURE__ */ React.createElement("span", null, tr("hero.strap")), /* @__PURE__ */ React.createElement("a", { href: "https://github.com/jianliang00/open-box/releases/latest", style: { color: "var(--ink-2)", textDecoration: "underline", textDecorationColor: "var(--line-2)", textUnderlineOffset: 3 } }, tr("hero.release"), " \u2192")), /* @__PURE__ */ React.createElement("div", { style: { maxWidth: 980 } }, /* @__PURE__ */ React.createElement("h1", { style: {
    fontFamily: "var(--font-body)",
    fontSize: compact ? "clamp(42px, 13vw, 64px)" : "clamp(52px, 8vw, 104px)",
    lineHeight: 0.96,
    fontWeight: 500,
    letterSpacing: "-0.035em",
    margin: "0 0 28px 0",
    textWrap: "balance"
  } }, tr("hero.title1"), /* @__PURE__ */ React.createElement("br", null), /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400, letterSpacing: "-0.01em" } }, tr("hero.title2"))), /* @__PURE__ */ React.createElement("p", { style: {
    fontSize: compact ? 17 : 20,
    lineHeight: 1.45,
    color: "var(--ink-3)",
    maxWidth: 680,
    margin: "0 0 36px 0",
    fontWeight: 400
  } }, tr("hero.body")), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap", marginBottom: 24 } }, /* @__PURE__ */ React.createElement(Btn, { variant: "accent", size: "lg", icon: "download", href: "https://github.com/jianliang00/open-box/releases/latest" }, tr("hero.download")), /* @__PURE__ */ React.createElement(Btn, { variant: "ghost", size: "lg", icon: "github", iconRight: "arrow-up-right", href: "https://github.com/jianliang00/open-box" }, tr("hero.source")), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "var(--ink-4)", marginLeft: compact ? 0 : 8 } }, /* @__PURE__ */ React.createElement(Icon, { name: "check", size: 14 }), " ", tr("hero.status"))))), /* @__PURE__ */ React.createElement(Section, { pad: [24, 32], style: { paddingTop: 24 } }, /* @__PURE__ */ React.createElement(HeroShowcase, null)), /* @__PURE__ */ React.createElement(Section, { pad: [40, 32], style: { paddingTop: 8, paddingBottom: 40 } }, /* @__PURE__ */ React.createElement("div", { style: {
    display: "grid",
    gridTemplateColumns: compact ? "1fr" : "repeat(4, 1fr)",
    gap: 0,
    borderTop: "1px solid var(--line)",
    borderBottom: "1px solid var(--line)"
  } }, [
    [tr("hero.use1.title"), tr("hero.use1.body")],
    [tr("hero.use2.title"), tr("hero.use2.body")],
    [tr("hero.use3.title"), tr("hero.use3.body")],
    [tr("hero.use4.title"), tr("hero.use4.body")]
  ].map(([k, v], i) => /* @__PURE__ */ React.createElement("div", { key: k, style: {
    padding: "28px 24px",
    borderLeft: !compact && i !== 0 ? "1px solid var(--line)" : "none",
    borderTop: compact && i !== 0 ? "1px solid var(--line)" : "none"
  } }, /* @__PURE__ */ React.createElement("div", { style: { fontFamily: "var(--font-mono)", fontSize: 10.5, letterSpacing: 1.5, color: "var(--ink-4)", marginBottom: 10 } }, String(i + 1).padStart(2, "0"), " \xB7 ", k), /* @__PURE__ */ React.createElement("div", { style: { fontSize: 14, color: "var(--ink-2)", lineHeight: 1.45 } }, v))))));
};
const CopyLine = ({ text }) => {
  const [copied, setCopied] = React.useState(false);
  const copy = () => {
    var _a;
    (_a = navigator.clipboard) == null ? void 0 : _a.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1400);
  };
  return /* @__PURE__ */ React.createElement("button", { onClick: copy, style: {
    display: "inline-flex",
    alignItems: "center",
    gap: 12,
    padding: "10px 14px",
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 10,
    fontFamily: "var(--font-mono)",
    fontSize: 13,
    color: "var(--ink-2)",
    cursor: "pointer"
  } }, /* @__PURE__ */ React.createElement("span", { style: { color: "var(--accent)" } }, "$"), /* @__PURE__ */ React.createElement("span", null, text), /* @__PURE__ */ React.createElement("span", { style: { width: 1, height: 16, background: "var(--line)", margin: "0 4px" } }), /* @__PURE__ */ React.createElement("span", { style: { display: "inline-flex", alignItems: "center", gap: 6, color: "var(--ink-4)", fontSize: 12 } }, /* @__PURE__ */ React.createElement(Icon, { name: copied ? "check" : "copy", size: 13 }), copied ? window.__OPENBOX_LANG__ === "zh" ? "\u5DF2\u590D\u5236" : "copied" : window.__OPENBOX_LANG__ === "zh" ? "\u590D\u5236" : "copy"));
};
const HeroShowcase = () => {
  const [tab, setTab] = React.useState("sandbox");
  const compact = useMedia("(max-width: 760px)");
  const tabs = [
    { id: "sandbox", label: tr("showcase.sandbox"), img: "showcase/openbox-showcase-1.png", cap: tr("showcase.cap1") },
    { id: "desktop", label: tr("showcase.desktop"), img: "showcase/openbox-showcase-2.png", cap: tr("showcase.cap2") },
    { id: "term", label: tr("showcase.term"), img: "showcase/openbox-showcase-3.png", cap: tr("showcase.cap3") }
  ];
  const active = tabs.find((t) => t.id === tab);
  return /* @__PURE__ */ React.createElement("div", { style: { position: "relative" } }, !compact && /* @__PURE__ */ React.createElement(React.Fragment, null, /* @__PURE__ */ React.createElement(
    Annotation,
    {
      style: { top: 60, left: -4 },
      label: "01",
      text: lines("showcase.a1")
    }
  ), /* @__PURE__ */ React.createElement(
    Annotation,
    {
      style: { top: 260, right: -8, textAlign: "right", alignItems: "flex-end" },
      label: "02",
      text: lines("showcase.a2")
    }
  ), /* @__PURE__ */ React.createElement(
    Annotation,
    {
      style: { bottom: -12, left: "30%" },
      label: "03",
      text: lines("showcase.a3")
    }
  )), /* @__PURE__ */ React.createElement("div", { style: {
    display: "flex",
    gap: 6,
    marginBottom: 14,
    padding: 4,
    background: "var(--bg-2)",
    border: "1px solid var(--line)",
    borderRadius: 10,
    width: compact ? "100%" : "fit-content",
    overflowX: "auto"
  } }, tabs.map((t) => /* @__PURE__ */ React.createElement("button", { key: t.id, onClick: () => setTab(t.id), "aria-pressed": tab === t.id, style: {
    padding: "7px 14px",
    fontFamily: "var(--font-mono)",
    fontSize: 12,
    background: tab === t.id ? "var(--surface)" : "transparent",
    border: tab === t.id ? "1px solid var(--line)" : "1px solid transparent",
    borderRadius: 7,
    cursor: "pointer",
    color: tab === t.id ? "var(--ink)" : "var(--ink-3)",
    boxShadow: tab === t.id ? "0 1px 1px rgba(0,0,0,0.04)" : "none"
  } }, /* @__PURE__ */ React.createElement("span", { style: { color: "var(--ink-4)", marginRight: 8 } }, t.id), t.label))), /* @__PURE__ */ React.createElement("div", { style: {
    maxWidth: 1180,
    overflow: "hidden",
    border: "1px solid var(--line)",
    borderRadius: 12,
    boxShadow: "0 1px 1px rgba(0,0,0,0.02), 0 10px 30px rgba(0,0,0,0.08), 0 40px 80px rgba(0,0,0,0.08)"
  } }, /* @__PURE__ */ React.createElement("div", { style: { position: "relative", aspectRatio: "2940/1716", background: "#f5f5f7" } }, /* @__PURE__ */ React.createElement(
    "img",
    {
      src: active.img,
      alt: active.label,
      style: { width: "100%", height: "100%", objectFit: "cover", display: "block" }
    }
  ))), /* @__PURE__ */ React.createElement("div", { style: {
    marginTop: 14,
    display: "flex",
    justifyContent: "space-between",
    gap: 8,
    flexDirection: compact ? "column" : "row",
    fontFamily: "var(--font-mono)",
    fontSize: 12,
    color: "var(--ink-4)"
  } }, /* @__PURE__ */ React.createElement("span", null, "fig. ", tabs.findIndex((t) => t.id === tab) + 1, " \u2014 ", active.cap), /* @__PURE__ */ React.createElement("span", null, tabs.findIndex((t) => t.id === tab) + 1, "/", tabs.length)));
};
const Annotation = ({ style, label, text }) => /* @__PURE__ */ React.createElement("div", { style: {
  position: "absolute",
  zIndex: 2,
  display: "flex",
  flexDirection: "column",
  gap: 6,
  fontFamily: "var(--font-mono)",
  fontSize: 11,
  color: "var(--ink-3)",
  pointerEvents: "none",
  ...style
} }, /* @__PURE__ */ React.createElement("span", { style: {
  width: 22,
  height: 22,
  borderRadius: "50%",
  display: "inline-flex",
  alignItems: "center",
  justifyContent: "center",
  background: "var(--ink)",
  color: "#fff",
  fontSize: 10,
  fontWeight: 600
} }, label), /* @__PURE__ */ React.createElement("span", null, text));
const Features = () => {
  const compact = useMedia("(max-width: 760px)");
  const medium = useMedia("(max-width: 1020px)");
  const items = [
    {
      icon: "box",
      tag: tr("features.tag1"),
      title: tr("features.title1.card"),
      body: tr("features.body1"),
      big: true
    },
    {
      icon: "bolt",
      tag: tr("features.tag2"),
      title: tr("features.title2.card"),
      body: tr("features.body2")
    },
    {
      icon: "terminal",
      tag: tr("features.tag3"),
      title: tr("features.title3.card"),
      body: tr("features.body3")
    },
    {
      icon: "layers",
      tag: tr("features.tag4"),
      title: tr("features.title4.card"),
      body: tr("features.body4")
    },
    {
      icon: "chip",
      tag: tr("features.tag5"),
      title: tr("features.title5.card"),
      body: tr("features.body5")
    }
  ];
  return /* @__PURE__ */ React.createElement(Section, { id: "features", eyebrow: tr("features.eyebrow") }, /* @__PURE__ */ React.createElement("div", { style: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-end",
    gap: 24,
    marginBottom: 48,
    flexWrap: "wrap"
  } }, /* @__PURE__ */ React.createElement("h2", { style: {
    fontSize: "clamp(40px, 5vw, 64px)",
    fontWeight: 500,
    letterSpacing: "-0.03em",
    lineHeight: 1,
    margin: 0,
    maxWidth: 720,
    textWrap: "balance"
  } }, tr("features.title1"), " ", /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 } }, tr("features.titleEm")), " ", tr("features.title2")), /* @__PURE__ */ React.createElement("p", { style: { color: "var(--ink-3)", fontSize: 15, maxWidth: 360, margin: 0, lineHeight: 1.5 } }, tr("features.body"))), /* @__PURE__ */ React.createElement("div", { style: {
    display: "grid",
    gridTemplateColumns: compact ? "1fr" : medium ? "repeat(2, 1fr)" : "repeat(6, 1fr)",
    gridAutoRows: "minmax(220px, auto)",
    gap: 0,
    border: "1px solid var(--line)",
    borderRadius: 14,
    overflow: "hidden",
    background: "var(--surface)"
  } }, items.map((it, i) => /* @__PURE__ */ React.createElement(FeatureCell, { key: i, ...it, index: i }))));
};
const FeatureCell = ({ icon, tag, title, body, big, index }) => {
  const compact = useMedia("(max-width: 760px)");
  const medium = useMedia("(max-width: 1020px)");
  const layouts = [
    { gridColumn: "span 3", gridRow: "span 2" },
    // big left
    { gridColumn: "span 3" },
    { gridColumn: "span 3" },
    { gridColumn: "span 3" },
    { gridColumn: "span 3" }
  ];
  const layout = compact ? { gridColumn: "span 1", gridRow: "span 1" } : medium ? { gridColumn: big ? "span 2" : "span 1", gridRow: "span 1" } : layouts[index] || {};
  return /* @__PURE__ */ React.createElement("div", { style: {
    ...layout,
    padding: 28,
    borderLeft: "1px solid var(--line)",
    borderTop: "1px solid var(--line)",
    marginLeft: -1,
    marginTop: -1,
    display: "flex",
    flexDirection: "column",
    gap: 14,
    position: "relative"
  } }, /* @__PURE__ */ React.createElement("div", { style: {
    fontFamily: "var(--font-mono)",
    fontSize: 11,
    letterSpacing: 1.2,
    color: "var(--ink-4)",
    display: "flex",
    alignItems: "center",
    gap: 8
  } }, /* @__PURE__ */ React.createElement("span", { style: {
    width: 28,
    height: 28,
    borderRadius: 7,
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    background: big ? "var(--accent)" : "var(--bg-2)",
    color: big ? "#fff" : "var(--ink-2)"
  } }, /* @__PURE__ */ React.createElement(Icon, { name: icon, size: 15 })), /* @__PURE__ */ React.createElement("span", null, tag)), /* @__PURE__ */ React.createElement("h3", { style: {
    fontSize: big ? 30 : 20,
    fontWeight: 500,
    margin: 0,
    letterSpacing: "-0.015em",
    lineHeight: 1.15,
    maxWidth: big ? 480 : "none"
  } }, title), /* @__PURE__ */ React.createElement("p", { style: {
    color: "var(--ink-3)",
    fontSize: big ? 15 : 14,
    lineHeight: 1.55,
    margin: 0,
    maxWidth: 480
  } }, body), big && /* @__PURE__ */ React.createElement(FeatureIllustration, null));
};
const FeatureIllustration = () => /* @__PURE__ */ React.createElement("div", { style: {
  marginTop: "auto",
  padding: 20,
  background: "var(--bg)",
  border: "1px dashed var(--line-2)",
  borderRadius: 10,
  display: "flex",
  gap: 14,
  alignItems: "center"
} }, /* @__PURE__ */ React.createElement("div", { style: {
  width: 46,
  height: 46,
  borderRadius: 10,
  background: "var(--ink)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center"
} }, /* @__PURE__ */ React.createElement(Icon, { name: "box", size: 20, stroke: 1.4, style: { color: "#fff" } })), /* @__PURE__ */ React.createElement("div", { style: { flex: 1 } }, /* @__PURE__ */ React.createElement("div", { style: { fontSize: 13, fontWeight: 500, marginBottom: 3 } }, "openbox-dev-agent"), /* @__PURE__ */ React.createElement("div", { style: { fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-4)" } }, "ghcr.io/jianliang00/macos-dev-agent:26.3")), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", flexDirection: "column", gap: 6, alignItems: "flex-end" } }, /* @__PURE__ */ React.createElement(Pill, { tone: "good", size: "xs" }, tr("features.running")), /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-mono)", fontSize: 10.5, color: "var(--ink-4)" } }, "up 14m \xB7 4 vCPU / 8GB")));
const Flow = () => {
  const [state, setState] = React.useState("idle");
  const compact = useMedia("(max-width: 760px)");
  const states = [
    { id: "idle", label: tr("flow.idle"), color: "var(--ink-4)", note: tr("flow.idle.note") },
    { id: "creating", label: tr("flow.creating"), color: "var(--warn)", note: tr("flow.creating.note") },
    { id: "pulling", label: tr("flow.pulling"), color: "var(--accent)", note: tr("flow.pulling.note") },
    { id: "running", label: tr("flow.running"), color: "var(--good)", note: tr("flow.running.note") },
    { id: "stopped", label: tr("flow.stopped"), color: "var(--ink-3)", note: tr("flow.stopped.note") }
  ];
  const idx = states.findIndex((s) => s.id === state);
  React.useEffect(() => {
    if (state === "running" || state === "stopped" || state === "idle") return;
    const t = setTimeout(() => {
      if (state === "creating") setState("pulling");
      else if (state === "pulling") setState("running");
    }, 1400);
    return () => clearTimeout(t);
  }, [state]);
  return /* @__PURE__ */ React.createElement(Section, { id: "lifecycle", eyebrow: tr("flow.eyebrow") }, /* @__PURE__ */ React.createElement("div", { style: { display: "grid", gridTemplateColumns: compact ? "1fr" : "1.1fr 1fr", gap: compact ? 32 : 48, alignItems: "center" } }, /* @__PURE__ */ React.createElement("div", null, /* @__PURE__ */ React.createElement("h2", { style: {
    fontSize: "clamp(36px, 4.5vw, 56px)",
    fontWeight: 500,
    letterSpacing: "-0.025em",
    lineHeight: 1.05,
    margin: "0 0 20px 0",
    textWrap: "balance"
  } }, tr("flow.title")), /* @__PURE__ */ React.createElement("p", { style: { color: "var(--ink-3)", fontSize: 16, lineHeight: 1.55, margin: "0 0 28px 0", maxWidth: 480 } }, tr("flow.body")), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", gap: 10, marginBottom: 20, flexWrap: "wrap" } }, /* @__PURE__ */ React.createElement(Btn, { variant: "accent", size: "sm", icon: "plus", onClick: () => setState("creating") }, tr("flow.new")), /* @__PURE__ */ React.createElement(Btn, { variant: "ghost", size: "sm", icon: state === "running" ? "stop" : "play", onClick: () => setState(state === "running" ? "stopped" : "running"), disabled: state === "creating" || state === "pulling" }, state === "running" ? tr("flow.stop") : tr("flow.start")), /* @__PURE__ */ React.createElement(Btn, { variant: "ghost", size: "sm", onClick: () => setState("idle") }, tr("flow.reset"))), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", flexDirection: "column", gap: 0 } }, states.map((s, i) => {
    const active = s.id === state;
    const past = i < idx;
    return /* @__PURE__ */ React.createElement("div", { key: s.id, style: {
      display: "flex",
      gap: 14,
      alignItems: "center",
      padding: "10px 0",
      borderTop: i === 0 ? "1px solid var(--line)" : "none",
      borderBottom: "1px solid var(--line)",
      opacity: active ? 1 : 0.55
    } }, /* @__PURE__ */ React.createElement("span", { style: {
      fontFamily: "var(--font-mono)",
      fontSize: 10.5,
      color: "var(--ink-4)",
      width: 22
    } }, "0", i + 1), /* @__PURE__ */ React.createElement("span", { style: {
      width: 10,
      height: 10,
      borderRadius: "50%",
      background: active ? s.color : past ? "var(--ink-3)" : "var(--line-2)",
      boxShadow: active ? `0 0 0 4px color-mix(in oklch, ${s.color} 20%, transparent)` : "none",
      transition: "all 200ms"
    } }), /* @__PURE__ */ React.createElement("span", { style: { fontSize: 14, fontWeight: active ? 500 : 400, width: 90 } }, s.label), /* @__PURE__ */ React.createElement("span", { style: { fontSize: 13, color: "var(--ink-3)", fontFamily: "var(--font-mono)", flex: 1 } }, s.note));
  }))), /* @__PURE__ */ React.createElement(SandboxCard, { state })));
};
const SandboxCard = ({ state }) => {
  const compact = useMedia("(max-width: 760px)");
  const map = {
    idle: { pill: [tr("card.empty"), "var(--ink-3)", "var(--bg-2)"], progress: 0, body: tr("card.click") },
    creating: { pill: [tr("flow.creating"), "var(--warn)", "oklch(0.95 0.04 60)"], progress: 15, body: tr("card.allocating") },
    pulling: { pill: [tr("flow.pulling"), "var(--accent)", "var(--accent-bg)"], progress: 62, body: tr("card.layer") },
    running: { pill: [tr("flow.running"), "var(--good)", "var(--good-bg)"], progress: 100, body: tr("card.ready") },
    stopped: { pill: [tr("flow.stopped"), "var(--ink-3)", "var(--bg-2)"], progress: 0, body: tr("card.saved") }
  };
  const m = map[state];
  return /* @__PURE__ */ React.createElement(MacWindow, { title: "OpenBox \u2014 openbox-sandbox-376036f9", style: { borderRadius: 12 } }, /* @__PURE__ */ React.createElement("div", { style: { padding: 24, background: "var(--surface)" } }, /* @__PURE__ */ React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 12, marginBottom: 20 } }, /* @__PURE__ */ React.createElement("div", { style: {
    width: 44,
    height: 44,
    borderRadius: 10,
    background: "var(--ink)",
    color: "#fff",
    display: "flex",
    alignItems: "center",
    justifyContent: "center"
  } }, /* @__PURE__ */ React.createElement(Icon, { name: "box", size: 20 })), /* @__PURE__ */ React.createElement("div", { style: { flex: 1 } }, /* @__PURE__ */ React.createElement("div", { style: { fontSize: 16, fontWeight: 600 } }, tr("card.title")), /* @__PURE__ */ React.createElement("div", { style: { fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-4)" } }, "openbox-openbox-sandbox-376036f9")), /* @__PURE__ */ React.createElement("span", { style: {
    display: "inline-flex",
    alignItems: "center",
    gap: 6,
    padding: "4px 10px",
    borderRadius: 999,
    background: m.pill[2],
    color: m.pill[1],
    border: `1px solid color-mix(in oklch, ${m.pill[1]} 30%, transparent)`,
    fontSize: 11.5,
    fontWeight: 500
  } }, /* @__PURE__ */ React.createElement("span", { style: { width: 6, height: 6, borderRadius: "50%", background: m.pill[1] } }), m.pill[0])), /* @__PURE__ */ React.createElement("div", { style: {
    height: 6,
    background: "var(--bg-2)",
    borderRadius: 6,
    overflow: "hidden",
    marginBottom: 10
  } }, /* @__PURE__ */ React.createElement("div", { style: {
    width: `${m.progress}%`,
    height: "100%",
    background: state === "running" ? "var(--good)" : state === "pulling" ? "var(--accent)" : "var(--warn)",
    transition: "width 700ms ease, background 300ms"
  } })), /* @__PURE__ */ React.createElement("div", { style: { fontFamily: "var(--font-mono)", fontSize: 11.5, color: "var(--ink-3)", marginBottom: 20 } }, m.body), /* @__PURE__ */ React.createElement("div", { style: {
    display: "grid",
    gridTemplateColumns: compact ? "1fr" : "1fr 1fr",
    gap: 0,
    border: "1px solid var(--line)",
    borderRadius: 8,
    fontSize: 12.5,
    background: "var(--surface)"
  } }, [
    ["OCI Image", "ghcr.io/jianliang00/\nmacos-dev-agent:26.3", true],
    ["Runtime", "container-runtime-macos"],
    ["Platform", "darwin/arm64"],
    ["Resources", "4 vCPU \xB7 8GB RAM"],
    [tr("card.desktopGui"), state === "running" ? `${tr("card.enabled")} \u2713` : tr("card.enabled")],
    [tr("card.workspace"), tr("card.notMounted")]
  ].map(([k, v, mono], i) => /* @__PURE__ */ React.createElement("div", { key: k, style: {
    padding: "10px 14px",
    borderTop: compact ? i === 0 ? "none" : "1px solid var(--line)" : i >= 2 ? "1px solid var(--line)" : "none",
    borderLeft: !compact && i % 2 === 1 ? "1px solid var(--line)" : "none"
  } }, /* @__PURE__ */ React.createElement("div", { style: { fontFamily: "var(--font-mono)", fontSize: 10, letterSpacing: 1.2, color: "var(--ink-4)", marginBottom: 3 } }, k.toUpperCase()), /* @__PURE__ */ React.createElement("div", { style: {
    fontFamily: mono ? "var(--font-mono)" : "var(--font-body)",
    fontSize: mono ? 11.5 : 12.5,
    color: mono ? "var(--accent)" : "var(--ink-2)",
    whiteSpace: mono ? "pre" : "normal",
    lineHeight: 1.3
  } }, v)))), /* @__PURE__ */ React.createElement("div", { style: { display: "flex", gap: 8, marginTop: 16, flexWrap: "wrap" } }, /* @__PURE__ */ React.createElement(Btn, { variant: "soft", size: "sm", icon: "terminal", disabled: state !== "running" }, tr("card.runCommand")), /* @__PURE__ */ React.createElement(Btn, { variant: state === "running" ? "soft" : "accent", size: "sm", icon: state === "running" ? "stop" : "play" }, state === "running" ? tr("card.stopSandbox") : tr("card.startSandbox")), /* @__PURE__ */ React.createElement("div", { style: { flex: 1 } }), /* @__PURE__ */ React.createElement(Btn, { variant: "ghost", size: "sm" }, tr("card.remove")))));
};
const TerminalDemo = () => {
  const compact = useMedia("(max-width: 760px)");
  const script = [
    { t: "prompt", text: "sw_vers" },
    { t: "out", text: "ProductName:    macOS\nProductVersion: 26.3\nBuildVersion:   25E205" },
    { t: "prompt", text: "whoami && hostname" },
    { t: "out", text: "sandbox\nopenbox-sandbox-376036f9" },
    { t: "prompt", text: "# run the agent \u2014 fully isolated" },
    { t: "prompt", text: "codex --dangerously-bypass-approvals 'play me a focus mix'" },
    { t: "out", text: "\u2192 Opening Safari in the guest desktop\u2026\n\u2192 Searching YouTube for 'deep focus music'\u2026\n\u2192 Started playlist. You can close this window." },
    { t: "prompt", text: "\u2588" }
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
      const tm = setTimeout(() => setCharIdx((c) => c + 1), speed + Math.random() * 20);
      return () => clearTimeout(tm);
    } else {
      const pause = line.t === "out" ? 400 : 240;
      const tm = setTimeout(() => {
        setLineIdx((i) => i + 1);
        setCharIdx(0);
      }, pause);
      return () => clearTimeout(tm);
    }
  }, [lineIdx, charIdx, running]);
  const restart = () => {
    setLineIdx(0);
    setCharIdx(0);
    setRunning(true);
  };
  const rendered = script.slice(0, lineIdx + 1).map((line, i) => {
    const text = i === lineIdx ? line.text.slice(0, charIdx) : line.text;
    return { ...line, text, complete: i < lineIdx };
  });
  return /* @__PURE__ */ React.createElement(Section, { id: "terminal", eyebrow: tr("terminal.eyebrow") }, /* @__PURE__ */ React.createElement("div", { style: { display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 1.3fr", gap: compact ? 32 : 48, alignItems: "center" } }, /* @__PURE__ */ React.createElement("div", null, /* @__PURE__ */ React.createElement("h2", { style: {
    fontSize: "clamp(36px, 4.5vw, 56px)",
    fontWeight: 500,
    letterSpacing: "-0.025em",
    lineHeight: 1.05,
    margin: "0 0 20px 0"
  } }, tr("terminal.title1"), " ", /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 } }, tr("terminal.titleEm")), " ", tr("terminal.title2")), /* @__PURE__ */ React.createElement("p", { style: { color: "var(--ink-3)", fontSize: 16, lineHeight: 1.55, margin: "0 0 24px 0", maxWidth: 480 } }, tr("terminal.body")), /* @__PURE__ */ React.createElement("ul", { style: { margin: 0, padding: 0, listStyle: "none", display: "flex", flexDirection: "column", gap: 10 } }, [
    [tr("terminal.item1"), tr("terminal.item1.body")],
    [tr("terminal.item2"), tr("terminal.item2.body")],
    [tr("terminal.item3"), tr("terminal.item3.body")],
    [tr("terminal.item4"), tr("terminal.item4.body")]
  ].map(([k, v]) => /* @__PURE__ */ React.createElement("li", { key: k, style: { display: "flex", alignItems: "baseline", gap: 12, fontSize: 14, color: "var(--ink-2)" } }, /* @__PURE__ */ React.createElement(Icon, { name: "check", size: 14, style: { color: "var(--accent)", flexShrink: 0 } }), /* @__PURE__ */ React.createElement("span", null, /* @__PURE__ */ React.createElement("b", { style: { fontWeight: 600 } }, k), " \u2014 ", /* @__PURE__ */ React.createElement("span", { style: { color: "var(--ink-3)" } }, v))))), /* @__PURE__ */ React.createElement("div", { style: { marginTop: 28, display: "flex", gap: 8 } }, /* @__PURE__ */ React.createElement(Btn, { variant: "soft", size: "sm", onClick: restart, icon: "play" }, tr("terminal.replay")), /* @__PURE__ */ React.createElement(Btn, { variant: "ghost", size: "sm", onClick: () => setRunning((r) => !r), icon: running ? "stop" : "play" }, running ? tr("terminal.pause") : tr("terminal.resume")))), /* @__PURE__ */ React.createElement(MacWindow, { tone: "dark", title: "zsh \u2014 openbox-sandbox-376036f9", style: { height: compact ? 380 : 460 } }, /* @__PURE__ */ React.createElement("div", { style: {
    padding: "18px 22px",
    fontFamily: "var(--font-mono)",
    fontSize: 13,
    color: "#e7e5de",
    height: "100%",
    overflowY: "auto",
    lineHeight: 1.5,
    background: "#1c1b18"
  } }, rendered.map((ln, i) => /* @__PURE__ */ React.createElement("div", { key: i, style: { whiteSpace: "pre-wrap" } }, ln.t === "prompt" ? /* @__PURE__ */ React.createElement(React.Fragment, null, /* @__PURE__ */ React.createElement("span", { style: { color: "var(--accent)" } }, "sandbox"), /* @__PURE__ */ React.createElement("span", { style: { color: "#9a968a" } }, " ~ "), /* @__PURE__ */ React.createElement("span", { style: { color: "#f0b93f" } }, "$"), " ", /* @__PURE__ */ React.createElement("span", { style: { color: ln.text.startsWith("#") ? "#7f7a6e" : "#f7f5ef" } }, ln.text)) : /* @__PURE__ */ React.createElement("span", { style: { color: "#c3bfb3" } }, ln.text)))))));
};
const Compat = () => {
  const compact = useMedia("(max-width: 760px)");
  return /* @__PURE__ */ React.createElement(Section, { id: "compat", eyebrow: tr("compat.eyebrow"), style: { paddingTop: 80, paddingBottom: 72 } }, /* @__PURE__ */ React.createElement("div", { style: {
    display: "flex",
    flexDirection: compact ? "column" : "row",
    alignItems: compact ? "flex-start" : "center",
    justifyContent: "space-between",
    gap: compact ? 22 : 40,
    padding: compact ? "24px 22px" : "30px 34px",
    background: "var(--surface)",
    border: "1px solid var(--line)",
    borderRadius: 12,
    boxShadow: "0 16px 40px rgba(0,0,0,0.05)"
  } }, /* @__PURE__ */ React.createElement("div", null, /* @__PURE__ */ React.createElement(Pill, { tone: "good", size: "xs" }, tr("compat.badge")), /* @__PURE__ */ React.createElement("h2", { style: {
    fontSize: "clamp(28px, 3.4vw, 42px)",
    fontWeight: 600,
    letterSpacing: 0,
    lineHeight: 1.08,
    margin: "14px 0 10px 0"
  } }, tr("compat.title")), /* @__PURE__ */ React.createElement("p", { style: { color: "var(--ink-3)", fontSize: 15, lineHeight: 1.55, margin: 0, maxWidth: 620 } }, tr("compat.body"))), /* @__PURE__ */ React.createElement("div", { style: {
    fontFamily: "var(--font-mono)",
    fontSize: 12,
    lineHeight: 1.8,
    color: "var(--ink-3)",
    minWidth: compact ? "auto" : 280
  } }, tr("compat.runtime"), /* @__PURE__ */ React.createElement("br", null), tr("compat.source"), /* @__PURE__ */ React.createElement("br", null), tr("compat.intel"))));
};
const FAQ = () => {
  const compact = useMedia("(max-width: 760px)");
  const items = [
    [tr("faq.q1"), tr("faq.a1")],
    [tr("faq.q2"), tr("faq.a2")],
    [tr("faq.q3"), tr("faq.a3")],
    [tr("faq.q4"), tr("faq.a4")],
    [tr("faq.q5"), tr("faq.a5")],
    [tr("faq.q6"), tr("faq.a6")]
  ];
  const [open, setOpen] = React.useState(0);
  return /* @__PURE__ */ React.createElement(Section, { id: "faq", eyebrow: tr("faq.eyebrow"), style: { paddingTop: 60 } }, /* @__PURE__ */ React.createElement("div", { style: { display: "grid", gridTemplateColumns: compact ? "1fr" : "1fr 2fr", gap: compact ? 28 : 48 } }, /* @__PURE__ */ React.createElement("h2", { style: {
    fontSize: "clamp(36px, 4.5vw, 56px)",
    fontWeight: 500,
    letterSpacing: "-0.025em",
    lineHeight: 1,
    margin: 0
  } }, tr("faq.title1"), " ", /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-serif)", fontStyle: "italic", fontWeight: 400 } }, tr("faq.title2"))), /* @__PURE__ */ React.createElement("div", { style: { borderTop: "1px solid var(--line)" } }, items.map(([q, a], i) => /* @__PURE__ */ React.createElement("div", { key: i, style: { borderBottom: "1px solid var(--line)" } }, /* @__PURE__ */ React.createElement(
    "button",
    {
      onClick: () => setOpen(open === i ? -1 : i),
      "aria-expanded": open === i,
      "aria-controls": `faq-answer-${i}`,
      style: {
        width: "100%",
        padding: compact ? "18px 0" : "22px 0",
        display: "flex",
        alignItems: "center",
        gap: 20,
        background: "transparent",
        border: "none",
        cursor: "pointer",
        textAlign: "left",
        fontFamily: "var(--font-body)",
        color: "var(--ink)"
      }
    },
    /* @__PURE__ */ React.createElement("span", { style: { fontFamily: "var(--font-mono)", fontSize: 12, color: "var(--ink-4)", width: 28 } }, String(i + 1).padStart(2, "0")),
    /* @__PURE__ */ React.createElement("span", { style: { fontSize: 17, fontWeight: 500, flex: 1 } }, q),
    /* @__PURE__ */ React.createElement(Icon, { name: "plus", size: 16, style: {
      transform: open === i ? "rotate(45deg)" : "rotate(0)",
      transition: "transform 200ms ease"
    } })
  ), /* @__PURE__ */ React.createElement("div", { id: `faq-answer-${i}`, style: {
    maxHeight: open === i ? 300 : 0,
    overflow: "hidden",
    transition: "max-height 260ms ease"
  } }, /* @__PURE__ */ React.createElement("p", { style: {
    paddingLeft: compact ? 0 : 48,
    paddingBottom: 22,
    margin: 0,
    color: "var(--ink-3)",
    fontSize: 15,
    lineHeight: 1.6,
    maxWidth: 680
  } }, a)))))));
};
const Footer = () => {
  const compact = useMedia("(max-width: 760px)");
  const groups = [
    [tr("footer.project"), [
      ["README", "https://github.com/jianliang00/open-box#readme"],
      [tr("footer.compat"), "COMPATIBILITY.md"],
      [tr("footer.license"), "https://github.com/jianliang00/open-box/blob/main/LICENSE"]
    ]],
    [tr("footer.releases"), [
      [tr("footer.latest"), "https://github.com/jianliang00/open-box/releases/latest"],
      [tr("footer.changelog"), "https://github.com/jianliang00/open-box/releases/tag/0.0.6"],
      [tr("footer.actions"), "https://github.com/jianliang00/open-box/actions"]
    ]],
    [tr("footer.community"), [
      [tr("footer.issues"), "https://github.com/jianliang00/open-box/issues"],
      [tr("footer.discussions"), "https://github.com/jianliang00/open-box/discussions"],
      [tr("footer.source"), "https://github.com/jianliang00/open-box"]
    ]]
  ];
  return /* @__PURE__ */ React.createElement("footer", { style: {
    borderTop: "1px solid var(--line)",
    padding: compact ? "42px 18px 28px" : "56px 32px 32px",
    maxWidth: 1280,
    margin: "0 auto"
  } }, /* @__PURE__ */ React.createElement("div", { style: { display: "grid", gridTemplateColumns: compact ? "1fr" : "2fr 1fr 1fr 1fr", gap: compact ? 28 : 48, marginBottom: 48 } }, /* @__PURE__ */ React.createElement("div", null, /* @__PURE__ */ React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 12, marginBottom: 14 } }, /* @__PURE__ */ React.createElement(Logo, { size: 32 }), /* @__PURE__ */ React.createElement("span", { style: { fontWeight: 700, fontSize: 20, lineHeight: 1 } }, "OpenBox")), /* @__PURE__ */ React.createElement("p", { style: { color: "var(--ink-3)", fontSize: 13.5, lineHeight: 1.55, maxWidth: 340, margin: 0 } }, tr("footer.body"))), groups.map(([title, links]) => /* @__PURE__ */ React.createElement("div", { key: title }, /* @__PURE__ */ React.createElement("div", { style: { fontFamily: "var(--font-mono)", fontSize: 11, letterSpacing: 1.2, color: "var(--ink-4)", marginBottom: 14 } }, title.toUpperCase()), /* @__PURE__ */ React.createElement("ul", { style: { listStyle: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: 8 } }, links.map(([label, href]) => /* @__PURE__ */ React.createElement("li", { key: label }, /* @__PURE__ */ React.createElement("a", { href, style: { color: "var(--ink-2)", fontSize: 14 } }, label))))))), /* @__PURE__ */ React.createElement("div", { style: {
    paddingTop: 24,
    borderTop: "1px solid var(--line)",
    display: "flex",
    justifyContent: "space-between",
    gap: 12,
    flexDirection: compact ? "column" : "row",
    fontFamily: "var(--font-mono)",
    fontSize: 11.5,
    color: "var(--ink-4)"
  } }, /* @__PURE__ */ React.createElement("span", null, tr("footer.copy")), /* @__PURE__ */ React.createElement("span", null, tr("footer.note"))));
};
Object.assign(window, { Nav, Hero, Features, Flow, TerminalDemo, Compat, FAQ, Footer, Logo });
