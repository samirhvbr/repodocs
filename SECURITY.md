# Security Policy

> This file exists for **the path GitHub recognises** — a `SECURITY.md` at the
> root is what enables the *"Report a vulnerability"* button. It **does not
> duplicate** the norm; it points at the single source.
>
> **The source is [docs/security.md](docs/security.md), binding from the first
> commit.** This file is a marked echo ([ADR-008](docs/decisions.md)).

## Reporting a vulnerability

A vulnerability, an exposed secret or a suspected leak: report it to
**samirhv@me.com**, **immediately**. Please do not open a public issue for a
security problem.

You will get an acknowledgement, and a structural fix becomes an ADR in
[docs/decisions.md](docs/decisions.md).

See [docs/security.md §11](docs/security.md#11-incident-response) for the
normative incident-response text, and
[§5](docs/security.md#5-secrets-and-configuration) for why an exposed secret is
**rotated, not reverted** — removing the line from HEAD leaves it in the history
and in every clone.

## Supported versions

This repository holds documentation, two git hooks and a template skeleton.
There is no released artefact and no runtime, so there is no version-support
matrix: **the current `master` is the supported state.** Everything else is
history, kept for the record.

## Context

This is a **private** repository today. What it contains is the documentation
standard for the samirhvbr/Blue3 fleet — no credentials, no application, no
customer data.

If it is opened publicly, this file becomes the first point of contact for
anyone reporting a problem from outside the house. The checklist to run before
that happens is
[docs/runbook.md §6](docs/runbook.md#6-pre-flight-before-making-a-repository-public)
— and the first item on it is scanning the **history**, not the working tree.
