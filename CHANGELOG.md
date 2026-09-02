# Changelog

Entries in the commit-message format (`versão - comentário em português`, see
[docs/versioning.md](docs/versioning.md)), newest first. **Each `##` heading is
literally the commit subject** — this file is the handoff artefact between
whoever does the work and whoever commits it.

Bodies are narrative: what changed, why, and what was measured. This file is
never rewritten.

## 1.0.1 - o LICENSE bilingue custa o selo MIT do GitHub, medido

Um push é o único jeito de medir o que o GitHub faz com um `LICENSE`, e a
medição contradisse a expectativa.

**O que foi medido.** Depois do push da `1.0.0`, `gh repo view` devolveu
`licenseInfo: Other` — não `MIT License`. O mesmo vale para SHVIA-WEB,
SHVIA-SITE e BLUE3-AI-LOGIN, os três que carregam o mesmo texto bilíngue.
Controle: `skill-LOOP`, que carrega o MIT puro em inglês, é detectado como
`MIT License`.

**Por que.** O detector do GitHub compara o arquivo inteiro com um template de
licença. A metade em português derruba a similaridade abaixo do limiar dele. A
licença **é** MIT nos dois casos — o que se perde é o selo na barra lateral e a
detectabilidade via API.

**O que mudou aqui.** Nada no LICENSE: a escolha do bilíngue foi deliberada e
segue valendo. O que mudou é que o custo dela está medido em vez de suposto —
[ADR-006](docs/decisions.md) ganhou a seção do custo, e a decisão de manter ou
inverter entrou na fila em [.continue/README.md §3](.continue/README.md) como
chamada do dono. A inversão, se vier, espelha o par `README.md`/`README_br.md`
que a frota já usa.

**Também confirmado no mesmo push:** o `SECURITY.md` na raiz funcionou — o
`securityPolicyUrl` do repositório passou a existir.

## 1.0.0 - estrutura inicial de documentação do padrão da frota

The first real content of `repodocs`, which until now was one commit and an
11-byte `README.md`. GitHub's own description of it — *"Documentation for new
repository"* — already said what it was for; this release makes it true.

### What this settles

The standard existed, but only as a pattern to be inferred by opening sixteen
repositories and noticing what they had in common. The measurement:

| Convention | Evidence across the fleet |
|---|---|
| `LICENSE`, no extension | 41 files against **1** `LICENSE.md` |
| `NOTICE`, no extension | 11 files, zero `NOTICE.md` |
| `version.md`, lowercase, bare `X.Y.Z` | 63 files against 1 `VERSION` |
| MIT bilingual PT/EN, `Copyright (c) 2026 Samir Hanna Verza` | byte-identical in 14 repositories |
| Commit `versão - comentário em português` | normative in EOP, SHVIA-DESKTOP, SHVIA-SITE, SHVIA-WEB, BLUE3-INTRANET |
| `CLAUDE.md` + `AGENTS.md` identical below the H1 | EOP and SHVIA-DESKTOP (BLUE3-INTRANET symlinks; SHVIA-WEB diverged on purpose) |

An inferred standard is a standard that drifts. It is now written once, in
English, at [docs/conventions.md](docs/conventions.md).

### The move that mattered

`BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` (157 lines, written 29/08/2026)
already declared itself *"fonte única, vale para todos os repos da frota"* — and
its own §7 admitted the problem: the source of a fleet-wide norm was a path
inside one product repository. **That is the exact failure the document was
written to prevent**, applied to itself: a rule that lives inside one repo is
invisible to whoever opens another.

It moved here, translated, extended with what it lacked (the root-file standard,
the status vocabulary, the language rule and its carve-outs) — [ADR-001](docs/decisions.md).
The INTRANET copy has **not** been touched yet, so two copies exist and this one
is the source; retrofitting the pointer is a separate, explicit pass.

### Two contradictions settled rather than copied

Both were found while measuring, and both were live:

- **`SHVIA-WEB`** — its `LICENSE` says MIT under `Copyright (c) 2026 Samir Hanna
  Verza`, while its `NOTICE` says *"Copyright (c) Blue3. Proprietary software;
  see LICENSE."* Those cannot both be true. This repository's `NOTICE` agrees
  with its `LICENSE`, and [ADR-006](docs/decisions.md) makes that a rule.
- **`BLUE3-INTRANET`** — its `README.md` states *"the old `version.md` was
  removed in favour of this env var"* while `version.md` is still present and
  its own `CLAUDE.md` calls it the source of truth with the env var as fallback.
  [ADR-002](docs/decisions.md) makes `version.md` the sole authority and forbids
  a document from claiming otherwise. Two documents disagreeing about one number
  is how a wrong deploy gets signed off.

### What was created

- **Root:** `README.md` (rewritten), `version.md` (`1.0.0`), the
  `CLAUDE.md`/`AGENTS.md` twins, `SECURITY.md`, this file, `LICENSE` (copied
  byte-for-byte from the fleet's), `NOTICE`, `.gitignore`.
- **`docs/`:** `conventions.md` (the norm), `versioning.md`, `decisions.md`
  (ADR-001…009), `security.md` (English successor to `SECURITY_GUIDELINES.md`
  v1.1), `runbook.md`, `README.md` (index).
- **`.claude/`:** the fleet Opus profile with a 17-rule deny-list, and a
  `README.md` explaining why the deny-list beats the allow-list.
- **`.continue/`:** the queue, with the `README.md` that §2 of the norm makes
  mandatory.
- **`tools/git-hooks/`:** `commit-msg` and `pre-push`, on the EOP topology.
- **`templates/skeleton/`:** the placeholder copy of the whole set, so a new
  repository is `cp -r` plus one substitution pass.
- **`.github/`:** `CODEOWNERS` and `dependabot.yml`. Deliberately no workflow —
  [ADR-009](docs/decisions.md): a red CI on a documentation repository teaches
  people to ignore CI.

### Measured

The hooks were exercised in both directions before shipping: `feat: teste`
rejected, `1.0.0 - <comentário>` accepted, a duplicate version against
`origin/master` rejected, `REPODOCS_NO_HOOK=1` bypassing both, and an
unreachable remote degrading to a warning rather than a refusal. `LICENSE` is
byte-identical to `SHVIA-WEB/LICENSE`; the twins diff clean below the H1.

### What is left

The queue is [.continue/README.md](.continue/README.md). The open item is not
work in this repository — it is the retrofit pass into the sibling repositories,
which is the owner's call to schedule.
