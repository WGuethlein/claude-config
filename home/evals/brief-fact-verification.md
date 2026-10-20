# Eval: brief fact verification

Trigger: a task brief, plan step, or context file states a fact about
existing code - a constructor or method signature, argument order, a default
value, a member name, an existing test/helper name, or an expected count -
without reading the file first. Seen 6 times on one plan
(benefit-invoice-reconciliation): an identity-scrub test asserted against a
name ("TORDI") the scrub had already removed because the scrub map only had
"Tordi"; a brief called `FetchAsync(_reportXRefCode, cancellationToken)` when
`pageSize` sits second in the real signature; a brief referenced
`options.ClientNamespace`, which lives on `DayforceOptions`, not `ReconOptions`;
a brief assumed a `SunLife()` test helper existed when it did not.

Procedure:
1. Take the most recent brief, plan step, or context file produced for
   implementer dispatch.
2. Extract every sentence that asserts a fact about existing code:
   signatures, member/type names, argument order or defaults, existing test
   or helper names, line numbers, or "this already does X" claims.
3. For each, Read or Grep the real file and compare verbatim against the
   assertion.
4. Flag any assertion that does not match, and separately flag any assertion
   for which the brief cites no read at all (no file:line, no quoted
   signature) - an assertion can be right by luck and still be the failure
   mode this eval exists to catch.

Pass condition: every code-fact assertion in the brief is verified against
the actual file and matches exactly, or has been corrected before dispatch.
Zero unverified assertions remain.

Fail action: return the specific false or unverified assertion(s) to whoever
wrote the brief (the main session) with the correct
signature/name and its file:line, and correct the brief before the
implementer is dispatched. Do not let the implementer discover the defect
and route back a NEEDS_CONTEXT report - that is a working safety net, not a
substitute for this check.
