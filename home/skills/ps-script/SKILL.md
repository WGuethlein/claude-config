---
name: ps-script
description: Produce a production-ready PowerShell script in DLZ's standard layout and hand it back with verification results, manual steps, risks, and a safe test plan. Use this whenever Wyatt asks for a PowerShell script, module, scheduled task, or automation against AD, Exchange, Entra, Intune, SCCM, Graph, or endpoints, even if he just says "write me something that..." or "automate this". Follow the PowerShell rule file for conventions; this skill is the delivery procedure.
---
# PowerShell script delivery

The conventions (layout, target-version constraints, verification tools) are in `~/.claude/rules/powershell.md` and load automatically when a `.ps1` file is open. This skill is the procedure around them.

## Before writing
1. Confirm the target: Windows PowerShell 5.1, PowerShell 7.6, or Both. If unknown, ask; it changes the syntax available.
2. Confirm the four context items: required function, AD required (Y/N), OS or platform, other requirements (modules, permissions, schedule). If any are missing and not inferable, ask once, all together.
3. For anything that changes production objects, agree on the dry-run default and the pilot scope (one OU, one mailbox, one device group) before writing.
4. Run the `powershell-cmdlet-verifier` skill on every cmdlet and parameter you intend to use, for the target version. Note anything you could not verify.

## Writing
- Create the `.ps1` in the current project folder following the rule file's layout. If there is no project, ask where it should live.
- Default to `-WhatIf`-capable, report-first behavior. Changes require an explicit switch.
- Transcript logging for any script that modifies AD, Exchange, Entra, or endpoints.

## Verify
- Run `Invoke-ScriptAnalyzer -Severity Warning` on the file. Fix findings. If the analyzer isn't installed, say so.
- If the script is more than a one-off, create `<name>.Tests.ps1` with Pester 5 tests for parameter validation and the dry-run path, and run them.
- Paste the analyzer and test output.

## Hand back, in this order
1. The script path.
2. What it does, in three to five sentences.
3. Manual steps: module installs, consent grants, permissions, scheduling.
4. Risks and blast radius, with the specific objects or systems affected.
5. Test plan: how to run it safely first (`-WhatIf`, pilot scope), what a successful run looks like, and how to roll back.
