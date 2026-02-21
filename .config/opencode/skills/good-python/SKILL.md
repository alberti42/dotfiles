---
name: good-python
description: Practical programming guidelines for writing good, future-proof Python code
license: MIT
metadata:
  author: Andrea Alberti (2026)
  version: 1.0.0
---

# Guidelines For Good Python Code

This document distills practical programming guidelines that emerged from a long,
hands-on refactor of a Python library.

The guiding theme is not "write clever code"; it is:

- make behavior explicit
- keep code small and test-backed
- remove anything you cannot explain and verify

These guidelines aim to be broadly useful, especially for scientific / exploratory
code that eventually becomes a real project.

## 1) Core Principles

### 1.1 Keep It Simple

- Prefer the smallest implementation that solves the problem.
- Avoid "framework" patterns unless the problem truly needs them.
- If the code looks absurdly complex for what it does, it probably is.

### 1.2 Avoid Untested Fallback Stacks

- Do not pile up "try this, then this, then this" recipes unless each branch is
  verified.
- Fallbacks are expensive: they grow code paths and hide the real behavior.
- If you must add a fallback, add a test for both the main path and the fallback.

### 1.3 Small Steps, Always Tested

- Change one thing at a time.
- Add the smallest test (or manual reproducer) that proves the behavior.
- Only keep code paths you can demonstrate.

### 1.4 Remove Dead Code Aggressively

- If you cannot explain what a block does, or you cannot observe its effect,
  delete it.
- Dead code is not "safety"; it is future confusion.

### 1.5 Prefer Explicit User Control Over Magic

- Avoid silent policy decisions (e.g., auto-selecting backends, auto-configuring
  environment variables).
- Provide helpers that make the explicit path easy, not automatic.

## 2) Workflow: From Idea to Clean Implementation

### 2.1 Start With a Reproducer

- Before refactoring, create a minimal script/test that shows the behavior.
- When the behavior is visual/interactive, create a manual harness.

### 2.2 Use "Prove Then Prune"

- When code is uncertain, do not refactor it first.
- First: test each block in isolation.
- Then: delete blocks that show no benefit.
- Finally: refactor the reduced code.

### 2.3 Prefer Evidence Over Documentation

- Vendor docs can be stale.
- If behavior matters, verify it empirically and/or with tests.
- Document what you observe and can reproduce.

## 3) Testing Strategy

### 3.1 One Test Per Claim

- If you state "X works", create a test (or a manual harness) that demonstrates X.
- Avoid tests that assert implementation details unless that detail is the intended
  contract.

### 3.2 Automated vs Manual Tests

- Automated tests are best for pure logic and stable APIs.
- Manual tests are legitimate for GUI behavior, but keep them:
  - single-purpose
  - easy to run
  - documented with expected observations

### 3.3 Headless Safety

- If your library might run on CI or servers, ensure tests do not require GUI.
- Force a non-GUI backend in tests (e.g., MPLBACKEND=Agg) when appropriate.

### 3.4 Warn-Once Behavior

- If you intentionally ignore errors (best-effort integrations), ensure you:
  - warn in a controlled way (warn-once)
  - keep behavior deterministic
  - never spam loops

## 4) API Design: Compatibility, Clarity, and Scope

### 4.1 Drop-In Means "Same Signature" Where It Matters

- If you claim drop-in replacement, keep the call pattern compatible.
- If you add extra behavior, prefer separate functions rather than mutating a
  familiar API into something surprising.

### 4.2 Split Global vs Per-Object Semantics

- Identify what acts on "the whole environment" vs "a single object".
- Example pattern:
  - show(): global "tick" / session-level behavior
  - refresh(fig): figure-level behavior
- This reduces confusion and prevents adding figure-specific flags to a global API.

### 4.3 Avoid Custom Aliases That Reduce Portability

- Non-standard keyword aliases can make code harder to revert to upstream libraries.
- If you add an alias at all, document the portability cost.
- Better: do not add it unless it carries meaningful value.

### 4.4 Keep Public Surface Small

- Each exported function is a maintenance commitment.
- If a wrapper does nothing but call upstream, remove it.
- Prefer "use upstream directly" for figure creation/config.

## 5) Fallbacks and Environment-Specific Behavior

### 5.1 Default: No Fallbacks

- Fallbacks are allowed only when you can prove they matter.
- Otherwise, fail clearly and let the user choose.

### 5.2 When You Must Be Best-Effort

- Some behavior is inherently backend/OS dependent (GUI window raising, etc.).
- In that case:
  - make it opt-in
  - keep it isolated in a small module
  - do not crash if it fails
  - provide a clear status for debugging

### 5.3 Do Not Pretend to Control the Environment

- If user tools (e.g., IPython magics) can set state, respect it.
- Provide helpers that return recommendations rather than enforcing policy.
- Example:
  - recommended_backend(respect_existing=True)
    returns a suggestion while honoring an already selected backend.

## 6) Documentation That Teaches "Why"

### 6.1 Prefer Declarative Explanations

- Start with: who is this for, when it helps, and what workflow it enables.
- Only then: show the mechanics.

### 6.2 Keep Jargon Out of the First Screen

- The introduction should be understandable without knowing internal terms.
- Introduce terms ("backend") with a one-line explanation and a link.

### 6.3 Write Docs That Match Reality

- If upstream docs are wrong or ambiguous, do not mirror them.
- Verify behavior and document what actually happens.
- When behavior depends on platform/version, say so.

### 6.4 Provide Minimal and Robust Patterns

- When there is a "minimal" approach and a "robust" approach, show both.
- Label them explicitly.
- Example:
  - minimal: input() with isatty() guard
  - robust: hold_windows() pumping GUI events

## 7) Naming and Semantics

### 7.1 Name by User Intent

- Prefer names that describe what the user wants, not how it is implemented.
- Example: in_foreground=True
  - expresses intent
  - avoids leaking "window raising" mechanics

### 7.2 Avoid Names That Collide With Existing Meanings

- If a dependency uses a term differently (e.g., Matplotlib's "force"), do not
  reuse that word for a different meaning.
- Choose a clearer name (respect_existing) over a "familiar" but misleading one.

### 7.3 Prefer Keyword-Only for APIs With Behavioral Flags

- Keyword-only parameters improve readability and reduce accidental misuse.

## 8) Refactoring Tactics That Work

### 8.1 Refactor After Deleting

- The best refactor is to delete code first.
- Only then reorganize and rename.

### 8.2 Move Low-Level Helpers Out of Core Logic

- Put "plumbing" (warn-once, environment detection) into helper modules.
- Keep core user-facing behavior readable.

### 8.3 Keep Imports Lazy When They Affect Global State

- GUI libraries and matplotlib backends can have side effects.
- Import pyplot inside functions when possible.
- If a dependency is mandatory, fail early and clearly.

## 9) Packaging and Releases

### 9.1 Pin Versions for Reproducibility

- Installation from git should encourage pinning tags.
- Prefer git tags like vX.Y.Z while package version remains X.Y.Z.

### 9.2 Automate Releases

- CI should build sdist+wheel and attach to a GitHub release on tags.
- Validate that tag version matches project version.
- Run tests in CI in a headless-safe way.

### 9.3 Keep Distributions Minimal

- Wheels should contain only the runtime package.
- sdists should exclude developer assets (venv, tests, examples, bin scripts)
  unless they are intended as part of the distribution.

## 10) A Practical Checklist

Before merging a change:

- Can I explain the change in one sentence?
- Is there a test (or manual harness) proving the behavior?
- Did I remove at least as much complexity as I added?
- Is the public API still coherent?
- Does documentation explain "why" before "how"?
- Are there any new fallbacks that are untested?

## Appendix: Minimal Templates

### Minimal warn-once:

- Use a module-level set of keys.
- Emit a warning once per key.

### Minimal interactive detection:

- Detect IPython via __IPYTHON__
- Detect REPL via sys.ps1
- Detect python -i via sys.flags.interactive
