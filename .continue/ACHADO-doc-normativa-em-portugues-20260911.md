# Finding — a repository whose *normative documentation* is Portuguese has no row in §8

> **Measured on 11/09/2026, in EOP.** This is a finding, not a fix. §8 is the fleet's
> language norm and it is echoed into nine repositories by the regenerator, so the
> change belongs here and in the spec — never in the echo, where it would be
> overwritten on the next pass.

## What happened

`EOP/CLAUDE.md` carries **two rules that contradict each other**, three hundred lines
apart:

- **Golden rule 10** (the repository's own): *"Idioma: **pt-BR** em docs/ADRs (exceção:
  `README.md` raiz em inglês, espelhado em `README_br.md`)"*.
- **§Language**, which is *inside* the `RELEASES-RULE:repodocs` echo block and therefore
  regenerated from this repository: *"Everything that lives in this repository … is
  written in English (US): documents, commit messages, …"*.

The owner's verdict on 11/09 was **golden rule 10 wins for EOP**: `docs/` and the ADRs
stay pt-BR, commit messages and the changelog stay English. That is also what the disk
has done since `1.76.155` — so the practice was never in doubt; the **norm** was.

## Why §8 cannot absorb it today

§8 has exactly three carve-outs, and the finding is that **none of them is this shape**:

| carve-out | what it is about | fits EOP's `docs/`? |
|---|---|---|
| end-user-facing strings | **what kind of text** | no — an ADR is not product copy |
| the Blue3 internal repositories | **which repository**, all of its text | no — EOP's commits and changelog *are* English |
| `.continue/` drafts | **where in the lifecycle**, temporary by construction | no — `docs/` is the permanent record, the opposite end |

EOP is a fourth shape: **one repository, one directory, permanently** — the normative
documentation in Portuguese while everything the English rule exists for (commit
messages, changelog, release notes, PRs, issues, code comments) stays English.

⭐ **And the reason is the one §8 itself gives for the carve-outs it has.** The rule
exists *"for a reader who does not read Portuguese and meets our text first"*. EOP's
`docs/` is a 28-article Constitution, 97 ADRs and 34 domain dossiers of operational
reasoning — the same argument ADR-020 accepted for BLUE3-INTRANET, applied to a
directory instead of a repository.

## What this finding does NOT decide

⛔ **Whether §8 gains a fourth row, or EOP's `docs/` converts, is the owner's** — it is
a norm, and norms move by ADR here. Two shapes are visible, and they are not equivalent:

| # | shape | what it costs |
|---|---|---|
| **A** | §8 gains a row: *normative documentation of a named repository*, with EOP listed | one row and one ADR. ⚠️ A carve-out keyed to a **directory** is new — the existing three key on text kind, repository, and lifecycle |
| **B** | EOP's `docs/` converts to English over time, rule 10 is retired | ⛔ Nothing is rewritten by the rule (§8 says so), so the contradiction would live for as long as the conversion takes — which is the state that produced this finding |

## What was done in EOP meanwhile

**Nothing in the echo.** The `§Language` block is regenerated, so editing it there would
be undone on the next pass and would teach the next reader that the contradiction was
resolved when it was not. EOP got a **note outside the echo**, next to golden rule 10 and
immediately after the block, pointing here — the same mould the repository already uses
for its operational note about `release.sh`.
