# Learnings Protocol Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every clever-cc-plugins skill reads, writes and reviews `.claude/learnings.md` by one shared protocol that marks each entry's source (`stated` / `corrected` / `inferred`), replaces contradicted entries instead of stacking them, shows the user the saved lines instead of a count, and promotes or retires entries by judgment instead of a "3+ similar" threshold.

**Architecture:** One file, `plugins/<plugin>/skills/_shared/learnings-protocol.md`, byte-identical in all seven plugin repos with skills (cc-career, cc-chef, cc-coach, cc-concept, cc-config, cc-content, cc-handoff). Skills and skill contracts stop restating learnings rules and instead tell the model to read the protocol's **Recall**, **Writing**, **Confirming** or **Reviewing** section. The marketplace's `check-doc-sync.py` gains a check that every copy exists and is identical. The design follows Anthropic's "The components of agent memory" (2026-11-06): keep injected memory small and correct, record how a rule is known, let the model judge salience instead of fixed rules, and use consolidation passes to fix, prune and promote.

**Tech Stack:** Markdown skill files; Python 3 standard library + `unittest` for the drift check; bash/grep for verification.

**Spec:** No separate spec. The design comes from the analysis in the session that produced this plan (gaps 1–3 of the comparison with the article). The **Shared artifacts** section below is the spec: its text is exact copy.

## Global Constraints

- Root of all repos: `ROOT=/home/vanlaarmi12/Git-Repos/clever-cc-plugins`. Each `cc-*`, `marketplace` and `.github` directory is its own git repo; the plugin dir inside each plugin repo is `plugins/<repo-name>/`.
- `learnings-protocol.md` is byte-identical in every plugin repo. Its line 3 is `_Last updated: 2026-11-10_` (session-wrap Step 1c reads line 3).
- Entry format, exactly: `[<plugin>:<skill>] <observation> (<source>) — <YYYY-MM-DD>` with `<source>` ∈ `stated`, `corrected`, `inferred`.
- No migration of existing `.claude/learnings.md` files. Unmarked entries are treated as `stated`.
- New Markdown paragraphs are single unwrapped lines (user rule: no hard wraps inside paragraphs). Do not reflow existing paragraphs you don't change.
- Each skill keeps its own explicit feedback question, its domain examples of what to record, and its closing line. Only the duplicated rules, file-creation boilerplate and count confirmations are removed.
- Every skill whose text tells the model to write `.claude/learnings.md` has `Edit` in its `allowed-tools` frontmatter (or no `allowed-tools` line).
- Git: per repo, work on branch `feat/learnings-protocol`. Commits use Conventional Commits with gitmoji and type `feat` (behaviour changes; `refactor`/`docs` would not trigger a plugin release). End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Local commits need no confirmation; every `git push`, PR creation or merge needs explicit user confirmation, per repo.
- The marketplace change (Task 1) is merged last, after every plugin repo has the protocol on `main`. Its remote-mode check reads plugin repos at `HEAD` and would fail the weekly run otherwise.

## Review Focus

1. **Legacy unmarked entries** (every existing learnings file): recall must apply them as `stated`; review must judge their source from the wording (many came from silent auto-store) instead of promoting them by default or retiring them as one-offs. Pinned by the Task 11 smoke test (the "SME" entry).
2. **An inferred observation contradicting a stated/corrected entry:** must not overwrite it. Pinned only by protocol text (Writing rule 2), which R1 keeps identical everywhere. No smoke step reliably provokes an inference that contradicts a stated entry, so reviewers should check this rule by reading it.
3. **session-wrap re-proposing the same kept entries every session:** session-wrap reviews only today's entries plus older entries that group with them, unless the user says "review all". Pinned in Task 3 and the Task 11 session-wrap step.
4. **Replacement across plugin tags:** a replaced line takes the writing skill's tag, so it leaves a tag-filtered review's scope. Accepted behaviour; the protocol says so explicitly (Writing rule 2) so reviewers don't treat it as a bug.
5. **Stale project-local protocol copy** (copied by `new-content-skill` / `new-coaching-skill` into `.claude/skills/_shared/`): session-wrap Step 1c must offer the refresh. Pinned in Task 3 Step 3 (grep) and Task 11.

## Out of scope

- Gap 5 (size cap and staleness pass over the whole file). The Reviewing section's **Retire** rule covers superseded and covered entries when a review runs; nothing triggers a review automatically.
- Gap 6 is delivered as a side effect: the protocol's **Writing** section replaces each skill's fixed "Qualifies / Does not qualify" lists with a purpose statement, so no separate work.
- The generic `## Learnings` CLAUDE.md section that `bootstrapping-config` generates for user projects keeps its wording. Entries Claude writes outside skills stay unmarked and are read as `stated`.

---

## Shared artifacts

### S1: `learnings-protocol.md` (exact copy)

Create this file once in Task 2 at `cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md`; every other repo task copies it with `cp`. The text between the outer fences is the file content (inner fences are part of it).

````markdown
# Learnings Protocol

_Last updated: 2026-11-10_

`.claude/learnings.md` is the project's memory between sessions. It holds what a future run on this project needs to know but cannot read from the request, `CLAUDE.md` or the registered context files. Every clever-cc-plugins skill reads and writes it by this protocol. This file is identical in every plugin; change it in all plugin repos at once.

## Entry format

One line per entry, a blank line between entries:

```text
[<plugin>:<skill>] <observation> (<source>) — <YYYY-MM-DD>
```

- The tag names the skill that wrote the entry. It is provenance, not a filter: every skill applies every relevant entry.
- `<source>` records how the entry is known:
  - `stated`: the user said it as a standing preference, rule or fact.
  - `corrected`: the user corrected an output. The entry records the corrected behaviour, not the mistake.
  - `inferred`: the skill concluded it from the run. The user has not confirmed it.
- Entries without a source marker predate this protocol. Treat them as `stated`, and do not rewrite them only to add a marker.

## Recall

Before any other work, read `.claude/learnings.md` in full if it exists. Apply the entries relevant to this run. When two entries conflict, `stated` and `corrected` beat `inferred`; between equal sources the newer date wins. Never announce this step. Mention an entry only when it changes what you do.

## Writing

Record what a future run on this project would need and could not read from the request, `CLAUDE.md` or the context files: preferences, constraints, project facts, corrections, and non-default choices the user accepted. Do not record standard behaviour applied without deviation, details that only mattered for this run, or anything an existing entry already says. Prefer one precise entry over several partial ones. When in doubt, skip.

Before writing, compare the new observation with every existing entry, under any tag:

1. **An equivalent entry exists:** write nothing. If the new source is stronger (`stated` or `corrected` over `inferred`), update that entry's source and date in place instead.
2. **The observation contradicts or updates an existing entry:**
   - New source `stated` or `corrected`, or both `inferred`: replace the old line in place with the new entry. The new line carries the current skill's tag, even if the old line had another tag.
   - New source `inferred`, old entry `stated`, `corrected` or unmarked: keep the old entry and write nothing. If this run gave real reason to doubt it, ask the user before changing anything.
3. **Otherwise:** append the new entry at the end of the file.

Never leave two entries in the file that contradict each other.

If the file does not exist, create it with this header first:

```markdown
# Learnings

Observations and corrections collected by clever-cc-plugins skills. One entry per line: `[plugin:skill] observation (stated|corrected|inferred) — YYYY-MM-DD`.

---
```

## Confirming

At the end of the skill's feedback step, after the user has answered or skipped the feedback question, show every entry this run wrote or replaced, verbatim, in one block. Mark new entries with `+` and replacements with `~`, followed by the line they replaced:

```text
Saved to .claude/learnings.md:
+ [cc-content:linkedin-post] Links go in the post body, never in the first comment (stated) — 2026-11-10
~ [cc-content:linkedin-post] Hashtags are optional, two at most (corrected) — 2026-11-10
  replaces: [cc-content:linkedin-post] Use 3–5 hashtags (inferred) — 2026-10-02
```

Follow the block with one line inviting the user to drop or change any of these. Apply their answer if they give one. If the run wrote nothing, say nothing about learnings.

## Reviewing

Review skills (`session-wrap`, `learnings-promotion`, `auditing-config`) consolidate the file. Each review skill sets its scope (which tags, which entries) and its promotion targets. These rules are shared:

1. Read the entries in scope, plus `CLAUDE.md` and the registered context files.
2. Group entries that express the same underlying concern, however they are worded.
3. Propose one action per group or single entry, stating the entry count, the sources and a one-line reason:
   - **Promote:** a standing rule. That is any `stated` or `corrected` entry, or a group of two or more related entries. For an unmarked entry the source is unknown: judge from its wording whether the user said it, and say so in the proposal. Frequency is a signal, not a threshold: one stated rule can qualify, and three unconfirmed inferences can still be wrong. Choose the narrowest target that reaches every run needing the rule: a skill's guidelines, a context file or a voice guide before `CLAUDE.md`, which every session loads.
   - **Keep:** still true and useful, but not yet a standing rule. Typically a single `inferred` entry.
   - **Retire:** already covered by `CLAUDE.md` or a context file (name the file), contradicted by one of them, superseded by a newer entry, or tied to a situation that is over.
4. Apply nothing before the user decides each proposal: promote, keep or retire. Remove promoted and retired entries from `.claude/learnings.md`; leave kept entries unchanged. Delete the file when no entries remain below the header.
````

### S2: Recall snippet (replaces a skill's Step 0 recall paragraph)

```markdown
Read `../_shared/learnings-protocol.md` and follow its **Recall** section.
```

Append the skill's existing skill-specific sentence if it has one (for example cc-concept's "in particular, …" clauses). Delete the generic text it replaces ("If `.claude/learnings.md` exists, read it silently… Do not announce this step…").

### S3: Feedback-step snippet (standalone skills: cc-content, cc-config, cc-coach `research-prompt`)

Replace the skill's whole "Auto-store phase" block (format line, Qualifies/Does-not-qualify lists, file-exists check, header block) and the count confirmations in its "Explicit feedback" bullets with:

```markdown
**Auto-store phase.** Read `../_shared/learnings-protocol.md` and follow its **Writing** section. Tag entries `[<plugin>:<skill>]`; the source is `inferred` unless the user said it. Worth recording in this skill: <the skill's domain examples, condensed from its old "Qualifies:" line>.

**Explicit feedback.** <the skill's existing question, unchanged>

- If the user provides a correction, record it per the protocol's **Writing** section with source `corrected`.
- Then follow the protocol's **Confirming** section. <the skill's existing closing line, unchanged, e.g. "Great — the post is ready to publish…">
```

Keep an old "Does not qualify" item only if it is specific to the skill; drop items the protocol already covers.

### S4: Contract step text (cc-career, cc-concept, cc-coach, cc-chef `skill-contract.md`)

Step 0, replacing the current "Recall learnings" item:

```markdown
0. **Recall learnings** (silent) — read `learnings-protocol.md` in this `_shared/` folder and follow its **Recall** section.
```

Feedback step (cc-career and cc-concept Step 7, replacing the current item):

```markdown
7. **Two-phase feedback** — read `learnings-protocol.md` in this `_shared/` folder and follow its **Writing** section: auto-store qualifying observations tagged `[<plugin>:<skill-name>]` (source `inferred` unless the user said it), then ask for feedback and record any correction with source `corrected`. Finish with the protocol's **Confirming** section. Ask before promoting anything heavier.
```

### Repo checks (run in each plugin task; `REPO` is the task's repo name)

```bash
ROOT=/home/vanlaarmi12/Git-Repos/clever-cc-plugins; P="$ROOT/$REPO/plugins/$REPO"
# R1 protocol copy identical to the cc-content copy
cmp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" "$P/skills/_shared/learnings-protocol.md"
# R2 no count-only confirmations left
grep -rnE 'learning\(s\) (auto-)?saved' "$P"
# R3 every skill/contract that names .claude/learnings.md also points to the protocol
for f in $(grep -rl '\.claude/learnings\.md' --include=SKILL.md --include=skill-contract.md "$P"); do grep -q 'learnings-protocol\.md' "$f" || echo "MISSING $f"; done
# R4 every example or template entry carries a source marker
grep -rnE '\[cc-[a-z]+:[a-z-]+\] .* — (20[0-9]{2}-|<YYYY)' "$P" | grep -vE '\((stated|corrected|inferred)\) — '
# R5 skills that point to the protocol pre-approve Edit
for f in $(grep -rl 'learnings-protocol\.md' --include=SKILL.md "$P"); do l=$(grep -m1 '^allowed-tools:' "$f"); [ -z "$l" ] || [[ "$l" == *Edit* ]] || echo "NO-EDIT $f"; done
```

Expected for R1–R5: no output (R1 exits 0).

---

### Task 1: marketplace — drift check for protocol copies + guideline

**Files:**

- Modify: `marketplace/scripts/check-doc-sync.py` (module docstring; `check()` at line 113; new helper)
- Modify: `marketplace/tests/test_check_doc_sync.py` (`build()` at line 56, `run_check()` at line 31, new tests)
- Modify: `marketplace/docs/cc-plugin-repo-guideline.md` ("Observation-log bracket tags" section, around line 282)
- Modify: `marketplace/CLAUDE.md` (Conventions list)

**Interfaces:**

- Produces: `check_learnings_protocol(src, plugins, repo, skills) -> list[str]` in `check-doc-sync.py`; `check()` extends its `problems` with the result. Problem strings, exactly:
  - missing: `"<plugin>: plugins/<plugin>/skills/_shared/learnings-protocol.md not found"`
  - differs: `"<plugin>: _shared/learnings-protocol.md differs from the copy in <ref1>, <ref2>"`

- [ ] **Step 1: Branch**

Run: `cd "$ROOT/marketplace" && git switch -c feat/learnings-protocol`

- [ ] **Step 2: Write the failing tests**

In `tests/test_check_doc_sync.py`: add `PROTOCOL = "# Learnings Protocol\n\n_Last updated: 2026-11-10_\n"`; give `build()` a `protocols=None` parameter that, for every plugin with at least one skill, writes `plugins/<name>/skills/_shared/learnings-protocol.md` with `(protocols or {}).get(name, PROTOCOL)` unless that value is `None` (then the file is not written); pass `protocols` through `run_check()`. Add:

```python
    def test_missing_learnings_protocol(self):
        p = self.run_check(protocols={"cc-b": None})
        self.assertIn("cc-b: plugins/cc-b/skills/_shared/learnings-protocol.md not found", p)

    def test_learnings_protocol_differs(self):
        p = self.run_check(protocols={"cc-b": PROTOCOL + "drift\n"})
        self.assertIn("cc-b: _shared/learnings-protocol.md differs from the copy in cc-a", p)
        self.assertFalse(any(x.startswith("cc-a: _shared/learnings-protocol.md") for x in p), p)

    def test_hook_only_plugin_needs_no_learnings_protocol(self):
        self.assertFalse(any("cc-hook" in x and "learnings-protocol" in x for x in self.run_check()))
```

- [ ] **Step 3: Run the tests to verify the new ones fail**

Run: `python3 -m unittest discover -s tests -v 2>&1 | tail -5`
Expected: FAIL for `test_missing_learnings_protocol` and `test_learnings_protocol_differs`; all pre-existing tests still pass.

- [ ] **Step 4: Implement `check_learnings_protocol(src, plugins, repo, skills) -> list[str]`**

Only plugins with a non-empty skill list are checked, in catalog order. Read each copy with `src.read(repo[name], "plugins/%s/skills/_shared/learnings-protocol.md" % name)`; catch `FileNotFoundError` and report "missing" (do not let it reach `main()`, which would exit 2, because `FileNotFoundError` is an `OSError`). Among the copies found, the reference text is the most common one, with ties going to the earliest plugin in catalog order (`collections.Counter.most_common` keeps insertion order for ties). Report "differs" for each plugin whose text is not the reference, naming the plugins that hold the reference text. Call it at the end of `check()` before `return problems`. Add one line to the module docstring's "Checked against that truth" list: `- every plugin with skills: skills/_shared/learnings-protocol.md exists and is identical across plugins`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -v 2>&1 | tail -3`
Expected: `OK`. If a pre-existing test that builds its own fixture without `build()` now reports `learnings-protocol.md not found` (check `test_skills_are_read_from_the_repo_named_in_source` and `test_plugin_with_documented_skills_but_none_found_is_not_hook_only`), add the protocol file to that test's fixture; the check is right, the fixture is incomplete.

- [ ] **Step 6: Update the guideline and CLAUDE.md**

In `docs/cc-plugin-repo-guideline.md`, "Observation-log bracket tags": change the format line to `[<plugin-name>:<skill-name>] <concise observation> (<stated|corrected|inferred>) — <YYYY-MM-DD>`, add `(stated)` to the example, and add one paragraph: every plugin with skills ships `plugins/<name>/skills/_shared/learnings-protocol.md`, byte-identical across plugins; skills reference it instead of restating learnings rules; to change it, edit one copy and copy it to every plugin repo in the same change set; `scripts/check-doc-sync.py` reports drift. In `CLAUDE.md` Conventions add: `- learnings-protocol.md must stay identical in every plugin repo; check-doc-sync.py reports a missing or differing copy`.

- [ ] **Step 7: Commit (local only)**

```bash
git add scripts/check-doc-sync.py tests/test_check_doc_sync.py docs/cc-plugin-repo-guideline.md CLAUDE.md
git commit -m "✨ feat(doc-sync): check that learnings-protocol.md is identical across plugins

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Do not push. Task 12 pushes this repo last.

### Task 2: cc-content — protocol file + writing skills

**Files:**

- Create: `cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md` (S1, exact)
- Modify (Step 0 → S2; feedback step → S3; add `Edit` to `allowed-tools` where missing): `atomize`, `blog-article`, `brand-voice`, `content-ideation`, `content-onboarding`, `content-performance-review`, `facebook-post`, `gated-long-form-content`, `humanize`, `instagram-post`, `landing-page`, `linkedin-post`, `long-tail-copy`, `marketing-email`, `press-release`, `research-prompt`, `samples-curation`, `x-post` — each `cc-content/plugins/cc-content/skills/<name>/SKILL.md`. The feedback step is the `## Step N: Feedback` section (content-onboarding and samples-curation have a differently shaped block around their `<concise observation>` line; apply S3 to that block).
- Modify: `cc-content/plugins/cc-content/skills/register-context/SKILL.md` `## Feedback` (line 141): keep the question; replace "I will log a correction to `.claude/learnings.md`" with recording per the protocol's **Writing** section (tag `[cc-content:register-context]`, source `corrected`), then **Confirming**.

**Interfaces:**

- Produces: `_shared/learnings-protocol.md`, which Tasks 4–10 copy with `cp` and Task 3 references.
- Consumes: S1, S2, S3.

- [ ] **Step 1: Branch and create the protocol file**

Run: `cd "$ROOT/cc-content" && git switch -c feat/learnings-protocol`. Write S1 to `plugins/cc-content/skills/_shared/learnings-protocol.md`. Verify: `sed -n 3p plugins/cc-content/skills/_shared/learnings-protocol.md` prints `_Last updated: 2026-11-10_`.

- [ ] **Step 2: Run the repo checks to see the failures**

Run the Repo checks with `REPO=cc-content`.
Expected: R2 lists about 20 lines, R4 lists the `<concise observation> — <YYYY-MM-DD>` template lines. (R3 and R5 pass trivially until skills reference the protocol.)

- [ ] **Step 3: Edit the 19 skills**

Apply S2 and S3 per the file list. Keep each skill's own question, domain examples and closing line. Add `Edit` to `allowed-tools` in skills that lack it (currently all of the listed skills except `brand-voice`, `content-onboarding` and `register-context`).

- [ ] **Step 4: Run the repo checks to verify they pass**

Run the Repo checks with `REPO=cc-content`, but exclude the Task 3 files: append `| grep -v -e session-wrap -e new-content-skill` to R2, R3 and R4.
Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add plugins/cc-content/skills
git commit -m "✨ feat(learnings): adopt the shared learnings protocol in content skills

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: cc-content — session-wrap review + new-content-skill template

**Files:**

- Modify: `cc-content/plugins/cc-content/skills/session-wrap/SKILL.md` (Step 0 line 265; Step 1c lines 333–373; Step 4 lines 401–435; Step 5 lines 437–522; Step 7 summary label)
- Modify: `cc-content/plugins/cc-content/skills/new-content-skill/SKILL.md` (Step 0 line 18; `cp -n` block lines 134–137; generated-skill template Step 0 around line 319 and feedback around lines 419–434; file listing around lines 470–472)

**Interfaces:**

- Consumes: `_shared/learnings-protocol.md` from Task 2.
- Produces: the review scope rule other review skills mirror: session-wrap reviews `[cc-content:` entries dated today plus older `[cc-content:` entries that group with them; "review all" widens the scope to every `[cc-content:` entry.

- [ ] **Step 1: session-wrap Step 0 and Step 4**

Step 0 → S2. Step 4: replace the file check, the header block, the `[<skill-name>] <correction summary>` format and the count confirmation with: record each correction from Step 3 per the protocol's **Writing** section, tagged `[cc-content:<skill-name>]`, source `corrected`, then follow **Confirming**.

- [ ] **Step 2: session-wrap Step 5 → protocol review**

Replace the "three or more semantically similar" detection and the option list with the protocol's **Reviewing** section. Scope: `[cc-content:` entries dated today plus older `[cc-content:` entries that group with them; if the user says "review all", every `[cc-content:` entry. Promotion targets stay as today: (a) the skill's `format-guidelines.md`, (b) project `CLAUDE.md` `## Learnings`, (c) the registered brand voice guide (same show-only-for-voice-patterns rule and the same insertion rules as today). Replace (d) "Dismiss" with **Keep** and **Retire** per the protocol. Keep the "Recurring pattern detected" block, retitled "Learnings review", listing each entry with its source. End the block with one line: older entries are not shown; say "review all" to include them. (cc-content has no full-review skill of its own, so this phrase is the only full review without cc-config.) In Step 7 add a line `Learnings retired: <N (or "none")>` under "Patterns promoted".

- [ ] **Step 3: session-wrap Step 1c → all copied shared files**

Generalize Step 1c from the two hard-coded files to the four files `new-content-skill` copies: `storytelling-frameworks.md`, `persuasion-principles.md`, `readability-patterns.md`, `learnings-protocol.md`. The `ls` line lists all four; the intro sentence names all four; the compare/ask/refresh logic is unchanged.

Verify: `grep -c 'learnings-protocol.md\|readability-patterns.md' plugins/cc-content/skills/session-wrap/SKILL.md` prints a number ≥ 2, and `grep -n 'ls .claude/skills/_shared' plugins/cc-content/skills/session-wrap/SKILL.md` shows one line naming all four files.

- [ ] **Step 4: new-content-skill**

Step 0 → S2. Add `cp -n "${CLAUDE_SKILL_DIR}/../_shared/learnings-protocol.md" ".claude/skills/_shared/" 2>/dev/null` to the copy block, and `.claude/skills/_shared/learnings-protocol.md` to the file listing near line 470. In the generated-skill template, Step 0 becomes S2 and the feedback step becomes S3 with `[cc-content:<skill-name>]` (end-user and plugin-dev mode both resolve `../_shared/` correctly). Add `Edit` to `allowed-tools`.

- [ ] **Step 5: Run the full repo checks**

Run the Repo checks with `REPO=cc-content` (no exclusions), plus `grep -nE '3 or more|three or more|Dismiss' plugins/cc-content/skills/session-wrap/SKILL.md`.
Expected: no output from any of them.

- [ ] **Step 6: Commit**

```bash
git add plugins/cc-content/skills/session-wrap/SKILL.md plugins/cc-content/skills/new-content-skill/SKILL.md
git commit -m "✨ feat(session-wrap): review learnings by source and judgment, refresh all shared copies

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: cc-concept — protocol, contract, writing skills

**Files:**

- Create: `cc-concept/plugins/cc-concept/skills/_shared/learnings-protocol.md` (`cp` from cc-content)
- Modify: `cc-concept/plugins/cc-concept/skills/_shared/skill-contract.md` Step 0 (line 11) and Step 7 (line 29) → S4
- Modify (in `cc-concept/plugins/cc-concept/skills/<name>/SKILL.md`): `audience-personas`, `campaign-concept`, `channel-advisor`, `competitive-research`, `editorial-strategy`, `gtm-plan`, `positioning`, `seo-research`, `strategy-onboarding`, `strategy-performance-review`:
  - their own Step 0 recall paragraph → S2, keeping the skill's "in particular, …" clause;
  - "Store learnings tagged `[cc-concept:<skill>]` in `.claude/learnings.md`" → "Store learnings per the contract's Step 7, tagged `[cc-concept:<skill>]`.";
  - add `(stated)`, `(corrected)` or `(inferred)` to every example entry, whichever fits the example.
- Modify: `marketing-advisor/SKILL.md`: Step 0 → S2; in the save-prompt (lines 62–63), the "learnings" branch records per the protocol's **Writing** section with source `stated` (the user chose to save it), then **Confirming**; mark examples.
- Modify: `strategy-orchestrator/SKILL.md`: Step 0 → S2; Step 7 (line 148) records per **Writing** (source `stated`) and **Confirming**; `allowed-tools: Read` → `allowed-tools: Read, Write, Edit`.

**Interfaces:**

- Consumes: Task 2's protocol file, S2, S4.

- [ ] **Step 1: Branch and copy the protocol**

```bash
cd "$ROOT/cc-concept" && git switch -c feat/learnings-protocol
cp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" plugins/cc-concept/skills/_shared/
```

- [ ] **Step 2: Run the repo checks to see the failures**

Run the Repo checks with `REPO=cc-concept`. Expected: R3 lists most skills, R4 lists about 30 example lines, R5 lists `strategy-orchestrator` only after Step 3 adds the reference.

- [ ] **Step 3: Edit the contract and the 12 skills per the file list**

- [ ] **Step 4: Run the repo checks to verify they pass**

Run the Repo checks with `REPO=cc-concept`, excluding `learnings-promotion` (Task 5) by appending `| grep -v learnings-promotion` to R3 and R4. Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add plugins/cc-concept/skills
git commit -m "✨ feat(learnings): adopt the shared learnings protocol in concept skills

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: cc-concept — learnings-promotion by judgment

**Files:**

- Modify: `cc-concept/plugins/cc-concept/skills/learnings-promotion/SKILL.md` (Steps 1–4, lines 198–241; description frontmatter unchanged)
- Modify: `cc-concept/README.md` line 34 (skill table: "promotes recurring patterns" → "promotes, keeps or retires entries by source and relevance") and line 120 (same change in the prose); add `README.md` to this task's commit.

**Interfaces:**

- Consumes: the protocol's **Reviewing** section.

- [ ] **Step 1: Rewrite Steps 1–4 against the protocol**

Step 0 keeps reading the file and filtering to `[cc-concept:` tags, and adds: read `../_shared/learnings-protocol.md` (**Reviewing** section). Step 1 "Group and threshold" becomes "Group and propose" per the protocol: no 3-entry threshold; single `stated`, `corrected` or unmarked entries are promotion candidates. Step 2 keeps its two targets (CLAUDE.md default; cc-concept `_shared/*.md` or `SKILL.md` only with the explicit universality justification) and offers a registered context file as a third target when the entry is about the client rather than about behaviour. Step 3's delimited output lists each proposal with its count, sources, target and reason. User decisions are promote / keep / retire, where "keep" replaces today's "skip". Step 4: remove promoted and retired entries, leave kept ones, delete the file when empty, and still no git operations. Update the example line in Step 0 to carry a source marker.

- [ ] **Step 2: Verify**

```bash
grep -nE '3 or more|fewer than 3|dismiss' plugins/cc-concept/skills/learnings-promotion/SKILL.md
```

Expected: no output. Then run the full Repo checks with `REPO=cc-concept`; expected: no output.

- [ ] **Step 3: Commit**

```bash
git add plugins/cc-concept/skills/learnings-promotion/SKILL.md
git commit -m "✨ feat(learnings-promotion): promote, keep or retire by source and judgment

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: cc-career — protocol, contract, skills

**Files:**

- Create: `cc-career/plugins/cc-career/skills/_shared/learnings-protocol.md` (`cp` from cc-content)
- Modify: `cc-career/plugins/cc-career/skills/_shared/skill-contract.md` Step 0 (line 10) and Step 7 (line 28) → S4
- Modify: `career-onboarding`, `career-performance-review`, `career-plan`, `personal-branding-strategy` `SKILL.md`: Step 0 → S2 (keep the skill-specific clause); "Store learnings tagged … in `.claude/learnings.md`" → "Store learnings per the contract's Step 7, tagged `[cc-career:<skill>]`."; mark every example entry with a source.

- [ ] **Step 1: Branch and copy** — `cd "$ROOT/cc-career" && git switch -c feat/learnings-protocol && cp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" plugins/cc-career/skills/_shared/`
- [ ] **Step 2: Run the Repo checks** (`REPO=cc-career`). Expected: failures in R3 and R4.
- [ ] **Step 3: Edit the contract and the 4 skills per the file list**
- [ ] **Step 4: Run the Repo checks** (`REPO=cc-career`). Expected: no output.
- [ ] **Step 5: Commit** — `git add plugins/cc-career/skills && git commit -m "✨ feat(learnings): adopt the shared learnings protocol in career skills" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 7: cc-coach — protocol, contract, skills, generated-skill fix

**Files:**

- Create: `cc-coach/plugins/cc-coach/skills/_shared/learnings-protocol.md` (`cp` from cc-content)
- Modify: `cc-coach/plugins/cc-coach/skills/_shared/skill-contract.md`: Step 0 (line 14) → S4 Step 0; Step 5.2 (line 54): the "learnings" branch records per the protocol's **Writing** section, tagged `[cc-coach:<skill-name>]`, source `stated` (the user chose to save it), then **Confirming**.
- Modify: `career-coach`, `life-coach`, `networking-coach`, `presentation-coach`, `productivity-coach` `SKILL.md`: mark every example entry with a source. Their "Recall learnings silently per the contract" lines → S2.
- Modify: `research-prompt/SKILL.md`: Step 0 → S2, Step 5 → S3 (tag `[cc-coach:research-prompt]`), add `Edit` to `allowed-tools`.
- Modify: `new-coaching-skill/SKILL.md`:
  - Step 0 → S2; add `Edit` to `allowed-tools`.
  - In end-user mode (around line 128), after `mkdir -p .claude/skills/<domain-name>` add `mkdir -p .claude/skills/_shared` and `cp -n` of both `${CLAUDE_SKILL_DIR}/../_shared/skill-contract.md` and `…/learnings-protocol.md` into `.claude/skills/_shared/`. Today, generated end-user skills reference a contract that is never copied into the project.
  - Lines 211–212: the generated reference becomes plain `../_shared/skill-contract.md` for both modes (it resolves in both once the files are copied); delete the "adjust the relative path" note.
  - The two generated example entries (line 229) carry source markers.

- [ ] **Step 1: Branch and copy** — `cd "$ROOT/cc-coach" && git switch -c feat/learnings-protocol && cp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" plugins/cc-coach/skills/_shared/`
- [ ] **Step 2: Run the Repo checks** (`REPO=cc-coach`). Expected: failures in R2, R3 and R4.
- [ ] **Step 3: Edit per the file list**
- [ ] **Step 4: Verify** — run the Repo checks (`REPO=cc-coach`), expecting no output; and `grep -n 'cp -n' plugins/cc-coach/skills/new-coaching-skill/SKILL.md`, expecting two lines (`skill-contract.md`, `learnings-protocol.md`).
- [ ] **Step 5: Commit** — `git add plugins/cc-coach/skills && git commit -m "✨ feat(learnings): adopt the shared learnings protocol; copy shared files for project-local coaching skills" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 8: cc-chef — protocol and contract

**Files:**

- Create: `cc-chef/plugins/cc-chef/skills/_shared/learnings-protocol.md` (`cp` from cc-content)
- Modify: `cc-chef/plugins/cc-chef/skills/_shared/skill-contract.md`:
  - Step 0 (line 41 in the sequence) → S4 Step 0.
  - `### Step 5: Feedback and learnings` (lines 51–76): keep its two-phase shape and the output-language rule. Replace the format line, the Qualifies/Does-not-qualify lists, the file check and the header with: follow `learnings-protocol.md` in this `_shared/` folder (**Writing**), tag `[cc-chef:<skill>]`, source `inferred` unless the user said it, and "worth recording: recurring preferences not already in the context files, e.g. oven temperature in both °C and °F". Corrections get source `corrected`. Replace "confirm how many learnings were saved" with **Confirming**.
- Skills (`chef-onboarding`, `research-prompt`, `tandoor-food-cleanup`) already defer to contract Step 5 and keep their own "Qualifying observations" examples. Add a source marker to any example entry they contain (R4 finds them).

- [ ] **Step 1: Branch and copy** — `cd "$ROOT/cc-chef" && git switch -c feat/learnings-protocol && cp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" plugins/cc-chef/skills/_shared/`
- [ ] **Step 2: Edit the contract per the file list**
- [ ] **Step 3: Verify** — Repo checks (`REPO=cc-chef`), expecting no output; and `grep -n 'how many learnings' plugins/cc-chef/skills/_shared/skill-contract.md`, expecting no output.
- [ ] **Step 4: Commit** — `git add plugins/cc-chef/skills && git commit -m "✨ feat(learnings): adopt the shared learnings protocol in the chef contract" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 9: cc-config — protocol, both skills, audit review

**Files:**

- Create: `cc-config/plugins/cc-config/skills/_shared/learnings-protocol.md` (new `_shared/` dir; `cp` from cc-content)
- Modify: `cc-config/plugins/cc-config/skills/auditing-config/SKILL.md`:
  - Step 0 (line 18): S2, keeping the sentence that tags are provenance only.
  - `### 2g: Learnings review` (lines 284–295): scope is every entry under any tag. Steps 1–5 become: read `../_shared/learnings-protocol.md` and follow **Reviewing**. Promotion targets stay CLAUDE.md, an existing or new skill, or a hook (for deterministic behaviour). The user groups are "promote / keep / retire" instead of "promote to config / delete as one-off".
  - "When applying learnings review results" (lines 396–400): remove promoted and retired entries, leave kept ones, delete the file when empty.
  - Report step 5 (line 433): "how many entries were promoted, retired and kept".
  - `## Feedback` (line 468): S3 (tag `[cc-config:auditing-config]`; keep the "concise fact about this project" domain example and the closing note at line 500).
- Modify: `bootstrapping-config/SKILL.md`: Step 0 → S2; `## Feedback` (line 455) → S3 (tag `[cc-config:bootstrapping-config]`); in "Explain the Learnings mechanism" (lines 439–441), the third bullet says `/auditing-config` proposes promoting, keeping or retiring entries by source and relevance.
- Modify: `cc-config/README.md` line 156 ("groups the entries into recurring patterns and one-offs…") to match 2g: proposes promoting, keeping or retiring each entry by source and relevance; add `README.md` to this task's commit.
- Modify: `auditing-config/reference.md` line 92 ("Learnings graduation"): standing rules (stated or corrected entries, or related groups) graduate into CLAUDE.md rules, skills or hooks; superseded or covered entries are retired; the rest stay.

- [ ] **Step 1: Branch and copy** — `cd "$ROOT/cc-config" && git switch -c feat/learnings-protocol && mkdir -p plugins/cc-config/skills/_shared && cp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" plugins/cc-config/skills/_shared/`
- [ ] **Step 2: Edit per the file list**
- [ ] **Step 3: Verify** — Repo checks (`REPO=cc-config`), expecting no output; and `grep -nE '3\+ similar|one-off' plugins/cc-config/skills/auditing-config/SKILL.md plugins/cc-config/skills/auditing-config/reference.md plugins/cc-config/skills/bootstrapping-config/SKILL.md`, expecting no output.
- [ ] **Step 4: Commit** — `git add plugins/cc-config/skills && git commit -m "✨ feat(learnings): adopt the shared learnings protocol; audit reviews by source and judgment" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 10: cc-handoff — protocol and both skills

**Files:**

- Create: `cc-handoff/plugins/cc-handoff/skills/_shared/learnings-protocol.md` (new `_shared/` dir; `cp` from cc-content)
- Modify: `handoff/SKILL.md` line 38 and `handoff-install/SKILL.md` line 29: keep each question, but end it with "If not, tell me what to change." instead of "I will log a correction…". Add the instruction: record a correction per `../_shared/learnings-protocol.md` (**Writing**, tag `[cc-handoff:<skill>]`, source `corrected`), then **Confirming**. Add S2 as the first instruction of each skill. `handoff-install` already has `Edit` in `allowed-tools`; `handoff` has no `allowed-tools` line.

- [ ] **Step 1: Branch and copy** — `cd "$ROOT/cc-handoff" && git switch -c feat/learnings-protocol && mkdir -p plugins/cc-handoff/skills/_shared && cp "$ROOT/cc-content/plugins/cc-content/skills/_shared/learnings-protocol.md" plugins/cc-handoff/skills/_shared/`
- [ ] **Step 2: Edit both skills**
- [ ] **Step 3: Verify** — Repo checks (`REPO=cc-handoff`), expecting no output; and `grep -c 'learnings-protocol.md' plugins/cc-handoff/skills/*/SKILL.md`, expecting `2` for each file (recall + writing).
- [ ] **Step 4: Commit** — `git add plugins/cc-handoff/skills && git commit -m "✨ feat(learnings): adopt the shared learnings protocol in handoff skills" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 11: Cross-repo verification and behaviour smoke test

**Files:** none changed (fixture in a scratch directory only).

- [ ] **Step 1: Drift check across local clones**

Run: `cd "$ROOT/marketplace" && python3 scripts/check-doc-sync.py --root "$ROOT"`
Expected: `Documentation is in sync.` (exit 0). Any `learnings-protocol.md` line in the output names the repo to fix.

- [ ] **Step 2: Repo checks for all seven plugins**

Run the Repo checks once for each `REPO` in `cc-career cc-chef cc-coach cc-concept cc-config cc-content cc-handoff`.
Expected: no output for any repo.

- [ ] **Step 3: No stale user-facing docs**

Run: `cd "$ROOT" && grep -rnEi '3\+ similar|three or more|one-offs?|learning\(s\) saved|dismiss' --include=README.md . .github/profile | grep -v docs/superpowers`
Expected: no line about learnings. (`cc-content/README.md:167` "one-off constraints" is about campaign context and is fine.) Fix any other hit in the task that owns that repo.

- [ ] **Step 4: Smoke test: writing, contradiction, legacy entries (manual, user-run)**

In an empty scratch directory, create `CLAUDE.md` (one line: `# Smoke test`) and `.claude/learnings.md`:

```markdown
# Learnings

---

[cc-content:linkedin-post] Never use the term "SME"; say "Mittelstand" — 2026-08-01

[cc-content:linkedin-post] Use 3–5 hashtags (inferred) — 2026-09-01
```

Start Claude Code there with the local cc-content plugin loaded (e.g. `claude --plugin-dir "$ROOT/cc-content/plugins/cc-content"`; check `claude --help` for the current flag), run `/cc-content:linkedin-post` for a post about a German machine builder, continue without context, and answer the feedback question with "No hashtags at all."
Expected:

- The post says "Mittelstand", never "SME" (the legacy unmarked entry is applied as `stated`).
- No "N learning(s) saved" count; a `Saved to .claude/learnings.md:` block shows `~ … No hashtags … (corrected) — <today>` with a `replaces:` line naming the 3–5 hashtags entry.
- `.claude/learnings.md` contains exactly two entries: the unchanged "SME" line and the new corrected hashtag line.

- [ ] **Step 5: Smoke test: session-wrap scope (same session)**

Run `/cc-content:session-wrap`, skip the commit.
Expected: the "Learnings review" proposes only today's hashtag entry (plus any entry it groups with), offering Promote / Keep / Retire. The 2026-08-01 "SME" entry is not proposed unless you say "review all", and the block ends with a line telling you so. No proposal mentions a 3-entry threshold.

- [ ] **Step 6: Smoke test: stale project-local copy**

In the same scratch directory: `mkdir -p .claude/skills/_shared && printf '# Learnings Protocol\n\n_Last updated: 2026-01-01_\n' > .claude/skills/_shared/learnings-protocol.md`, then run `/cc-content:session-wrap` again.
Expected: Step 1c offers to refresh `learnings-protocol.md` (older than 2026-11-10).

Record any deviation as a fix in the owning task before Task 12.

### Task 12: Rollout (each push needs explicit user confirmation)

- [ ] **Step 1: Push and open PRs for the seven plugin repos**

For each plugin repo, after the user confirms that repo: `git push -u origin feat/learnings-protocol`, then `gh pr create --fill` with a body ending `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Merges happen only after the user approves each one.

- [ ] **Step 2: After all seven are merged to `main`, push and merge marketplace**

Run: `cd "$ROOT/marketplace" && python3 scripts/check-doc-sync.py` (remote mode, reads `HEAD`).
Expected: `Documentation is in sync.` Only then, with confirmation, push `feat/learnings-protocol` and open its PR.

- [ ] **Step 3: Confirm releases**

After the merges, each plugin repo's `plugin-release` run bumps a minor version (the commits are `feat`). Verify with `gh release list -R clever-cc-plugins/<repo> -L 1` per repo.
