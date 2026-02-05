#!/usr/bin/env bash

LOG_FILE="$1"
OUT_DIR="$2"

if [ $# -ne 2 ] || [ ! -f "$LOG_FILE" ]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUT_DIR"

awk -v outdir="$OUT_DIR" '
function trim(s) { gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s); return s }
function is_number(s) { return s ~ /^-?[0-9]+(\.[0-9]+)?([eE]-?[0-9]+)?$/ }
function normalize(s) { return (s ~ /[eE]/) ? (s+0) : s }

BEGIN { idx = 1 }

/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/, "", sql)
  gsub(/[{}]/,"",sql)  # remove {}
  gsub(/\([[:space:]]*\?[[:space:]]*(,[[:space:]]*\?)*[[:space:]]*\)/,"",sql)  # remove (?,?)
  sql = trim(sql)
  next
}

/Parameters:/ && sql != "" {
  file = sprintf("%s/exec_%03d.sql", outdir, idx++)
  line = $0
  sub(/.*Parameters:[[:space:]]*/, "", line)

  n = split(line, arr, ", ")
  vals = ""

  for (i=1; i<=n; i++) {
    raw = trim(arr[i])

    # Remove (Type)
    if (match(raw, /\([^)]+\)$/)) {
      val = substr(raw, 1, RSTART-1)
      val = trim(val)
    } else {
      val = raw
    }

    # Determine output
    if (tolower(val) == "null") {
      val_out = "NULL"
    } else if (is_number(val)) {
      val_out = normalize(val)
    } else {
      gsub(/'\''/, "''''", val)  # escape single quotes
      val_out = "'" val "'"
    }

    vals = vals (i==1?"":", ") val_out
  }

  print sql " " vals ";" > file
  close(file)
  sql = ""
}
' "$LOG_FILE"
