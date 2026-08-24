# Configuration — Azure DevOps backlog source

## 1. Separation by class of data

| Data | Location | Reason |
|---|---|---|
| Backlog catalogue | `.specify/grm-backlog.yml` (runtime) | Project configuration: versionable and reviewable |
| Credential (PAT) | Environment variable `AZDO_PAT` | Never in a repository file |
| Procedure and contract | This skill (Source of Truth) | Reusable capability, identical in every project |

The PAT must never appear in a repository file, in a log, in an error message or
in an installation report.

## 2. Catalogue file

Template: `extensions/grm-corporate-workflow/config/grm-backlog.example.yml`,
deployed to `.specify/grm-backlog.example.yml`. The consuming project copies it
to `.specify/grm-backlog.yml` and fills it in.

```yaml
provider: azure-devops
backlogs:
  <KEY>:
    organization_url: https://dev.azure.com/<organization>
    project: <project>
```

`provider` selects which skill resolves the backlog role. Without it, the
abstraction of the `--backlog` flag would be decorative.

There is no `default` key. A reference that does not name its backlog can
resolve silently against the wrong one.

## 3. Reference resolution

```
1. Starts with http(s)://  → normalize (§4) → parse organization / project / id
2. Contains ':'            → <key>:<id> → resolve against the catalogue
                             key not found → error, list available keys
3. Anything else           → syntax error
```

F-01 is applied after retrieval on both paths. There is no silent fallback at
any point.

## 4. URL normalization

Corporate browsing goes through an MCAS proxy, so a URL copied from the browser
looks like this:

```
https://dev.azure.com.mcas.ms/gruporomeu/JWM/_workitems/edit/126924?McasTsid=26110&McasCtx=4
```

The proxy host works in a browser because the proxy injects the session. It is
not needed — and must not be used — for programmatic access with a PAT.
Normalization is mandatory before parsing:

- strip the `.mcas.ms` suffix from the host, leaving `dev.azure.com`
- drop the `McasTsid` and `McasCtx` query parameters
- keep organization, project and work item id unchanged

The canonical host is always `dev.azure.com`.

## 5. Personal Access Token

### Requirements

| Requirement | Value |
|---|---|
| Scope | **A single organization.** Never "all accessible organizations" |
| Permission | Work Items → Read |
| Maximum expiry | One year, via "Custom defined" |
| Storage | Environment variable `AZDO_PAT` only |

Tokens scoped to all accessible organizations are withdrawn by Azure DevOps from
1 December 2026. Organization-scoped tokens remain supported. This is a
requirement, not a recommendation.

### Creation

1. Azure DevOps → User settings → Personal access tokens → New Token
2. Organization: the specific organization. Not "All accessible organizations"
3. Expiration: Custom defined, up to one year
4. Scopes: Work Items → Read
5. Copy the value once; it is not shown again

### Setting the variable

Current session only:

```powershell
$env:AZDO_PAT = '<token>'
```

Persistent for the user:

```powershell
[Environment]::SetEnvironmentVariable('AZDO_PAT', '<token>', 'User')
```

A persistent variable is not visible in sessions already open. Restart the
terminal, and VS Code with it, or the agent will report a missing credential
while the variable exists.

Never write the token into a script, a task definition, a commit or a chat
transcript. If it has been exposed, revoke it and issue a new one.

### Renewal

An expired token produces HTTP 401, indistinguishable from a permissions
problem unless the error message says otherwise. Renewal is issuing a new token
and updating the variable; tokens cannot be extended after expiry.

## 6. Execution environment

The corporate baseline is **Windows PowerShell 5.1**. `pwsh` is not installed.
Every script declares `#Requires -Version 5.1` and avoids 7.x-only syntax —
including `-AsPlainText` on `ConvertFrom-SecureString` and `-SkipHttpErrorCheck`
on `Invoke-WebRequest`, neither of which exists in 5.1.

`ExecutionPolicy` is `AllSigned` at machine scope. Scripts are therefore never
invoked directly. Copy the invocation below character for character; do not
rebuild the path from the skill name:

```
powershell -NoProfile -ExecutionPolicy Bypass -File .github\skills\grm-azure-devops-pbi\scripts\Get-WorkItem.ps1 -Reference "<reference>"
```

The path is relative to the workspace root. Downloaded files require
`Unblock-File` before they will run.