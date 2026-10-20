---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---
# Python conventions

## Language
- Target Python 3.14. No deprecated APIs. Type-hint every function and method; use built-in generics (`list[str]`, `dict[str, int]`) and `typing` only for `Callable`, `Protocol`, `TypeVar`, `Literal`, `Self`.
- Google-style docstrings on every module, class, and function. Each file starts with a 2-4 sentence module docstring.
- Imports at the top. No nested functions; extract a helper or a method instead.
- Prefer plain string methods over regex. When regex is needed, add a comment explaining the pattern.
- `argparse` for CLI entry points. Config via environment variables or a small settings dataclass, never hardcoded.

## Structure
- One significant class per file: `ClassName` lives in `class_name.py`. Small helpers and exceptions may share the file of the class that uses them.
- `main.py` (or `__main__.py`) holds only the entry point and argument parsing.
- Composition over inheritance. `Protocol` for duck-typed contracts, `abc.ABC` only when nominal typing is required.
- `pyproject.toml` is the single config file for the project, tooling, and dependencies. Use `uv` for environments and locking unless the project already uses something else.

## Verification
- `ruff check .` and `ruff format --check .` must pass. `pytest` for tests; `pytest -x` while iterating.
- Add a test for every bug fix that reproduces the bug first. For new modules, cover the public interface and at least one failure path.
- Paste the command and result when handing back.

## Delivery
- File paths with contents, then a "foundation first, complexity last" reading order: data models and config, then services, then the entry point.
