# Writing

Applies to everything I write for a reader: documentation, docstrings, comments, commit messages, and my replies.

## Five rules

1. **Name the actor and the action.** Never a figure of speech where a verb belongs.
   - "To see the exchange, ask for it first" → ask *whom*? Say: "switch the logging on."
   - "It leaves the server binary to you" → *who installs it, how?* Say: "you download it yourself and tell the package where it is."
   - "The front-end is let go of" → "the flymake backend is removed."

2. **Reuse the wording a fact already has.** If a document states something once, find that sentence and repeat it rather than inventing a new phrasing. A reader who meets two phrasings of one fact has to work out whether the difference means anything. Documentation is not a novel; varying words to avoid repetition is a mistake here, not a virtue.
   - Established: "does not depend on `lsp-mode`, or on any other Emacs package." Do not later write "has no framework underneath it."

3. **Stop when the information stops.** The default shape I reach for ends every sentence on a small turn or a parallel. Cut it.
   - "That is one job fewer for the package, and one fewer way for it to fail" → "That keeps the package smaller and gives it fewer ways to fail."
   - "for reasons of safety rather than taste" → "for safety."

4. **Do not negate something nobody said.** "Not because a second option seemed worth having" answers a question the reader never asked. Say what happened.

5. **Give the number, not a paraphrase of the number.** If a table says 0.2 s, the prose says 0.2 s — not "under a fifth of a second". Same for units already chosen elsewhere.

6. **Do not inflate.** No superlatives, no intensifiers, no praise of the work I just did. "This is so much better", "a dramatic improvement", "perfect" — drop the adjective and state what changed. The same goes for the reader's work: describe it, do not rate it. Accurate size, in both directions: a one-word fix is a one-word fix.

## Two checks before I write a sentence

- **Can a reader check this and find it false?** "Lightweight", of five thousand lines of code. Then don't write it.
- **Can I delete the second half without losing information?** Then delete it.

## Openings

Do not tease what a sentence is about to explain. "Two things happen between your keystroke and the underline, and only the second one is the grammar checker" makes the reader wait; "Two things happen between your keystroke and the underline: the client waits until you stop typing, then the server checks the document" tells them.

## Where the facts live

When a fact is already written somewhere — a docstring, another section, an earlier commit — open that place and copy the sentence. Do not restate it from memory in new words.

# Commits

Do not add a `Co-Authored-By: Claude …` trailer, or any other Claude or Anthropic attribution, to commit messages or pull requests. `attribution` in `~/.claude/settings.json` is set to empty strings for this reason.
