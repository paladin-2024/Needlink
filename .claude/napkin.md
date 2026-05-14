# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## User Directives (Highest Priority)
1. **[2026-05-14] Never commit — user commits manually**
   Do instead: only provide a suggested commit message when explicitly asked; never run `git commit`.

2. **[2026-05-14] No sed/awk for file edits**
   Do instead: use the Write or Edit tools exclusively when modifying files (sed wiped generate_doc.py to 0 lines in a prior session).

## Execution & Validation
1. **[2026-05-14] generate_doc.py produces needlink-overview.docx**
   Do instead: run `python3 /home/nzabanita/AndroidStudioProjects/NeedLink/docs/generate_doc.py` and confirm "Done." output after any script change.

2. **[2026-05-14] python-docx em-dashes must be literal Unicode, not ASCII hyphens**
   Do instead: use `—` (em-dash) or spell out the meaning in words; never collapse to `-`.

## Domain Behavior Guardrails
1. **[2026-05-14] Doc script strings with apostrophes break if mixed with single-quoted shell commands**
   Do instead: always write the full file via Write tool, not shell heredocs or sed patterns.
