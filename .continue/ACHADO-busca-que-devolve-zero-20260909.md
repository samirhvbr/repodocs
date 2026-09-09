# Finding — a search that returns zero needs a positive control before it becomes a conclusion

> **Measured on 09/09/2026.** This is a finding, not a fix. It is a rule about **method**,
> it applies to every repository of the fleet, and its home is the template — which is why
> it is registered here and not in the repository that happened to trip over it.

## The lesson

> **A search that returns zero requires a positive control before it becomes a
> conclusion: look for something you KNOW exists, using the same pattern. If the control
> also returns zero, the pattern is wrong — not the repository.**

## What happened

In `SHVIA-WEB`, a sweep was asked for after a real defect: a cleanup listener had been
hooked on `deleted` for a model that soft-deletes, so trashing a project destroyed its
GitHub scope and **restoring it silently widened** the project's reach. The question was
the obvious follow-up — *which other models with `SoftDeletes` have a listener on the
wrong event?*

The first step was to count the models that soft-delete:

```bash
grep -c 'use SoftDeletes;' app/Models/<Model>.php
```

It answered **0** for `Conversation`, `Message` and `Workspace`. All three soft-delete.
They write it as:

```php
use HasFactory, SoftDeletes;
```

Three of the five soft-deleting models were about to be reported as not soft-deleting, in
a table whose entire purpose was to say where the defect could repeat.

## Why this class of failure is the expensive one

**`0 occurrences` is a plausible answer and is indistinguishable from `does not exist`.**
The pattern did not error. It did not warn. It returned a number, and the number was the
same number the correct search would return in a healthy repository. The instrument
answered *"nothing here"* when the honest answer was *"I did not look there"*.

It is the same silence this standard already names in three other shapes — a test that
skips and reads as passing, an allowlist that is green because it is incomplete, a review
panel that agrees because all of it inherited one wrong premise. What makes the search
case worse is that the output of a correct search and the output of a broken one are
**byte-identical**.

⚠️ **And the trap is in the direction of the check nobody runs.** A search that returns
too much gets noticed immediately — the reader has to wade through it. A search that
returns too little gets *believed*, because it looks like the good outcome.

## The owner's count: six in one week

The owner counted six instances of an instrument answering something plausible instead of
failing, within a single week: the mirror corpus, thirteen tests with `tokens:0`, a
writable `/tmp`, `rebase --continue`, a `sandboxMode` discarded in silence, and this one.

> 🔬 **Provenance, per §16.** Only two of the six were measured by this session: the
> `SoftDeletes` grep above, and the `rebase --continue` table in
> [`ACHADO-commit-msg-no-rebase-20260909.md`](ACHADO-commit-msg-no-rebase-20260909.md).
> The other four are the owner's count, **not verified here** — they are listed because
> the shape repeating is the finding, and a list of one is an anecdote. Whoever writes the
> spec should measure them rather than inherit them from this line.

## The control is cheap, and it was run on this very document

Writing this finding required checking whether a term the owner referred to — `D-NOVA` —
existed anywhere. It did not appear. **That zero was not trusted until the same search
found something known to exist:**

```
# control: something known to be there, same pattern, same paths
$ grep -rl "GH-F2" repodocs SHVIA/SHVIA-WEB-github --include="*.md"
SHVIA/SHVIA-WEB-github/CHANGELOG.md
SHVIA/SHVIA-WEB-github/.continue/README.md
SHVIA/SHVIA-WEB-github/.continue/FILA-20260827.md

# then the real question, same pattern
$ grep -rl "D-NOVA" repodocs SHVIA/SHVIA-WEB-github --include="*.md"
(nothing)
```

The control passed, so the zero is a real zero. Widened to all of `~/x` with its own
control, the answer holds: **`D-NOVA` is not written down anywhere in the fleet.** It is
a term the owner uses that has never been recorded — which is itself worth knowing, and
is precisely the kind of thing an uncontrolled zero would have reported with the same
confidence.

## Adjacent finding: the three loose lessons are **not** at the risk they were thought to be

The owner's note said three fleet-wide lessons sit in `SHVIA-WEB/AGENTS.md` where *"the
next `fleet.sh echo` may overwrite them"*. **Measured: it cannot.**

`stamp_block()` in `tools/fleet.sh` replaces only what lies **between** the markers
`<!-- NAME:repodocs -->` and `<!-- /NAME -->`; every other line is copied through by the
same `awk`. In `SHVIA-WEB/AGENTS.md` (1482 lines) the markers are at **1342–1402**
(`COMMIT-RULE`) and **1438–1482** (`RELEASES-RULE`). The method sections are all above
line 1342 — outside every block. Two of the four declared blocks (`QUEUE-RULE`,
`LANGUAGE-RULE`) are missing from that file, and when `echo --apply` inserts them it
inserts *before the first existing marker*, so it appends rather than overwrites.

**The instinct was right and the mechanism was not**, and the real risk is worth stating
because it does not close by itself:

- **It is not overwriting — it is non-arrival.** A fleet-wide lesson living in one
  repository's `AGENTS.md` never reaches the other eight. Nothing carries it there, and no
  check reports its absence.
- **`templates/skeleton/AGENTS.md` is the file that would lose them**, on a re-seed rather
  than on an `echo`. That is a rarer event and a total one.

> This is the same reasoning that put this document in `repodocs` instead of in the
> repository that found it. A lesson about method that lives in one repository is a lesson
> eight repositories do not have.

## A lead, not a decision

The lesson is prose, and prose is an instruction — it protects whoever does not know. What
would make it a guard is narrower than it looks, and the spec has to choose:

- **A search that reports its own control.** A wrapper that refuses to print `0` without
  having first matched a known-present sentinel. Cheap, and it only covers searches that
  go through the wrapper — which is not how anybody greps.
- **The rule at the point of conclusion, not of search.** The place a zero becomes a
  decision is a table, a checklist or a report. That is where *"was this zero controlled?"*
  belongs, and it is a review question, not a script.

⚠️ **Do not write it as *"be careful with grep"*.** Every one of the six instances was
produced by somebody being careful; the pattern was chosen *because* it looked right. The
usable form is the positive control, because it does not depend on suspecting the pattern
— it depends on running one extra command whose expected output is known in advance.
