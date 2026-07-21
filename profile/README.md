<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/logo-dark.svg" />
    <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/logo.svg" width="420" alt="clever [cc] plugins" />
  </picture>
</p>

<p align="center">
  <a href="#plugins">Plugins</a> ·
  <a href="#principles">Principles</a> ·
  <a href="#install">Install</a> ·
  <a href="https://github.com/clever-cc-plugins/marketplace">Marketplace repo ↗</a>
</p>

<p align="center">
  A small family of MIT-licensed plugins for Claude Code, authored by Michael van Laar —<br />
  opinionated, dogfood-tested, and built around one rule: every line costs tokens on every message.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/plugins-5-F97316?style=flat-square&labelColor=404040" alt="5 plugins" />
  <img src="https://img.shields.io/badge/skills-34-F97316?style=flat-square&labelColor=404040" alt="34 skills" />
  <img src="https://img.shields.io/badge/license-MIT-404040?style=flat-square" alt="MIT License" />
</p>

---

## Plugins

Each plugin lives in its own repo and ships through this marketplace. No plugin has a version number — they auto-update straight from `main`, per [Claude Code's own recommendation](https://code.claude.com/docs/en/plugins.md) for actively-iterated plugins.

| Plugin                                                            | For              | What it does                                                                                                                                                                 |
| ----------------------------------------------------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**cc-config**](https://github.com/clever-cc-plugins/cc-config)   | _for developers_ | Bootstrap and audit a best-practice Claude Code configuration — hardened permissions, formatter hooks, cost-optimization defaults.                                           |
| [**cc-concept**](https://github.com/clever-cc-plugins/cc-concept) | _for marketers_  | The strategic frame before the content — positioning, campaign concepts, channel strategy, content strategy, and go-to-market that `cc-content` skills then execute against. |
| [**cc-content**](https://github.com/clever-cc-plugins/cc-content) | _for marketers_  | A content studio in slash commands — brand onboarding, LinkedIn drafts, blog articles, sample curation, and more.                                                            |
| [**cc-handoff**](https://github.com/clever-cc-plugins/cc-handoff) | _for developers_ | Hand work off between machines or sessions — writes a `HANDOFF.md` snapshot and wires the pickup convention into `CLAUDE.md`.                                                |
| [**cc-chime**](https://github.com/clever-cc-plugins/cc-chime)     | _ambient_        | Audio cues when Claude finishes a turn or needs your input. No commands — it just runs.                                                                                      |

- **cc-config** — `/cc-config-init` · `/cc-config-optimize`
- **cc-concept** — `/cc-concept-onboarding` · `/cc-concept-positioning` · `/cc-concept-campaign-concept` · `/cc-concept-gtm` · +9 more
- **cc-content** — `/cc-content-onboarding` · `/cc-content-linkedin-post` · `/cc-content-blog-article` · `/cc-content-samples-curation` · `/cc-content-session-wrap` · +12 more
- **cc-handoff** — `/handoff` · `/handoff-install`
- **cc-chime** — runs automatically on the `Stop` and `Notification` hooks, no commands to invoke

## Principles

What ties the family together, even though one plugin writes configs and another writes LinkedIn posts.

|     | Principle            | What it means in practice                                                                                                                                                                                                                          |
| --- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ✓   | Slim by default      | Every line of context costs tokens on every message. Minimum viable config is the goal, not the baseline.                                                                                                                                          |
| ─   | One clear way in     | Four plugins ship `/slash` commands; one runs automatically via hooks. No hidden config files, no menu trees.                                                                                                                                      |
| ▸   | Tables, not graphics | Docs lean on tables, rules, and ✓ ✗ glyphs to communicate state — output that reads as proof, not decoration.                                                                                                                                      |
| │   | Shared guardrails    | Every repo runs the same secret-scanning pre-commit hook and follows the same [repo guideline](https://github.com/clever-cc-plugins/marketplace/blob/main/docs/cc-plugin-repo-guideline.md) — one marketplace entry is the single source of truth. |

## Install

```
# in any Claude Code project
$ /plugin marketplace add clever-cc-plugins/marketplace
✓ marketplace added · 5 plugins available

$ /plugin install cc-config@clever-cc-plugins
✓ cc-config installed
```

See the [marketplace](https://github.com/clever-cc-plugins/marketplace) repo for the full catalog, auto-update instructions, and how to add a new plugin.

---

<p align="center">
  © 2026 Michael van Laar · MIT · each plugin lives in its own repo, cataloged by <a href="https://github.com/clever-cc-plugins/marketplace">marketplace</a>
</p>
