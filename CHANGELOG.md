# Changelog

Entries in the commit-message format (`versão - comentário em português`, see
[docs/versioning.md](docs/versioning.md)), newest first. **Each `##` heading is
literally the commit subject** — this file is the handoff artefact between
whoever does the work and whoever commits it.

Bodies are narrative: what changed, why, and what was measured. This file is
never rewritten.

## 1.4.0 - the default branch is `master`, never `main`

Census of the 51 fleet repositories, 03/09/2026: **43 on `master`, 7 on `main`,
1 on `dev`**. The seven are not a decision — they are repositories created after
GitHub changed its own default, inheriting whatever the button gave them.

### Why uniformity is the point

Git does not care. Every script, runbook, hook and workflow that wants "the
default branch" does: it either hardcodes one and is wrong for part of the
fleet, or resolves it at runtime and carries a fallback chain forever.
`tools/release.sh` does the latter today **because** the fleet is mixed. This
ADR is what lets those fallbacks be deleted later.

### It already broke something, in this rollout

`samirhvbr/samirhvbr` has GitHub's default at `master` and only `master` on the
remote — but a **stale local `origin/HEAD` still pointing at `origin/main`**. The
fleet sweep read it, derived `main`, pushed `HEAD:main` and was refused. The
failure reads like a permissions problem and is actually a branch name.

Fixed with `git remote set-head origin -a` — the step everyone skips when
renaming a branch, and the one that causes this exact class of failure.

### The rule

`master` is the default branch of every repository here. A repo created as `main`
is renamed with GitHub's own rename (it preserves open pull requests and
redirects old links), and every existing clone is repointed — including
`set-head`.

A different branch is allowed **when it is a written decision**:
`blue3-intranet-ntheme` works on `dev` and says so in its own `version.md`. A
repo sitting on `main` because that is what the button did is not a decision.

### Suggested, not swept

Renaming a default branch is outward-facing: it touches clone instructions, CI
configs that name the branch, and bookmarks to branch URLs. GitHub's rename
covers PRs and redirects; it does not fix a collaborator's clone or a workflow
file that hardcodes `main`. So the seven are **listed for the owner to
schedule**, not renamed on the strength of a convention:

`blue3-debian-custom-iso` · `blue3-ai-login` · `MIGRANDO-ZIMBRA-CARBONIO` ·
`shvia-bench` · `shvia-rota` · `shvia-site` · `shvia-workspace`

Written up in [ADR-015](docs/decisions.md), `docs/conventions.md` §7, the
`CLAUDE.md`/`AGENTS.md` twins and the skeleton.

## 1.3.1 - Agent doc: Releases rule and the English-only language rule

Marked echo of the single source at samirhvbr/repodocs. Two rules land here:

1. The `version.md` of the default branch ON GITHUB is what the GitHub Releases
   show, and a commit that bumps it is not finished until that version has a
   tag, a Release and the `Latest` badge — same push, not "later".
2. Everything in this repository is English (US): documents, commit messages,
   pull requests, issues, code comments. The only carve-out is end-user-facing
   product strings. History is not rewritten.

Delimited by a marker, so re-running replaces instead of duplicating.


## 1.3.0 - everything is English (US), commit messages included

The owner rejected the last language split, and the trigger was a commit this
very rollout had just written across the fleet:

> `1.0.1 - Regra de Releases no doc de agente: bump e Release sao um ato so`

> *"precisamos documentar a regra de que commits tambem, tudo em ingles"*
> *"todo commit em ingles, PR em ingles, issues em ingles, tudo ingles-US"*

### Why the split did not survive

ADR-005 put documents in English but kept commit messages in Portuguese,
reasoning that the commit convention was a separate per-repo rule. That reasoning
ignores where a commit message is actually read: `git log`, `git blame`, the diff
of a pull request, the body of a Release, and the changelog entry it was copied
from. It is exactly the surface the English rule exists for — the first thing a
collaborator or a tool that does not read Portuguese meets.

### The rule now

**Everything in a repository, and in GitHub's interface around it, is English
(US)** — documents, commit messages, PR titles and bodies, issues, code comments,
changelog entries, release notes.

**Exactly one carve-out remains:** end-user-facing strings — UI text,
transactional email, product copy. A Brazilian user does not read the repository.

That takes the carve-out list from three, to two after `LICENSE` fell in
[ADR-010](docs/decisions.md), to **one** here in
[ADR-014](docs/decisions.md).

### What was changed

`docs/conventions.md` §8, `docs/versioning.md` (format and examples),
`docs/README.md`, `README.md`, the `CLAUDE.md`/`AGENTS.md` twins, and the whole
`templates/skeleton/`. ADR-003's language clause is marked superseded rather than
edited away; ADR-005's carve-out list now points here.

### What enforces it, and what does not

`tools/git-hooks/commit-msg` checks the **shape** — `X.Y.Z - description`, no
Conventional Commits prefix, no vague one-word message — and its reject list
gained the English offenders (`cleanup`, `changes`, `tweak`, `stuff`,
`refactor`) next to the Portuguese ones already there.

It does **not** check the language, on purpose. Detecting language mechanically
is guesswork, and a guard that fires on a false positive is a guard that gets
bypassed with `--no-verify` — which disables every other guard with it. The
shape is mechanical; the language is the norm's job.

### History is not rewritten

Portuguese messages already in the fleet's history stay. `git log` will read
bilingual across the 03/09/2026 boundary, which is the same shape ADR-005
already accepted for documents, for the same reason.

## 1.2.4 - Regra de Releases no doc de agente: bump e Release sao um ato so

Eco marcado da norma unica em samirhvbr/repodocs (docs/versioning.md). O
`version.md` da branch padrao NO GITHUB e o que as Releases no GitHub mostram, e
um commit que bumpa o `version.md` nao esta terminado ate aquela versao ter tag,
Release e o badge `Latest`.

Bloco delimitado por marcador: rodar de novo substitui, nao duplica.


## 1.2.3 - o bump e a Release sao um ato so, e o badge Latest obedece ao version.md

Achado do dono, olhando o `sshvterm-desktop`: *"teve um bump para version.md
para 1.2.81 mas o Releases esta em 1.2.80"*.

### O que estava errado

A Release `1.2.81` **existia** — o workflow rodou e criou. O que estava errado
era so o **badge `Latest`**, parado na `1.2.80`. Varredura nos 51: tres repos
com o mesmo sintoma, e nos tres a Release existia. O pior era o `shvia-web`,
com `version.md` em `2.110.162` e badge em `2.16.38`.

### A causa foi minha

O backfill carimbava `--latest` na **ultima versao que aquela rodada conhecia**.
No `sshvterm-desktop` ele comecou lendo `1.2.80`, um push moveu o arquivo para
`1.2.81` no meio, e no fim ele empurrou o badge de volta para `1.2.80`. Correu
contra o proprio workflow — e ganhou a corrida errada.

### Duas correcoes no `release.sh`

1. **`--latest` so vai para a versao que o `version.md` nomeia**, nunca para "a
   ultima que esta rodada tocou".
2. Toda execucao termina **relendo o `version.md` do remoto e movendo o badge**
   se ele tiver derivado. Isso torna qualquer rodada auto-corretiva:

       release.sh: badge Latest movido de 1.2.80 para 1.2.81 (version.md manda)

Entao a pergunta *"este repo esta certo?"* virou um comando que tambem conserta:
`./tools/release.sh`.

### A regra que passou a estar escrita

**O bump e a Release sao um ato so.** Um commit que bumpa o `version.md` nao
esta terminado enquanto aquela versao nao tiver Release **e o badge**. Nao
"depois", nao "quando alguem lembrar" — no mesmo push. Esta em
`docs/versioning.md`, no gate de fechar versao do `docs/conventions.md`, nos
gemeos e no skeleton.

O badge nao e cosmetico: quem olha le como *"esta e a versao corrente"*, e um
badge numa Release velha afirma algo falso sobre o projeto.

### Um erro de operacao que vale registrar

Eu editei o `release.sh` **com ele rodando** no backfill do `shvia-web`. O bash
le o arquivo em pedacos, o deslocamento quebrou a sintaxe no meio da execucao
(`syntax error near unexpected token` na linha 226) e a rodada morreu em
`2.16.71` de 764. Retomada com uma **copia congelada** do script — o backfill e
idempotente, entao ela continuou de onde parou, mas o certo era congelar antes.

## 1.2.2 - o remoto e a autoridade: version.md do GitHub = Releases do GitHub

Correcao do dono, e ela apagou uma ambiguidade que eu tinha deixado em pe:

> *"no github o Releases tem que estar na mesma versao do version.md, e meio
> logico, esquece o local"*

O `release.sh` estava lendo o `version.md` da **arvore local**. Passa a ler do
**`origin/<branch padrao>`** e a taggear aquele commit, caindo para `HEAD` so
quando o ref remoto nao resolve — que e o caso do CI, onde o `HEAD` **e** o
commit pushado. Arquivo local divergente vira uma nota, nao uma Release
diferente.

### Por que isso nao era detalhe

Medido no mesmo dia: o `sshvterm-desktop` tinha `1.3.19` local contra `1.2.80`
no remoto (8 commits nao pushados), e o `shvia-web` tinha `2.110.154` local
contra `2.110.161`. Publicar da arvore local taggearia **commit que o GitHub nao
tem**. O guard anterior (recusar quando a arvore diverge do HEAD) tratava o
sintoma; a regra do dono elimina a pergunta.

### O que isso resolve de graca

O fluxo de PR passa a funcionar sem ninguem lembrar de nada: uma branch em
`1.3.25` **nao publica nada** enquanto e branch; no merge, o push do `version.md`
para a branch padrao dispara o workflow e a Release vira `1.3.25`. O merge e o
evento.

### Tambem nesta versao

- **`sshvterm-desktop`, o unico repo da frota com pipeline amarrado em tag.** As
  17 Releases dele eram de junho, tituladas `ShvTerm v0.5.41`, com **178
  instaladores e 10.184 downloads**. Os titulos foram para o padrao (so o
  numero); **nada foi apagado** e os binarios estao intactos. O `v` da tag ali
  **faz trabalho**: o `main.yml` dispara em `tags: ['v*']` — e por isso o
  proximo passo e o gatilho aceitar as duas formas, nao trocar de forma.
- **O `release.sh` deixou de duplicar Release.** Uma versao conta como publicada
  sob **qualquer um dos dois nomes**: criar uma `0.5.41` pura ao lado da
  `v0.5.41` que ja tem binario nao consertaria nome nenhum — duplicaria a versao
  e a copia sairia **sem os instaladores**. No `sshvterm-desktop` isso muda o
  backfill de 227 para **210 criadas e 17 puladas**.

## 1.2.1 - o censo completo derruba o numero que a 1.2.0 publicou

A `1.2.0` afirmou *"54 repositorios, zero Releases publicadas, e tres tags entre
todos eles"*. **Errado.** Aquele numero saiu de uma varredura parcial — a
caminhada local em `~/x` mais a org BLUE3-ISP — e **perdeu o SSHVTERM-DESKTOP
inteiro**.

### O numero real, do censo dos 52 repos com `version.md`

| | |
|---|---|
| Sem nenhuma Release publicada | **50 de 52** |
| Sem nenhuma tag de versao | **47 de 52** |
| Versoes distintas na frota | **~2.764** |
| EOP + SHVIA-WEB | **1.591 delas — 55% do total** |

E cinco repos **ja fazem isso**, todos com prefixo `v`: `SSHVTERM-DESKTOP` (22
tags e **17 Releases publicadas**, tituladas `ShvTerm v0.5.41`),
`brasileirao-a-2026` (17 tags), `blue3-wcup-2026` (3), `blue3-f1` (1), e o
`docsys_blue3` (19 tags, 18 Releases), que e do Rodrigo e esta fora desta frota.

### A consequencia que agora esta escrita

Mostrado o numero, o dono confirmou a decisao: **tag pura em todos, inclusive
nesses cinco**. A consequencia e real e fica dita de frente no
[ADR-011](docs/decisions.md): o SSHVTERM-DESKTOP vai ter `v0.5.41` com a Release
*"ShvTerm v0.5.41"* **convivendo** com uma `0.5.41` nova — a mesma versao
alcancavel por dois nomes. As tags velhas **nao sao apagadas**: apagar orfanaria
17 Releases que ja existem e que alguem pode ter linkado.

### Um defeito que o censo pegou no `release.sh`

O `--current` taggeava o HEAD com a versao lida da **arvore de trabalho**. Oito
repos da frota estao agora com o `version.md` bumpado e **nao commitado** — o
SHVIA-WORKSPACE esta 14 versoes a frente do ultimo commit. Nesses, o `--current`
teria criado uma tag apontando para um commit que nao contem aquela versao.

Agora ele recusa e explica, e diz que o `--backfill` e seguro ali (ele le o
historico, nao a arvore). Testado nos dois sentidos.

### Outros dois achados do censo, ainda abertos

- **SHVIA-WEB local esta 18 commits atras do origin** (local `2.110.154`, origin
  `2.110.161`). Backfill a partir do checkout velho perderia 8 versoes.
- **SHVIA-OLLAMA tem `version.md` nao rastreado pelo git** (`1.2.0`), enquanto a
  ultima versao commitada e `1.1.1`.

Ambos estao na fila em [.continue/README.md](.continue/README.md).

### Por que isto virou entrada propria em vez de conserto silencioso

O CHANGELOG nao e reescrito — e a regra da casa, e ela vale principalmente
quando o que esta escrito e o **erro**. A `1.2.0` fica como esta; esta entrada
diz o que estava errado e o ADR-011 ganhou o aviso apontando para ca. E a
terceira vez seguida que medir contrariou o que este repositorio tinha escrito.

## 1.2.0 - toda versao vira tag e Release, e a regra do version.md sai do papel

O quadro **Releases** do GitHub estava vazio em **todos os 54 repositorios** da
frota, e a causa nao era descuido: o GitHub nunca deduz versao de mensagem de
commit. Um repo com mil commits `2.110.161 - ...` continua dizendo *"No releases
published"*, e `git diff 2.110.160..2.110.161` falha porque **nenhum dos dois
nomes existe como ref**.

### O que foi medido antes de escrever qualquer regra

| Repo | commits | versoes distintas | tags | Releases |
|---|---|---|---|---|
| SHVIA-WEB | 1085 | 756 | 0 | 0 |
| EOP | 840 | 827 | 0 | 0 |
| SHVIA-DESKTOP | 1035 | 98 | 1 | 0 |
| BLUE3-INTRANET | 982 | 150 | 0 | 0 |
| SSHVTERM-WEB | 135 | 75 | 0 | 0 |

Tres tags em 54 repositorios, e zero Releases. Dois repos ja carregavam a divida
**por escrito** no proprio `version.md`: o `blue3-f1` diz *"Ao publicar, taggear
`v0.3.0`"* e o `brasileirao-a-2026` diz *"⚠️ Sem tag `v0.16.0` no git"*.

### A regra que este repositorio publicou errada

O `docs/versioning.md` e o ADR-002 afirmavam que o `version.md` e *"uma string
`X.Y.Z` pura e nada mais"*. **Falso para um terco da frota.** Nove repos do
BLUE3-ISP e o proprio skill-COMMITTER tem um `version.md` que e um documento
markdown inteiro, abrindo com `**Versao atual:** \`0.17.1\``; o
`blue3-intranet-mobile` tem duas linhas (`2.1.9` e `api_min: 0.1.0`).

Esses repos ja documentavam a regra de verdade — *"extrai o primeiro numero
semver encontrado aqui"* — e o `config/app.php` deles ja implementava com
`preg_match('/\d+\.\d+\.\d+/')`. **A versao e o primeiro semver do arquivo**
([ADR-012](docs/decisions.md)), e o ADR-002 fica emendado, nao apagado.

E a segunda vez que uma norma daqui foi contrariada pela frota — a primeira foi o
`LICENSE` bilingue custando o selo MIT (`1.0.1`). As duas apareceram medindo, nao
relendo.

### O que passou a existir

- **`tools/release.sh`** — a implementacao unica: `--current`, `--backfill`,
  `--dry-run`. Idempotente e retomavel por construcao (pula o que ja existe),
  com throttle e parada limpa quando o orcamento de API baixa.
- **`.github/workflows/release.yml`** — dispara a cada push que toca o
  `version.md` e **chama o script**, em vez de reimplementar as regras: duas
  copias de uma regra e como uma regra passa a ter duas versoes, uma errada.
- **ADR-011** (tag e Release por versao), **ADR-012** (primeiro semver),
  **ADR-013** (workflow de release nao e workflow de CI — o ADR-009 fica
  estreitado para proibir so build/teste, com o motivo: CI vermelha em repo de
  documentacao ensina a ignorar CI, e este workflow e silencioso no caso normal).

### A tag nao leva `v`

Decisao do dono. Diverge das tres tags que a frota ja tem (`v0.15.0` e uma na
SHVIA-DESKTOP), que **ficam como historico**; o que sera corrigido sao os dois
`version.md` cujo texto ainda manda usar `v` — documento contradizendo o artefato
e o defeito, nao a tag velha.

### Medido neste repo

Backfill rodado: `1.0.0` → `b5bc824`, `1.0.1` → `e8131fe`, `1.1.0` → `654c999`,
com as notas vindas da secao real do CHANGELOG (a extracao foi corrigida para
parar so num heading do mesmo nivel ou acima — na primeira versao ela cortava a
`1.0.0` no primeiro `###` e perdia 78 das 83 linhas). Re-execucao: zero criadas,
tres puladas. E `git diff 1.0.1..1.1.0` finalmente responde — 16 arquivos.

### O que falta

O rollout nos outros 53 repositorios, com o backfill completo (~2.000-3.000
Releases) sob dry-run lido repo a repo, e o passo equivalente no
**skill-COMMITTER**. Esta na fila em [.continue/README.md](.continue/README.md).

## 1.1.0 - nada bilingue: o LICENSE passa a ser o MIT em ingles puro

Resposta do dono a medicao da `1.0.1`: *"nao, nada bilingue, so ingles, license
e etc so ingles"*. A pergunta que estava na fila saiu respondida.

**O que mudou.** O `LICENSE` deixa de ser PT-depois-EN e passa a ser o texto MIT
em ingles, **byte-identico ao canonico** — o mesmo do `skill-LOOP`, que era o
controle da medicao e que o GitHub detecta como `MIT License`. O
`templates/skeleton/LICENSE` acompanha, com `<YEAR>`/`<OWNER>`.

**O que isso custa, dito de frente.** O `LICENSE` deste repo **nao e mais
byte-identico aos catorze da frota** — ele e byte-identico ao MIT canonico. A
divergencia esta na direcao certa e fecha substituindo os outros, nao revertendo
aqui. Entrou na fila junto com o retrofit da norma.

**A regra de idioma encolheu de tres excecoes para duas.** Ficam em portugues
so a **mensagem de commit** e as **strings voltadas ao usuario final**. O
`LICENSE` saiu da lista, e o par `README.md`/`README_br.md` fica explicitamente
recusado pelo mesmo motivo que uma norma copiada: dois documentos dizendo a
mesma coisa divergem, e um deles fica errado em silencio — o par do
BLUE3-INTRANET esta em 374 linhas contra 259.

**Onde ficou registrado.** [ADR-010](docs/decisions.md) e a decisao nova;
supera a clausula bilingue do ADR-006 (que mantem o resto: nome sem extensao,
MIT, titular, e a regra de o NOTICE nunca contradizer o LICENSE) e revisa a
lista de excecoes do ADR-005. A norma em `docs/conventions.md` §8, os gemeos
`CLAUDE.md`/`AGENTS.md`, os dois `README.md`, os dois `versioning.md` e o
`docs/README.md` foram corrigidos na mesma passada — documento que envelhece em
silencio e pior que documento ausente.

**A fila perdeu uma linha.** O item *"vale o LICENSE bilingue?"* foi **apagado**
de `.continue/README.md`, nao marcado como feito: item concluido sai da fila, e
o registro permanente e este arquivo. Bump **Y** porque houve ADR novo.

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
