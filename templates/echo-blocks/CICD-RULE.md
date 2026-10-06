<!-- CICD-RULE:repodocs -->

## CI — a private repository may use the fleet's self-hosted runner; a public one never

> Marked echo. The single source is **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/ci.md)**
> — change it there, not here. This block is regenerated.

**The fleet has one CI machine, `cicd`: a self-hosted GitHub Actions runner that
does not spend the account's hosted minutes.** It exists because that budget ran
out on 25/09/2026 and every job in a private repository failed within seconds,
with zero steps. Its address, the way in and the procedure are in the source and
**not here** — this block is copied into public repositories.

**A public repository never gets that runner.** A pull request from a fork runs
its code on the machine, and the machine sits in the office network. Public
repositories use GitHub-hosted runners, which are free for them. If you are about
to register a runner in one, stop.

**The switch is a repository variable, never an edit of the workflow.** A job
reads `runs-on: ${{ vars.CI_RUNNER || 'ubuntu-latest' }}`;
`gh variable set CI_RUNNER --body shvia-ci -R <owner>/<repo>` sends the jobs to
`cicd`, and `gh variable delete CI_RUNNER -R <owner>/<repo>` hands them back to
GitHub.

**Joining is the owner's act — and so is joining a collaborator's repository.**
One runner per repository, registered over SSH with a registration token. The
jobs run with `sudo` and `docker` on a machine inside the office network, so an
agent **never registers a runner on its own initiative**: it says what is needed
and asks. The dashboard on port 8080 only shows the jobs — it is not how a
repository joins.

<!-- /CICD-RULE -->
