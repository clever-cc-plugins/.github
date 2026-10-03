# Plugin icons

Source SVGs for each plugin's `plugins/<name>/.claude-plugin/icon.png`. Every icon uses the same template, derived from the light-mode [`logo.svg`](../logo.svg) and the org avatar:

| Element    | Value                                                                                                     |
| ---------- | --------------------------------------------------------------------------------------------------------- |
| Canvas     | 1024×1024, full-bleed `#FFEDD5` (orange-100, the avatar background)                                       |
| Frame      | `[ ]` brackets in `#404040` (neutral-700): x 132–892, y 192–832, stroke 92, arms 214 long × 84 thick      |
| Glyph      | One plugin-specific shape in `#F97316` (orange-500), secondary detail in `#7C2D12` (orange-900)           |
| Glyph area | 380×380 box at 322–702, scaled ×1.053 around the center so it keeps clear of the bracket arms at 24–32 px |

| Plugin     | Glyph                    |
| ---------- | ------------------------ |
| cc-config  | Settings sliders         |
| cc-concept | Target                   |
| cc-content | Pilcrow (¶)              |
| cc-career  | Ascending steps          |
| cc-coach   | Speech bubble            |
| cc-handoff | Page with outgoing arrow |
| cc-chime   | Bell                     |

Each plugin repo carries two copies:

- `plugins/<name>/.claude-plugin/icon.png`: the 1024×1024 opaque RGB PNG that ships with the plugin. The plugin directory picks it up by convention, so no `plugin.json` key is needed.
- `assets/icon.svg`: a copy of the SVG for READMEs and docs, kept outside `plugins/` so it doesn't ship with the plugin. Each plugin README shows it right-aligned next to the `# <name>` heading.

The org profile ([`profile/README.md`](../../profile/README.md)) and the [marketplace README](https://github.com/clever-cc-plugins/marketplace#available-plugins) link the SVGs in this folder by raw URL in their plugin tables, so keep the file names stable.

To add a plugin: copy any SVG, replace the glyph group, put the SVG here and in the plugin repo's `assets/icon.svg`, and export the PNG. Check it at 32 px before committing. When you change an SVG here, update both copies in the plugin repo.
