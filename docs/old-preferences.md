<!-- Wyatt's previous claude.ai preferences, unchanged, kept for the audit session to compare against. -->

# Claude Coding Preferences

## General Principles (All Languages)

### Code Architecture
- **KISS**: Simplest solution that solves the problem
- **DRY**: Factor out repeated logic
- **YAGNI**: Don't add unnecessary functionality
- **SoC**: Separate concerns appropriately
- **SRP**: Single responsibility per component

### String Processing
- Prefer simple string methods over regex for straightforward tasks
- Use regex for complex patterns with explanatory comments

### Documentation
- No emojis or emoticons in markdown documentation
- 2-4 sentence file description at top

### Development Process
- **ALWAYS ask clarifying questions before writing code**
- Confirm: requirements, inputs/outputs, error handling, architecture decisions

---

## Python

### Language & Typing
- Target Python 3.12, no deprecated APIs
- Type-hint all functions/methods
- Prefer built-in generics (`list[str]`, `dict[str, int]`)
- Use `typing` for `Callable`, `Protocol`, `TypeVar`, `Literal`

### Documentation & Style
- Google-style docstrings for all classes, methods, functions
- Avoid nested functions
- Use `argparse` for CLI programs

### OOP & Organization
- Prefer composition over inheritance
- Use `Protocol` (duck typing) or `abc.ABC` (nominal typing) as appropriate
- Each significant class in own file: `ClassName` -> `class_name.py`
- Small helper classes/exceptions may share file with primary class
- Separate main function into own file
- Import statements at top
- Provide "foundation-first, complexity-last" study order

---

## PowerShell

### Pre-Development
- **ALWAYS verify cmdlet syntax/parameters/modules before coding**
- Never guess command names or parameters
- Confirm requirements, security risks, operational impacts

### Script Structure (in order)
1. **Header**: name, version, author, date, description, prerequisites, usage example
2. **Variables**: All configurable vars at top with comments, sensible defaults
3. **Parameters**: CLI params override defaults, validation attributes, help text
4. **Code**: Comment all sections (what/why), document complex logic

### Context Variables (You'll Provide)
- Required function, AD Required (Y/N), OS version, other requirements

### Best Practices
- Try/catch error handling with logging
- `Write-Verbose` for operational details
- `-WhatIf` for destructive operations
- Test required modules/permissions at start
- Approved verbs, proper naming (PascalCase functions, $camelCase vars)
- Transcript logging for audits
- Validate input before processing
- Splat complex cmdlets

### Output Format
Script + explanation, manual steps, risks, testing recommendations

---

## C#/.NET/Blazor

### Language & Framework
- Target latest stable .NET (8/9), C# 12 features
- Enable nullable reference types: `<Nullable>enable</Nullable>`
- Explicit nullability on all parameters/returns/properties
- No deprecated APIs or `null!` suppression without justification

### Documentation & Conventions
- XML comments (`///`) with `<summary>`, `<param>`, `<returns>`, `<exception>`
- **Projects**: `SolutionName.Layer` (e.g., `BlazorApp.Core`)
- **Types/Methods/Properties**: PascalCase
- **Local vars/params**: camelCase
- **Private fields**: `_camelCase`
- **Constants**: PascalCase
- **Interfaces**: `I` prefix
- **Async methods**: `Async` suffix
- **Files**: `ClassName.cs` (exact match)
- **Folders**: PascalCase

### Async/Await
- Use for all I/O operations, return `Task`/`Task<T>`
- `ValueTask<T>` for high-performance scenarios
- No `async void` except event handlers
- `ConfigureAwait(false)` in libraries

### DI & Service Lifetimes
- **Transient**: Stateless services
- **Scoped**: Per-request (EF contexts)
- **Singleton**: App lifetime (config, caching)
- Constructor injection only, avoid service locator

### Project Structure

#### Three-Layer Solution
**Core** (domain, entities) -> **Infrastructure** (data, services) -> **Web** (UI, components)

**Core** (`App.Core/`)
- `Entities/` - Domain models

**Infrastructure** (`App.Infrastructure/`)
- `Data/` - DbContext, configurations, DTOs (organized by domain), repositories
- `Services/` - Service implementations
- `Utils/` - Constants, helpers

**Web** (`App.Web/`)
- `Properties/launchSettings.json`
- `wwwroot/` - Static assets
- `Components/`
  - `ComponentModels/` - View models
  - `Layout/` - Layouts
  - `Pages/` - Routable pages with `@page`
    - `ErrorHandling/` - Error pages
  - `_Imports.razor` - Global imports
- `Themes/` - Theme code
- `App.razor`, `Routes.razor`
- `appsettings.json`, `appsettings.Development.json`
- `Program.cs`

#### Organization Rules
- Each significant type in own file; small helpers may share
- Namespaces match folder structure
- Using statements at top (IDE-sorted)
- **Dependencies**: Core (none) <- Infrastructure <- Web
- Study order: Core -> Infrastructure -> Web

### Blazor Components
- `@code` blocks for simple logic; code-behind for complex
- `ComponentModels/` for component state/logic
- Implement `IDisposable`, dispose subscriptions/timers/clients
- `StateHasChanged()` judiciously
- `[Parameter]` with proper nullability
- `[CascadingParameter]` for hierarchical values
- `@key` for list rendering
- `@rendermode` for SSR/WASM/Auto (.NET 8+)
- `ErrorBoundary` for rendering errors

### EF Core (if applicable)
- DbContext in Infrastructure `Data/`
- Async operations only
- Configurations in `Data/Configurations/` via `IEntityTypeConfiguration<T>`
- DTOs in `Data/DTOs/` (domain-organized)
- Eager/explicit loading or projection (avoid N+1)
- Scoped lifetime

### Error Handling
- Specific exception types in try/catch
- `ILogger<T>` with context
- Custom exceptions in Core
- Validate input, meaningful messages
- Global middleware for unhandled exceptions

### Configuration
- `appsettings.json` + environment overrides
- Options pattern: `IOptions<T>`, `IOptionsSnapshot<T>`
- User Secrets (dev) / Key Vault (prod) for sensitive data
- `IValidateOptions<T>` for startup validation
- Config classes in Infrastructure

### String Processing
- String interpolation (`$"..."`) over concatenation
- Compiled regex or source-generated (C# 11+) for frequent patterns

### OOP
- Composition over inheritance
- Interfaces for contracts
- Dependency injection
- Records for DTOs/value objects
- Factory/builder for complex creation

### Context Variables (You'll Provide)
- Required functionality, .NET version, Blazor type, database, authentication, project layer, other requirements

### Output Format
Code with file paths + explanation, affected projects, NuGet packages (with versions/projects), appsettings entries, Program.cs registration, manual steps, security notes, testing recommendations, deployment notes
