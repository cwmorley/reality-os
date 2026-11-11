# Security Policy

Reality OS is a documentation and specification repository with one small, dry-run
Node.js example under `integrations/n8n/`. It ships no running service, holds no
credentials, and makes no network requests, so the realistic security surface is
small. It is a pattern, not a packaged product, and there are no supported release
versions: the `main` branch is the only maintained version.

The protocol itself is a set of cooperative governance conventions, not an access
control mechanism. See [Trust Boundaries](./ARCHITECTURE.md#5-trust-boundaries-bounded-context-is-not-access-control)
for what it does and does not protect against.

## Reporting a vulnerability

If you find a problem in the example code or a flaw in the protocol that could cause
data loss or unauthorized change in a deployment that follows it, please report it
privately rather than in a public issue.

Use GitHub's private vulnerability reporting (the **Report a vulnerability** button
on the repository's Security tab) if it is available. Otherwise, contact the
maintainer through the maintainer's GitHub profile, https://github.com/cwmorley, and
leave the details out of any public thread.

This is a solo-maintained project, so responses are best-effort. Reports that are accepted will be
credited unless you ask otherwise.
