<!-- CICD-RULE:repodocs -->

## CI — the fleet's self-hosted runner is open to every repository

> Marked echo. The single source is **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/ci.md)**
> — change it there, not here. This block is regenerated.

**The fleet has one CI machine, `cicd`: a self-hosted GitHub Actions runner that
does not spend the account's hosted minutes.** It exists because that budget ran
out on 25/09/2026 and every job in a private repository failed within seconds,
with zero steps.

| | |
|---|---|
| Address | `100.64.100.240` — the office network only. RFC 6598 shared space: not routable from the internet |
| Access | `ssh samir@100.64.100.240` |
| Dashboard | `http://100.64.100.240:8080/` — read-only, no login, office network only. It shows the jobs; it is **not** how a repository joins |

**Every repository may use it, public ones included** — the owner's decision of
07/10/2026. Until that date a public repository was forbidden, and the reason has
not gone away: **a pull request from any fork runs its author's code on this
machine**, where the jobs have passwordless `sudo` and `docker`, which is
effectively root on a machine inside the office network. What stands where the
prohibition stood is one setting, per repository: *Settings → Actions → Fork pull
request workflows → **Require approval for all external contributors***. On a
public repository on `cicd`, that setting is not optional.

**Permission is not destination.** A job reads
`runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}`, so nothing moves until
somebody sets the variable:
`gh variable set CI_RUNNER --body shvia-ci -R <owner>/<repo>` sends the jobs to
`cicd`, `gh variable delete CI_RUNNER -R <owner>/<repo>` hands them back to
GitHub. **Never set it at organisation scope** — that retargets every repository
at once, public ones that run free on hosted minutes included.

**Joining is pre-authorised; registering is still the owner's act.** One runner
per repository, registered over SSH with a one-hour token. The jobs run with
`sudo` on a machine inside the office network, so an agent **never registers a
runner on its own initiative**: it says what is needed and asks. A repository
belonging to somebody else's account is not covered by the decision above — that
one is still decided case by case.

<!-- /CICD-RULE -->
