# Lessons (git-tracked agent memory)

Append one imperative rule per line as you learn them. Promote universal ones
into CLAUDE.md.

- Fix packwerk violations at the boundary (event or app/public API); never add a
  sibling dependency to package.yml to silence the checker.
- Tailwind v4 purges any class it cannot see verbatim: keep variant->class maps
  as complete literal strings in components, and keep the `.rb` `@source` glob
  for app/public in application.css — it is load-bearing.
- The tailwindcss:install generator cannot insert tags into a minimal layout
  head; verify stylesheet_link_tag "tailwind" exists after running it.
- Run the puma dev server with WEB_CONCURRENCY=0 on macOS; forked workers crash
  on objc fork-safety (NSCharacterSet + fork).
