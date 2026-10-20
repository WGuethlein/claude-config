---
paths:
  - "**/*.cs"
  - "**/*.razor"
  - "**/*.csproj"
  - "**/*.sln"
  - "**/*.slnx"
---
# C# / .NET / Blazor conventions

## Language
- Target .NET 10 LTS and C# 14. `<Nullable>enable</Nullable>` and `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` in every project. No `null!` suppression without a comment explaining why.
- XML doc comments (`///`) with summary, param, returns, and exception on all public members. Each file starts with a 2-4 sentence file-level comment.
- Use C# 14 where it reduces boilerplate: extension members, the `field` keyword, null-conditional assignment. Don't use preview features.
- Records for DTOs and value objects. String interpolation over concatenation. Source-generated regex for hot paths.

## Naming and layout
- Projects: `SolutionName.Layer`. Types, methods, properties, constants: PascalCase. Locals and params: camelCase. Private fields: `_camelCase`. Interfaces: `I` prefix. Async methods: `Async` suffix. One file per type, `ClassName.cs`, namespaces match folders.
- Three layers with one-way dependencies: `Core` (entities, domain exceptions, no dependencies) <- `Infrastructure` (`Data/` with DbContext, `Data/Configurations/` as `IEntityTypeConfiguration<T>`, `Data/DTOs/` by domain, repositories; `Services/`; `Utils/`) <- `Web` (`Components/ComponentModels`, `Layout`, `Pages`, `Pages/ErrorHandling`; `Themes/`; `Program.cs`).

## Behavior
- Async for all I/O; `Task`/`Task<T>`, `ValueTask<T>` only where measured. No `async void` outside event handlers. `ConfigureAwait(false)` in library code.
- Constructor injection only. Transient for stateless, Scoped for per-request and DbContext, Singleton for config and caches.
- Options pattern (`IOptions<T>` / `IOptionsSnapshot<T>`) with `IValidateOptions<T>` at startup. Secrets in User Secrets (dev) or Key Vault (prod); config classes live in Infrastructure.
- EF Core: async only, Scoped, projection or explicit loading to avoid N+1.
- Specific exception types in catch blocks; `ILogger<T>` with structured context; global exception middleware in Web.
- Blazor: `@code` for simple logic, code-behind for complex; `ComponentModels/` for state; implement `IDisposable` when subscribing to anything; `@key` on lists; explicit `@rendermode`; `ErrorBoundary` around risky components.

## Verification
- `dotnet build -warnaserror` and `dotnet test` must pass. Paste the summary line. For Blazor UI changes, run the app and describe or screenshot the result.
- Tests in `SolutionName.Tests` using xUnit; one test project per layer that has logic.

## Delivery
- File paths with contents, affected projects, NuGet packages with versions and target project, appsettings entries, `Program.cs` registrations, manual steps, security notes, and a Core -> Infrastructure -> Web reading order.
