# Eval: claimed verification without measurement

## The failure

Saying "I verified X" when X was read, searched, or reasoned - not executed. The word transfers
confidence the evidence does not carry, and it stops the next person checking.

## Instance 1 (2026-09-14, eval-viewer-site, Tasks 6+7)

A review claimed File.Exists swallows access-denied so an unreadable file reads as missing. The
controller repeated it with MORE force than the review used. An implementer could not reproduce it and
said so. Measurement: File.Exists returns True for a file with an explicit deny-read ACE. The claim was
false.

## Instance 2 (2026-09-14, eval-viewer-site, final review)

A whole-branch review found the Entra HR role would be inert because RoleClaimType was never set. The
controller ran a documentation search, received snippets - several for AddMicrosoftIdentityWebApi, a web
API rather than a web app - and told the user "I verified this against Microsoft's own documentation
before acting, rather than repeating the reviewer's reasoning."

Measurement by the implementer, four combinations through the handler the host actually resolves:

    map=True  rct=ws-fed  -> 1 role claim found   <- the code as it stood. IT WORKED.
    map=True  rct=roles   -> 0 role claims        <- the dispatched fix, applied literally
    map=False rct=ws-fed  -> 0 role claims
    map=False rct=roles   -> 1 role claim         <- the documented pair

MapInboundClaims defaults to true and the inbound map renames `roles` to the WS-Fed URI, so the default
RoleClaimType finds it. The guidance is a PAIR - MapInboundClaims = false AND RoleClaimType = "roles" -
and the controller quoted one half.

The dispatched fix would have introduced the exact production failure it was written to prevent, and no
test in the project would have caught it, because every role test builds its principal directly instead
of validating a token.

## What caught it both times

An implementer instructed to report what it measures rather than what it expects, and willing to tell
the controller its dispatch was wrong.

## Rules

1. A documentation search is not a measurement. It can establish that a setting exists; only running
   the code establishes what the code does.
2. Never write "verified" for something read. Use "documented" or "reasoned". Reserve "verified" and
   "measured" for things with command output behind them.
3. When a fix changes framework behaviour, require the implementer to measure the BEFORE state, not
   only the after. A fix to something that already worked is the expensive failure, and measuring
   before is the only thing that catches it.
4. Tests that construct their own principal, request, or context prove the code agrees with the
   fixture, not with the platform. When a finding is about platform behaviour, the test must go through
   the platform.
