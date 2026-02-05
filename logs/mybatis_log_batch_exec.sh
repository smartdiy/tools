#!/usr/bin/env bash

LOG_FILE="$1"
OUT_DIR="$2"

if [ $# -ne 2 ] || [ ! -f "$LOG_FILE" ]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUT_DIR"

awk -v outdir="$OUT_DIR" '
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}

function is_number(s) {
  return s ~ /^-?[0-9]+(\.[0-9]+)?([eE]-?[0-9]+)?$/
}

function normalize(s) {
  return (s ~ /[eE]/) ? (s+0) : s
}

BEGIN { idx = 1 }

# Capture SQL
/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/, "", sql)
  gsub(/[{}]/, "", sql)
  gsub(/\([[:space:]]*\?[[:space:]]*(,[[:space:]]*\?)*[[:space:]]*\)/, "", sql)
  sql = trim(sql)
  next
}

# Capture parameters and write batch file
/Parameters:/ && sql != "" {
  file = sprintf("%s/exec_%03d.sql", outdir, idx++)
  line = $0
  sub(/.*Parameters:[[:space:]]*/, "", line)
  n = split(line, arr, ", ")

  vals = ""
  for (i = 1; i <= n; i++) {
    raw = trim(arr[i])

    if (tolower(raw) == "null") {
      val_out = "NULL"
    } else {
      # strip (Type) annotation
      val_clean = raw
      sub(/\([^)]+\)$/, "", val_clean)
      val_clean = trim(val_clean)

      if (is_number(val_clean)) {
        val_out = normalize(val_clean)
      } else {
        # escape single quotes inside the string
        gsub(/'\''/, "''''", val_clean)
        val_out = "'" val_clean "'"
      }
    }

    vals = vals (i==1?"":", ") val_out
  }

  # print SQL + values directly, no parentheses
  print sql " " vals ";" > file
  close(file)
  sql = ""
}
' "$LOG_FILE"
