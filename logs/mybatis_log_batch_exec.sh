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

function is_number(v) {
  return v ~ /^-?[0-9]+(\.[0-9]+)?([eE]-?[0-9]+)?$/
}

function normalize(v) {
  return (v ~ /[eE]/) ? (v + 0) : v
}

BEGIN { idx = 1 }

# Capture SQL
/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/, "", sql)
  gsub(/[{}]/, "", sql)                       # remove {}
  gsub(/\([[:space:]]*\?[[:space:]]*(,[[:space:]]*\?)*[[:space:]]*\)/, "", sql) # remove placeholders
  sql = trim(sql)
  next
}

# Capture parameters and write file
/Parameters:/ && sql != "" {
  file = sprintf("%s/exec_%03d.sql", outdir, idx++)
  line = $0
  sub(/.*Parameters:[[:space:]]*/, "", line)
  n = split(line, a, ", ")

  vals = ""
  for (i = 1; i <= n; i++) {
    raw = trim(a[i])

    # null
    if (tolower(raw) == "null") {
      val_out = "NULL"
    } else {
      # remove type annotation like (String), (Long), (BigDecimal)
      sub(/\([^)]+\)$/, "", raw)
      val = trim(raw)

      if (is_number(val)) {
        val_out = normalize(val)
      } else {
        gsub(/'\''/, "''''", val)   # escape single quotes
        val_out = "'" val "'"
      }
    }

    vals = vals (i==1?"":", ") val_out
  }

  print sql " " vals ";" > file
  close(file)
  sql = ""
}
' "$LOG_FILE"
