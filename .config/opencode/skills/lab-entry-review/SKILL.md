---
name: lab-entry-review
description: >-
  Review a daily MQV-Atoms DokuWiki lab-book entry: read its text and its
  matplotlib plots, reconstruct in LOGICAL (not chronological) order what was
  investigated experimentally, give a quantitative mini-analysis with explicit
  hypotheses and interpretations, validate those interpretations interactively
  with the experimentalist, then write a "Summary" section into the entry. Use
  whenever the user asks to review / summarize / analyze a lab-book entry, "the
  entry for <date>", or "today's entry".
---

# Lab-entry review

Turn a raw daily lab-book entry into a **logically ordered summary with a
critical mini-analysis of the results**, in the house style of
`teams:m1machine:lab_book:summaries:clock_ila_2025` (read that page once as the
gold-standard exemplar). Wiki access, conventions, and identity are in the
project `CLAUDE.md` — follow them.

The output is a `===== Summary =====` section written into the *same* daily
entry. This skill does **interpretation only**: it draws on the entry text and
the **rendered PNG plots**. Data reduction — fitting, computing statistics,
producing the plots — is a *separate* workflow that the experimentalists run in
another repo (supported by its own SKILL.md); the plots you read here are its
finished output. Your job is to make sense of those results, not to reproduce
them (see "Reading plots"). Every interpretation is a **hypothesis to be
validated with the experimentalist** before it is committed.

## Guiding principles

- **Logical, not chronological.** The daily log is written as work happened.
  The summary regroups it into coherent investigation threads (e.g. "Rabi
  characterization", "Ramsey coherence", "spectrum-card bug") regardless of the
  order in the day. Order threads so the physics reads as a story.
- **Analyze, don't transcribe.** For each thread state: what was investigated
  and why → what the data/plots show (quantitatively, with units) → what it
  means. A summary that only restates the log adds no value.
- **Hypotheses are explicit and validated.** Interpretations are often not
  conclusive. Say so. Propose the plausible interpretations, mark each as a
  hypothesis, and confirm with the experimentalist. Never launder a guess into
  a stated fact.
- **Never fabricate numbers.** Only quote a value you can read from the text or
  off a plot (axis, fit legend, error bar). If you estimate from a curve, say
  "≈ (read off figure)". If you cannot tell, ask.
- **Mark AI provenance.** Any content the agent adds to the wiki must carry the
  `user:ai` tag in its `{{tag>...}}` line, so AI-generated contributions are clearly
  identifiable. Edits are attributed to the shared `llm` user, so this tag (and
  the edit summary) is the only provenance a future reader has.
- **This is a permanent, shared record.** Confirm before writing (see step 6).

## Inputs

- Target entry page id. If the user says "today"/"the entry", default to
  `teams:m1machine:lab_book:YYYY:MM:DD` for the current date; confirm the
  machine (`m1machine` vs `m1.5machine`) if ambiguous.
- Do **not** rewrite the day's detailed log content. You only *add* a Summary
  section (and may fix obvious typos with an explicit note).

## Workflow

### 1. Read the entry
- `core_getPage <id>` for the raw wiki source. Note the title, the section
  structure, the `{{tag>...}}` tags (authors `user:*`, projects `project:*`),
  measurement numbers, and every image reference `{{:ns:...png?...|...}}`.
- Skim linked entries (`core_getPageLinks`) only if needed to understand
  references to earlier work.

### 2. Read the plots
All plots are matplotlib PNGs stored as wiki media. For each figure you need to
interpret:
1. `core_getMediaInfo <media_id>` — confirm it exists and check `size`.
2. `core_getMedia <media_id>` — returns base64 (saved to a tool-results file if
   large).
3. Decode it to the scratchpad and view it:
   ```
   python3 <skill_dir>/scripts/decode_media.py <b64_source> <scratchpad>/<name>.png
   ```
   Then `Read` the PNG — you will see the actual figure (axes, curves, fits,
   error bars, violin distributions, legends). Read fit parameters straight off
   the legend.
- **Be economical.** Some entries embed huge image grids (e.g. a 16×21 scan =
  hundreds of thumbnails). Do not fetch every thumbnail. Fetch the *summary /
  overlaid* plots and a few representative panels, and say which you inspected.
- **State the source of each number:** "from the fit legend", "read off the
  curve", or "quoted in the text".

### 3. Reconstruct the logical structure
Group the day's work into threads. For each, collect: goal, method/conditions
(powers, fields, detunings, durations, tweezer depth, # shots/averages),
measurement numbers, the relevant figures, and the raw result.

### 4. Draft the analysis
For each thread write 2–5 sentences: **investigated → observed (quantitative)
→ interpretation (hypothesis).** Use the lab's vocabulary precisely: Rabi
frequency $\Omega$, Rabi/coherence decay $\tau$, quality factor
$Q=\Omega\tau$, Ramsey $T_2^\ast$, spin-echo, XY8 dynamical decoupling and
filter frequency, Landau-Zener ($P\propto\Omega^2/\alpha$), randomized
benchmarking (native vs Clifford, $\epsilon_\text{gate}$, $\epsilon_\text{spam}$),
Lamb-Dicke factor $\eta$, magic wavelength / magicness, probe shift, sideband
(SB) spectroscopy, survival/occupation probability, SPAM. Bring in scaling
arguments ($\Omega\sim B\sqrt P$, $\omega_\text{trap}\sim\sqrt P$,
$\eta\sim P^{-1/4}$) and compare to theory or papers when the entry invites it.

### 5. Validate interactively with the experimentalist (default mode)
Before writing anything to the wiki:
- Present the proposed thread structure, the key numbers you read, and — as a
  bulleted list — **each interpretation phrased as a question**, e.g.
  *"The Rabi decay is faster at high Rabi but Q still rises — I read this as
  phase-noise-limited (filter-function picture). Consistent with your view, or
  is there a competing explanation?"*
- Iterate on the answers. Keep a running list of confirmed vs open points.
- Any interpretation still unconfirmed at write time stays in the text but is
  marked `⚠ hypothesis — to confirm` so a human can resolve it later.
- (If the user prefers "interview first": ask all clarifying questions up front,
  then write once. Ask which mode they want if unclear.)

### 6. Write the Summary section
- `core_getPage` the entry again (fresh), insert a `===== Summary =====`
  section near the **top** (after the title/tags, before the detailed log),
  and `core_savePage` the full text back. Preserve everything else verbatim.
- Lock during the edit (`core_lockPages` → save → `core_unlockPages`).
- Set a clear edit `summary` (e.g. "Add logical-order summary + analysis"),
  `isminor:false`. Edits are attributed to the shared `llm` user, so the
  summary line is the only provenance.
- **Tag the addition `user:ai`.** The Summary's `{{tag>...}}` line must include the
  `user:ai` tag (see format) — all agent-added content carries it so AI-generated
  contributions are searchable and clearly marked.
- **Confirm the target page and show the drafted section before saving.**

## Summary section — format

```
===== Summary =====
{{tag>user:<experimentalist> project:<X> project:<Y> user:ai}}

//One-sentence framing of the day's goal.//

==== <Thread 1, logical name> ====
  * **Investigated:** ...
  * **Result:** ... (Ω = ... Hz, τ = ... ms, Q = ...; read off meas. #NNNN)
  * **Interpretation:** ...  ⚠ hypothesis — to confirm
  * See detailed log below / [[<linked entry>|related work]].

==== <Thread 2> ====
  ...
```
- Use DokuWiki syntax and LaTeX math (`$...$`) as the exemplar does.
- Reference measurement numbers and link related lab-book entries and papers.
- Reuse (don't duplicate) key figures with small widths if a plot is essential
  to the point; otherwise point to the log section.

## Reading plots — interpret, don't analyze

The plots are already-produced results. You read them to *interpret* them.

- **Do:** read axis labels/ranges, curve shapes and trends, fitted lines and
  their legend parameters, error bars, violin/point distributions, annotations —
  and reason physically about what they mean.
- **Don't:** re-fit, recompute statistics, or re-plot. That is deliberately a
  different workflow (separate repo + SKILL.md), and the figures here are its
  output — treat the plotted fits and quoted numbers as given. If a result looks
  like it needs recomputation, a different fit, or a new plot, raise it as a
  question/handoff to the experimentalist and their analysis workflow; do not
  attempt it here.
- If a needed plot is unreadable at the embedded resolution, fetch the
  full-resolution media and re-view before drawing conclusions. (A future SVG
  export would make figure text crisper; it does not change this skill's scope.)

## Scope

One daily entry per run. (Aggregating several days into a multi-week project
summary like `clock_ila_2025` is a natural extension but a separate task —
don't do it unless asked.)
