# Security Policy

## Supported Versions

The project is pre-production. Only the `develop` branch receives fixes.

## Reporting a Vulnerability

Do **not** open a public issue for security problems. Contact the repository owner privately (GitHub profile contact or a private security advisory via **Security → Report a vulnerability**) with:

- A description of the issue and its impact
- Steps to reproduce
- Affected files or endpoints

## Secrets Policy

- Never commit `.env`, passwords, JWT secrets, API keys, or keystores. Only `.env.example` with placeholders is tracked.
- Secrets are injected through environment variables (see `docs/ARCHITECTURE_BLUEPRINT.md`, Twelve-Factor configuration).

## If a Secret Was Committed or Pushed

Removing the file in a later commit does **not** remove it from Git history. Act in this order:

1. **Rotate the secret immediately** (change the password, regenerate the key or token). Treat the old value as public.
2. Tell the repository owner.
3. Remove it from the code and push the fix through a normal PR.
4. History rewriting is the owner's decision only; never force-push to `develop` or `main`.
