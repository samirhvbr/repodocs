# CI — the self-hosted runner `cicd`

> **Status:** `ACTIVE` · The fleet's one CI machine: what it is, which repositories
> may use it, how one joins, and the rules that keep it safe. Written 06/10/2026
> from `shvia-web/deploy/servidor-cicd.md`, which stays **the source for the machine
> itself** (disks, installed software, runners, dashboard internals) and is not copied
> here. **Not re-measured on the machine on the day of writing** — the figures and the
> state below are the ones that runbook recorded on 28–30/09/2026. Rules 1 and 4 were
> rewritten on 07/10/2026 by [ADR-030](decisions.md).
>
> ⚠️ **Since [ADR-030](decisions.md) the address travels.** The echo block that
> reaches the fleet ([`CICD-RULE`](../templates/echo-blocks/CICD-RULE.md)) carries
> `100.64.100.240` and the SSH user, in public repositories included. It is
> `100.64.0.0/10` — RFC 6598 shared space, not routable from the internet — so
> what is published is the internal topology, not a route. Owner's decision,
> 07/10/2026.

## What it is

| | |
|---|---|
| Machine | `cicd` — a Debian 13 VM on the office Proxmox, 8 vCPU, 16 GB RAM |
| Address | `100.64.100.240` — internal; reachable from the office network only |
| Access | `ssh samir@100.64.100.240` — the owner's user, with `sudo`. The key is never written down |
| What it runs | The **GitHub Actions** jobs of private repositories, on self-hosted runners. It is not a separate CI product: the workflows, the checks and the pull request statuses are GitHub's |
| Dashboard | `http://100.64.100.240:8080/` — **read-only, no login**, office network only. It shows what is running and the numbers; it runs nothing |
| The machine's runbook | [`samirhvbr/shvia-web` → `deploy/servidor-cicd.md`](https://github.com/samirhvbr/shvia-web/blob/master/deploy/servidor-cicd.md) — **the source**; do not copy it here |

**The dashboard is not the way in.** Handing someone `…:8080` gives them a page to read.
Using the CI means a runner registered for their repository, and that is the owner's act
([below](#how-a-repository-joins)).

## Why it exists

On 25/09/2026 the account's Actions budget ran out and every job in a private repository
failed within seconds with zero steps (*"The job was not started because an Actions budget
is preventing further use"*). A self-hosted runner does not consume the hosted minutes.
A per-minute platform fee for self-hosted runners was announced and then **postponed, not
cancelled**; if it comes back, these minutes count against the same budget.

## The rules

1. **Every repository of the fleet may use it, public ones included**
   ([ADR-030](decisions.md), 07/10/2026). Until that date a public repository was
   forbidden, and the reason has not gone away: a pull request from any fork runs its
   author's code on the machine, and rule 6 below says what that means. What stands where
   the prohibition stood is **fork pull request approval** — *Settings → Actions → Fork
   pull request workflows → Require approval for all external contributors* — per
   repository. A public repository that has not set `CI_RUNNER` keeps running on
   GitHub-hosted runners, which are free for it; opening the door moved no job.
2. **It is an opt-in, and the switch is a repository variable, not an edit of the
   workflow.** Every job reads `runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}`.
   `gh variable set CI_RUNNER --body shvia-ci -R <owner>/<repo>` sends the jobs to `cicd`;
   `gh variable delete CI_RUNNER -R <owner>/<repo>` hands them back to GitHub. The runners
   carry the label `shvia-ci`, which is ours so that it never collides with a GitHub-hosted one.
3. **One runner per repository.** A personal account cannot share a runner between its
   repositories. (An organization can register one for the whole organization — a choice that
   is made, and recorded as an ADR, on the day, as in `b3monitor` ADR-002.)
4. **Joining is pre-authorised; registering is still the owner's act.** No repository needs
   a decision taken case by case any more (ADR-030). But registration needs a one-hour token
   and a shell on this machine, the jobs run with `sudo` (rule 6), and **an agent never
   registers a runner on its own initiative** — it says what is needed and asks.
5. **Nothing deploys from it.** There is no CD step; deploying stays the owner's command.
6. **The jobs run with `sudo` and `docker`.** The `runner` user has passwordless `sudo` and is
   in the `docker` group, because `setup-php` and some CI files install packages. The machine
   runbook calls this acceptable **only because the VM does nothing else**. It follows that a
   workflow registered here has, in effect, root on a machine inside the office network.

## How a repository joins

The owner, in order:

1. **Check the visibility**: `gh repo view <owner>/<repo> --json visibility`. Public is
   allowed since ADR-030 — and a public repository is the case where step 6 below stops
   being optional.
2. **Get a registration token**, which lasts one hour:
   `gh api -X POST repos/<owner>/<repo>/actions/runners/registration-token -q .token`.
   It needs admin on the repository.
3. **Register the runner on `cicd`** with the *Adding a repository* block of the machine's
   runbook. Three details of it are easy to miss, and each cost a failed run once: the token
   goes through **stdin, never a file**; the runner's `.env` pins `LANG=C.UTF-8` and
   `LC_ALL=C.UTF-8` and drops the `LANG=pt_BR.UTF-8` that `config.sh` copies from the VM; and a
   workflow step that installs a system package waits for the dpkg lock
   (`-o DPkg::Lock::Timeout=600`), because several runners share one dpkg.
4. **Make the workflow read the variable** (rule 2), then set `CI_RUNNER`.
5. **The dashboard follows by itself** — it reads every runner's `.runner` file — but it can
   read that repository's runs only if the repository is in the dashboard's token, which is
   the owner's, and a fine-grained token **only reaches repositories of its own account**.

6. **On a public repository, require approval for external contributors** —
   *Settings → Actions → Fork pull request workflows*. Rule 1 used to keep a stranger's
   code off this machine by forbidding the repository; with the prohibition gone, this
   setting is the thing that does it. A public repository on `cicd` without it runs any
   fork's pull request with `sudo` inside the office network, by design (rule 6).

Check it: `gh api repos/<owner>/<repo>/actions/runners -q '.runners[] | "\(.name) \(.status)"'`.

## A repository of someone else's account

This is the case of a collaborator who wants the same CI — the B3DEV repositories belong to
`tiago-razera`, for one.

- **They need nothing on the network for the jobs to run.** The runner connects outward to
  GitHub; nobody connects to it. They only need the office network to **open the dashboard**.
- **They provide**: the repository name, and the registration token (step 2 — only an admin of
  that repository can create it). **The owner does** step 3 over SSH. The collaborator never
  gets a shell on `cicd`.
- **The repository stays out of the dashboard's numbers** (step 5): the owner's token cannot
  see another account's repositories, and the page shows an `HTTP 404` for it in its warnings,
  not an empty chart. The jobs run regardless.
- **Rule 6 is the real decision.** Their workflows, and every pull request opened against
  their repository, run with `sudo` on a machine in the office network. ADR-030
  pre-authorised *the fleet's own* repositories; somebody else's account is not the fleet,
  so this one stays the owner's call, made each time, and an agent never takes it on the
  owner's behalf.
- **The collaborator cannot read the links in this page** — repodocs and `shvia-web` are
  private. What they are sent has to stand on its own.

## What it does not do

- **No isolation inside the VM, and none from the office network.** Keeping the machine away
  from production and the LAN is the network's job (Proxmox, the firewall). Jobs need outbound
  access to GitHub, Docker Hub, npm, Packagist, crates.io and the Debian/Sury mirrors, nothing
  else.
- **No login on the dashboard.** Opening it to anything wider than the office network needs
  authentication first.
- **No Windows build.** `windows-latest` jobs stay on GitHub-hosted runners.

## When a job fails before it starts

Look at the disk before the code. Anonymous service-container volumes pile up in
`/var/lib/docker`, and a full volume fails every job at *Initialize containers* with MariaDB
saying `error 28` — it looks exactly like a broken pull request. An hourly prune
(`cicd-volume-prune.timer`) exists since 30/09/2026; the machine's runbook has the measurement.
