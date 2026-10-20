# Module-Specific Verification Notes

Modules that have caused version/edition/namespace failures in this environment. Read the
relevant entry when a script touches one. This file covers verification hazards only.

## ActiveDirectory (RSAT)

- Ships as a Windows feature (RSAT), not from the gallery. Requires
  `#Requires -Modules ActiveDirectory` and RSAT installed on the running host. The module
  is available in both 5.1 and 7.x, but under 7.x it loads via the Windows PowerShell
  compatibility shim (implicit remoting into a 5.1 session) — object types can round-trip
  as deserialized (`Deserialized.Microsoft.ActiveDirectory.*`) and lose methods. If a
  script does anything beyond reading properties, confirm it is running under 5.1.
- `Get-ADUser -Properties *` returns attribute names that differ from the LDAP names
  (`SamAccountName` vs `sAMAccountName`, `Enabled` vs `userAccountControl`). Do not assume
  a property exists by its LDAP name; confirm the PowerShell property name.
- Writing large-integer AD attributes (e.g. `msExch*` values, `accountExpires`) via
  `Set-ADUser -Replace` can fail; assigning the value as a string is the workaround (see
  the DirectoryServices note below — same root issue surfaces in .NET).
- Search scope: `-SearchScope OneLevel` vs `Subtree` matters given nested OUs (CR users
  sit a level deeper). Not a version issue, but a common correctness bug — verify scope.

## Microsoft Graph — PowerShell SDK vs .NET SDK

- The **Graph PowerShell SDK** (`Microsoft.Graph.*` modules) and the **Graph .NET SDK**
  (`Microsoft.Graph` NuGet, v5) are different products with different shapes. Do not port
  a cmdlet name to a .NET method name or vice versa by guessing.
- Graph SDK v5 (.NET) has significant namespace/type churn between minor versions.
  Request-body types move and get renamed. A known example: the sign-out operation's
  request body type (`RevokeSignInSessionsPostRequestBody`) and the method that returns
  its response have shifted; the resilient approach is to call the operation method
  (`...PostAsRevokeSignInSessionsPostResponseAsync`) rather than depending on the exact
  body type name. When emitting Graph SDK v5 calls, verify the current type/method names
  against the installed SDK version rather than memory.
- Graph **permissions** are a frequent silent blocker (an operation compiles and runs but
  403s at runtime for want of a consented scope). `MailboxSettings.ReadWrite` in
  particular is required to set auto-reply and is easy to miss. Flag required scopes
  alongside the code.

## Exchange Online (EXO)

- Several EXO operations have **no supported .NET SDK equivalent** and must stay in
  PowerShell: `Set-Mailbox -Type Shared`, `Add-MailboxPermission`,
  `Set-MailboxAutoReplyConfiguration`, `Remove-UnifiedGroupLinks`, `Enable-RemoteMailbox`.
  Do not invent a Graph/.NET call for these — confirm whether a supported path exists
  before claiming one does.
- `Remove-UnifiedGroupLinks` is an **Exchange Online** cmdlet, not a Teams one — do not
  reach for a `Connect-MicrosoftTeams` session to run it.
- The modern module is `ExchangeOnlineManagement` (`Connect-ExchangeOnline`). Older
  material references the deprecated remote-PowerShell connection; verify which is in use.

## Az / Azure

- `Az.*` modules are gallery-installed and versioned independently; parameter sets change
  across major versions. Do not assume a parameter exists — verify against the installed
  `Az` version.
- `Invoke-ProcessASDatabase` (Analysis Services refresh) comes from `SqlServer` /
  `Az.AnalysisServices` depending on context — confirm which module provides it before
  writing a script around it.

## DirectoryServices (.NET, not a module — related failure class)

Included here because it produces the same "looks right, fails at runtime" class:
- Writing `LargeInteger`/`IADsLargeInteger` AD attributes through
  `System.DirectoryServices` can throw `COMException 0x80004005`. Assigning the value as a
  **string** rather than a native 64-bit integer is the known fix.
- Binding: this environment uses `ServerBind | Negotiate` against
  `coload101.dlzcorp.com`. Not a version issue, but a required correctness detail.
