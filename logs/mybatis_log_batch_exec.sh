#!/usr/bin/env bash

# Usage:
#   ./mybatis_log_to_sql.sh application.log > replay.sql

LOG_FILE="$1"

if [ $# -ne 1 ] || [ ! -f "$LOG_FILE" ]; then
  echo "Usage: $0 mybatis.log"
  exit 1
fi

awk '
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

# -------- capture SQL --------
/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/, "", sql)
  next
}

# -------- capture params & emit --------
/Parameters:/ && sql != "" {
  line = $0
  sub(/.*Parameters:[[:space:]]*/, "", line)

  n = split(line, a, ", ")

  print sql

  for (i = 1; i <= n; i++) {
    entry = trim(a[i])

    # null
    if (tolower(entry) == "null") {
      printf "%s@p%d = NULL\n", (i==1?" ":" ,"), i
      continue
    }

    # extract type
    type = entry
    sub(/^.*\(/, "", type)
    sub(/\)$/, "", type)

    # extract value
    val = entry
    sub(/\([^)]+\)$/, "", val)
    val = trim(val)

    if (is_string(type)) {
      gsub(/'\''/, "''''", val)
      val = "'" val "'"
    } else if (is_decimal(type)) {
      val = normalize(val)
    }

    printf "%s@p%d = %s\n", (i==1?" ":" ,"), i, val
  }

  print ";"
  print ""

  sql = ""
}
' "$LOG_FILE"
