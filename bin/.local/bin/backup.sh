#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURE THESE ===
SRC="/home/dkl/local-devel/ansible-silverblue/"        # trailing slash recommended: sync contents
DST="/home/dkl/devel/local-devel/ansible-silverblue/"   # trailing slash recommended: destination root
LOG="/home/dkl/.local/share/backup.log" # change to "$HOME/.local/share/backup-sync.log" for user mode
RSYNC="/usr/bin/rsync"
# =======================

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname -s)

# rsync options:
# -a : archive (recursive, preserves perms/links)
# -H : preserve hard links
# -A : preserve ACLs (if supported)
# -X : preserve xattrs
# -z : compress during transfer
# --delete : remove files in DST not present in SRC (mirror)
# --partial --partial-dir : speed up interrupted transfers
# --delay-updates : safer for live directories
# --itemize-changes : logging detail
RSYNC_OPTS=(
  -aHAX
  -z
  --delete
  --partial
  --partial-dir=.rsync-partial
  --delay-updates
  --bwlimit=0
  --info=progress2,flist2,name0
  --itemize-changes
)

echo "[$TIMESTAMP] backup start on ${HOSTNAME} src=${SRC} dst=${DST}" >> "$LOG"

# Ensure destination directory exists
if ! install -d -m 0755 "$DST"; then
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] failed to create destination: $DST" >> "$LOG"
  exit 1
fi

"$RSYNC" "${RSYNC_OPTS[@]}" "$SRC" "$DST" \
  2>>"$LOG" \
  | sed "s/^/[$TIMESTAMP] /" >> "$LOG" 2>&1

RC=$?
TIMESTAMP_END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [ $RC -eq 0 ]; then
  echo "[$TIMESTAMP_END] backup completed OK" >> "$LOG"
else
  echo "[$TIMESTAMP_END] backup FAILED rc=$RC" >> "$LOG"
fi

exit $RC
