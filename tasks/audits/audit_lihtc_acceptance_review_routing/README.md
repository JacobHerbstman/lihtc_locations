# LIHTC Acceptance Review Routing Audit

This read-only audit assigns every final physical development to exactly one
next-review route. It does not approve a development, site, query, or source.
The verified route counts are 211 site-exception, 797 no-site, 5,928 shared
network, 913 explicit-identity, 28,701 one-primary-site singleton, 9,214
one-nonprimary-site singleton, and 7,705 multisite singleton developments.
Site-exception routes take priority over shared-site networks: 43 shared-network
developments are therefore routed to the site-exception queue. Mechanic Mill,
Springfield Village, Savannah Gateway, and Trinity Oaks are explicitly
resolved/addition cases, not unresolved exceptions. Wayne-style singletons are
separated by whether their sole retained site is a project-primary site, rather
than being treated as a general identity decision.

These are review routes, not accepted evidence classes. In particular, the
three default-singleton routes still require a deterministic negative-candidate
scan and an independently read validation sample before any rule-based
acceptance can be proposed.

Run `make` from `code/`.
