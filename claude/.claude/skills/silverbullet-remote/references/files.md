# Remote file operations

Always include the selected `--space` or explicit `--url`. `sb fs <command> --help` documents the installed version. These examples use an invented saved connection named `notes`.

| Operation | Example |
| --- | --- |
| List direct children | `sb --space notes fs ls Projects --json` |
| List matching descendants | `sb --space notes fs ls Projects --recursive --glob '*.md' --limit 100 --json` |
| Read content and revision | `sb --space notes fs read 'Projects/Orchard.md' --json` |
| Read a numbered excerpt | `sb --space notes fs read 'Projects/Orchard.md' --lines 10:30 --number` |
| Inspect metadata/revision | `sb --space notes fs stat 'Projects/Orchard.md' --json` |
| Create a new file | `sb --space notes fs write 'Projects/Seed Plan.md' --create --file draft.md` |

Raw `fs read` preserves bytes without an added newline. JSON reads include UTF-8 content and the full-file revision. Binary content needs raw redirected output. A line range still downloads the whole file. Default transfer cap is 16 MiB; increase `--max-bytes` deliberately if needed. Batch text edits are limited to 8 MiB and require UTF-8 without NUL.

## Conditional changes

Copy the `revision` value from read/stat output exactly, including its embedded quotes, into a shell-safe argument. The following uses a shell variable already populated with that exact value:

```sh
sb --space notes fs write 'Projects/Orchard.md' --if-match "$revision" --file edited.md
sb --space notes fs edit 'Projects/Orchard.md' --if-match "$revision" --file edits.json --dry-run
```

Review the dry-run diff, then execute the edit without `--dry-run` using the same revision. `--overwrite` is an explicit unconditional write policy, not a conflict-recovery mechanism.

Example `edits.json`:

```json
{"edits":[{"old":"Status: draft","new":"Status: ready"},{"old":"* [ ] Check drainage","new":"* [x] Check drainage"}]}
```

Each old string must occur exactly once in the original file and ranges must not overlap. Validation completes before one conditional write. `fs edit` protects its initial read even without `--if-match`; supplying the revision additionally protects the user's earlier inspection. `fs rm --if-match "$revision"` conditionally deletes a single file. Delete only within the requested scope.

## Results

Use one output selector: `--json`, `--text`, or `-o jsonl`. Logs and space management still print text. JSONL listings include a final summary record.

File exit codes: 2 invalid input, 3 missing target, 4 access denied, 5 revision/create conflict, 6 edit mismatch or overlap, 7 truncated listing, 8 operational failure. Errors are on stderr. An empty successful listing differs from a failed or truncated listing. On conflict, read fresh content and reassess; on uncertainty after a write, inspect before retrying. There are no `fs search`, copy, move, or recursive-delete commands in this interface.
