#!/usr/bin/env bash

# Usage:
#   ./mybatis_log_split_sql.sh application.log sql_out

LOG_FILE="$1"
OUT_DIR="$2"

if [ $# -ne 2 ] || [ ! -f "$LOG_FILE" ]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUT_DIR"

awk -v outdir="$OUT_DIR" '
# -------- helpers --------
function trim(s) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  return s
}

function is_string(t) {
  return t ~ /String|Char|Text|UUID|Date|Time|Timestamp/i
}

function is_decimal(t) {
  return t ~ /BigDecimal|Decimal|Numeric|Double|Float/i
}

function normalize(v) {
  return (v ~ /[eE]/) ? (v + 0) : v
}

# -------- init --------
BEGIN {
  idx = 1
}

# -------- capture SQL --------
/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/, "", sql)
  next
}

# -------- capture params & write file --------
/Parameters:/ && sql != "" {
  file = sprintf("%s/exec_%03d.sql", outdir, idx++)
  line = $0
  sub(/.*Parameters:[[:space:]]*/, "", line)

  n = split(line, a, ", ")

  print sql > file

  for (i = 1; i <= n; i++) {
    entry = trim(a[i])

    if (tolower(entry) == "null") {
      printf "%s@p%d = NULL\n", (i==1?" ":" ,"), i >> file
      continue
    }

    type = entry
    sub(/^.*\(/, "", type)
    sub(/\)$/, "", type)

    val = entry
    sub(/\([^)]+\)$/, "", val)
    val = trim(val)

    if (is_string(type)) {
      gsub(/'\''/, "''''", val)
      val = "'" val "'"
    } else if (is_decimal(type)) {
      val = normalize(val)
    }

    printf "%s@p%d = %s\n", (i==1?" ":" ,"), i, val >> file
  }

  print ";" >> file

  close(file)
  sql = ""
}
' "$LOG_FILE"
