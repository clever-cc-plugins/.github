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
  A small family of MIT-licensed plugins for Claude Code, authored by Michael van Laar.<br />
  Opinionated, dogfood-tested, and built around one rule: every line costs tokens on every message. Yes, that includes this one.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/plugins-8-F97316?style=flat-square&labelColor=404040" alt="8 plugins" />
  <img src="https://img.shields.io/badge/skills-57-F97316?style=flat-square&labelColor=404040" alt="57 skills" />
  <img src="https://img.shields.io/badge/license-MIT-404040?style=flat-square" alt="MIT License" />
</p>

---

## Plugins

Each plugin lives in its own repo and ships through this marketplace. The plugins are versioned independently, so Claude Code can detect and apply updates one by one.

| Plugin                                                                                                                                                                                                                 | For              | What it does                                                                                                                                                                          |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-config.svg" width="48" height="48" alt="" /><br />[**cc-config**](https://github.com/clever-cc-plugins/cc-config)    | _for developers_ | Bootstraps and audits a best-practice Claude Code configuration with hardened permissions, formatter hooks, and cost-optimization defaults.                                           |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-concept.svg" width="48" height="48" alt="" /><br />[**cc-concept**](https://github.com/clever-cc-plugins/cc-concept) | _for marketers_  | The strategic frame before the content: positioning, campaign concepts, channel strategy, content strategy, and go-to-market plans that the `cc-content` skills then execute against. |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-content.svg" width="48" height="48" alt="" /><br />[**cc-content**](https://github.com/clever-cc-plugins/cc-content) | _for marketers_  | A content studio in slash commands: brand onboarding, LinkedIn drafts, blog articles, sample curation, and more.                                                                      |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-career.svg" width="48" height="48" alt="" /><br />[**cc-career**](https://github.com/clever-cc-plugins/cc-career)    | _for you_        | The strategic frame before the coaching: a career plan, an uplevel roadmap, and a personal-branding strategy that the `cc-coach` skills coach against.                                |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-coach.svg" width="48" height="48" alt="" /><br />[**cc-coach**](https://github.com/clever-cc-plugins/cc-coach)       | _for you_        | Live coaching conversations on career, life, networking, presentations, and productivity. No plan required, and richer when `cc-career` is installed.                                 |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-chef.svg" width="48" height="48" alt="" /><br />[**cc-chef**](https://github.com/clever-cc-plugins/cc-chef)          | _for you_        | Grounded everyday recipes from a mood, your fridge, or a dish name, plus reworking, personal dietary guidelines, and export to recipe apps.                                           |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-handoff.svg" width="48" height="48" alt="" /><br />[**cc-handoff**](https://github.com/clever-cc-plugins/cc-handoff) | _for developers_ | Hands work off between machines or sessions: it writes a `HANDOFF.md` snapshot and documents the pickup convention in `CLAUDE.md`.                                                    |
| <img src="https://raw.githubusercontent.com/clever-cc-plugins/.github/main/assets/plugin-icons/cc-chime.svg" width="48" height="48" alt="" /><br />[**cc-chime**](https://github.com/clever-cc-plugins/cc-chime)       | _ambient_        | Plays an audio cue when Claude finishes a turn or needs your input. It has no commands and just runs.                                                                                 |

- **cc-config**: `/cc-config:bootstrapping-config` · `/cc-config:auditing-config`
- **cc-concept**: `/cc-concept:strategy-onboarding` · `/cc-concept:positioning` · `/cc-concept:campaign-concept` · `/cc-concept:gtm-plan` · +9 more
- **cc-content**: `/cc-content:content-onboarding` · `/cc-content:linkedin-post` · `/cc-content:blog-article` · `/cc-content:samples-curation` · `/cc-content:session-wrap` · +17 more
- **cc-career**: `/cc-career:career-onboarding` · `/cc-career:career-plan` · `/cc-career:personal-branding-strategy` · `/cc-career:career-performance-review`
- **cc-coach**: `/cc-coach:career-coach` · `/cc-coach:life-coach` · `/cc-coach:networking-coach` · `/cc-coach:presentation-coach` · +3 more
- **cc-chef**: `/cc-chef:chef-onboarding` · `/cc-chef:create-recipe` · `/cc-chef:rework-recipe` · `/cc-chef:export-recipe` · +3 more
- **cc-handoff**: `/cc-handoff:handoff` · `/cc-handoff:handoff-install`
- **cc-chime**: runs automatically on the `Stop` and `Notification` hooks, with no commands to invoke

## Principles

What ties the family together, even though one plugin writes configs and another one writes LinkedIn posts.

|     | Principle         | What it means in practice                                                                                                                                                                                                                                    |
| --- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ✓   | Slim by default   | Every line of context costs tokens on every message, so the target is the minimum viable config.                                                                                                                                                             |
| ─   | One clear way in  | Seven plugins ship `/slash` commands, and one runs automatically via hooks. There are no hidden config files and no menu trees.                                                                                                                              |
| ▸   | Tables first      | The docs use tables, rules, and ✓ ✗ glyphs to communicate state, so the output reads as proof.                                                                                                                                                               |
| │   | Shared guardrails | Every repo runs the same secret-scanning pre-commit hook and follows the same [repo guideline](https://github.com/clever-cc-plugins/marketplace/blob/main/docs/cc-plugin-repo-guideline.md). One marketplace entry per plugin is the single source of truth. |

## Install

```
# in any Claude Code project
$ /plugin marketplace add clever-cc-plugins/marketplace
✓ marketplace added · 8 plugins available

$ /plugin install cc-config@clever-cc-plugins
✓ cc-config installed
```

The [marketplace](https://github.com/clever-cc-plugins/marketplace) repo has the full catalog, the auto-update instructions, and the steps for adding a new plugin.

---

<p align="center">
  © 2026 Michael van Laar · MIT · each plugin lives in its own repo, cataloged by <a href="https://github.com/clever-cc-plugins/marketplace">marketplace</a>
</p>
