# Claude Code – Projektregeln

## Git-Workflow

- **Jede Änderung wird committet** – keine uncommitteten Änderungen hinterlassen
- **Commits verwenden Gitmoji** – passendes Emoji am Anfang der Commit-Message (z.B. `✨ Add feature`, `🐛 Fix bug`, `♻️ Refactor`, `📝 Update docs`)
- **Kein Hinweis auf Claude-Urheberschaft** – kein `Co-Authored-By: Claude` oder ähnliches in Commits
- **Gitflow-Workflow**:
  - Hauptbranch: `main`
  - Entwicklungsbranch: `develop`
  - Jedes neue Feature bekommt einen eigenen Branch: `feature/<name>` (abgezweigt von `develop`)
  - Nach Fertigstellung wird der Feature-Branch in `develop` gemergt
  - Bugfixes: `fix/<name>`, Releases: `release/<version>`
