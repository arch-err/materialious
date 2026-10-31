# Patched image

The `patched` branch builds `ghcr.io/arch-err/materialious` on pushes and daily.
Only images passing certificate checks and a fresh high/critical vulnerability gate
are published. Pin the resulting digest when deploying. Reports are retained as
Actions artifacts. Run locally with `security/check-image.sh IMAGE node`.

Certificate fixtures are public test chains from
https://emudhra.we-have-a-problem.com/chains.zip (31 October 2026).
Node and Companion also test their actual runtime against the fourteen test
endpoints, with a valid HTTPS control. Network failures fail the check.
