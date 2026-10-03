# Plugin icons

Source SVGs for each plugin's `plugins/<name>/.claude-plugin/icon.png`. Every icon uses the same template, derived from the `[ ]` brackets in [`logo.svg`](../logo.svg):

| Element    | Value                                                                                                     |
| ---------- | --------------------------------------------------------------------------------------------------------- |
| Canvas     | 1024×1024, full-bleed `#171717` (neutral-900, the dark logo background)                                   |
| Frame      | `[ ]` brackets in `#D4D4D4` (neutral-300): x 132–892, y 192–832, stroke 92, arms 214 long × 84 thick      |
| Glyph      | One plugin-specific shape in `#F97316` (orange-500), secondary detail in `#FDBA74` (orange-300)           |
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

To add a plugin: copy any SVG, replace the glyph group, and export a 1024×1024 opaque RGB PNG to `.claude-plugin/icon.png` in the plugin repo (the plugin directory picks it up by convention, no `plugin.json` key needed). Check it at 32 px before committing.
