#!/usr/bin/env bash

# Usage:
#   ./mybatis_log_split_sql_values.sh application.log sql_out

LOG_FILE="$1"
OUT_DIR="$2"

if [ $# -ne 2 ] || [ ! -f "$LOG_FILE" ]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUT_DIR"

awk -v outdir="$OUT_DIR" '
# ---------- helpers ----------
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}

function is_number(v) {
  return v ~ /^-?[0-9]+(\.[0-9]+)?([eE]-?[0-9]+)?$/
}

function normalize(v) {
  return (v ~ /[eE]/) ? (v + 0) : v
}

# ---------- init ----------
BEGIN {
  idx = 1
}

# ---------- capture SQL ----------
/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/, "", sql)

  # remove {} blocks
  gsub(/[{}]/, "", sql)

  # remove (?, ?, ?) placeholders
  gsub(/\([[:space:]]*\?[[:space:]]*(,[[:space:]]*\?)*[[:space:]]*\)/, "", sql)

  sql = trim(sql)
  next
}

# ---------- capture parameters & write file ----------
/Parameters:/ && sql != "" {
  file = sprintf("%s/exec_%03d.sql", outdir, idx++)
  line = $0
  sub(/.*Parameters:[[:space:]]*/, "", line)

  n = split(line, a, ", ")

  # build a comma-separated list of values
  vals = ""
  for (i = 1; i <= n; i++) {
    val = trim(a[i])

    if (tolower(val) == "null") {
      val_out = "NULL"
    } else {
      # remove (Type) if exists
      sub(/\([^)]+\)$/, "", val)
      val = trim(val)

      if (is_number(val)) {
        val_out = normalize(val)
      } else {
        # escape single quotes inside string
        gsub(/'\''/, "''''", val)
        val_out = "'" val "'"
      }
    }

    vals = vals (i==1?"":", ") val_out
  }

  # write SQL with values directly inserted
  print sql "(" vals ");" > file

  close(file)
  sql = ""
}
' "$LOG_FILE"
