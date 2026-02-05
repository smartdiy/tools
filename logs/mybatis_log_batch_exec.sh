#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="$1"
OUTPUT_DIR="$2"

if [ $# -ne 2 ] || [ ! -f "$LOG_FILE" ]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

awk -v outdir="$OUTPUT_DIR" <<'AWK'
# ---------- utils ----------
function trim(s) {
  gsub(/^[ \t\r\n]+/, "", s)
  gsub(/[ \t\r\n]+$/, "", s)
  return s
}

function is_string(t) {
  return t ~ /(String|Char|Text|UUID|Date|Time|Timestamp|VARCHAR|NVARCHAR)/i
}

function is_decimal(t) {
  return t ~ /(BigDecimal|Decimal|Numeric|Double|Float)/i
}

function normalize_number(v) {
  if (v ~ /[eE]/)
    return sprintf("%.18f", v) + 0
  return v
}

# ---------- flush ----------
function flush_exec() {
  if (sql == "") return

  file = sprintf("%s/exec_%s_%03d.sql", outdir, ts_compact, exec_no++)
  print "-- Generated from MyBatis log" > file
  if (ts != "")     print "-- Time   : " ts >> file
  if (mapper != "") print "-- Mapper : " mapper >> file
  print "" >> file

  for (i = 1; i <= param_cnt; i++) {
    if (param_mode[i] == "OUT")
      print "DECLARE @p" i " INT;" >> file
  }

  if (out_cnt > 0) print "" >> file

  print sql >> file

  sep = " "
  for (i = 1; i <= param_cnt; i++) {
    if (param_mode[i] == "OUT")
      printf "%s@p%d = @p%d OUTPUT\n", sep, i, i >> file
    else
      printf "%s@p%d = %s\n", sep, i, param_val[i] >> file
    sep = ","
  }

  print ";" >> file

  for (i = 1; i <= param_cnt; i++) {
    if (param_mode[i] == "OUT")
      print "SELECT @p" i " AS p" i ";" >> file
  }

  # reset
  sql = ""
  param_cnt = out_cnt = 0
  delete param_val
  delete param_mode
}

# ---------- init ----------
BEGIN {
  exec_no = 1
  sql = ""
  collecting = 0
}

# ---------- timestamp / mapper ----------
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
  ts = substr($0, 1, 19)
  ts_compact = ts
  gsub(/[^0-9]/, "", ts_compact)

  if (match($0, /[A-Za-z0-9_]+Mapper/))
    mapper = substr($0, RSTART, RLENGTH)
}

# ---------- Preparing ----------
/Preparing:/ {
  flush_exec()

  sql = $0
  sub(/.*Preparing:[ \t]*/, "", sql)

  param_cnt = out_cnt = 0
  collecting = 1
  next
}

# ---------- Parameters ----------
/Parameters:/ && collecting {
  line = $0
  sub(/.*Parameters:[ \t]*/, "", line)

  n = split(line, arr, ", ")

  for (i = 1; i <= n; i++) {
    param_cnt++
    entry = trim(arr[i])

    if (tolower(entry) == "null") {
      param_mode[param_cnt] = "OUT"
      param_val[param_cnt]  = "NULL"
      out_cnt++
      continue
    }

    type = entry
    sub(/^.*\(/, "", type)
    sub(/\)$/, "", type)

    val = entry
    sub(/\([^)]+\)$/, "", val)
    val = trim(val)

    if (is_string(type)) {
      gsub(/'/, "''", val)
      val = "'" val "'"
    } else if (is_decimal(type)) {
      val = normalize_number(val)
    }

    param_mode[param_cnt] = "IN"
    param_val[param_cnt]  = val
  }

  collecting = 0
}

END {
  flush_exec()
}
AWK

