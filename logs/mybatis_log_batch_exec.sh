#!/usr/bin/env bash

LOG_FILE="$1"
OUTPUT_DIR="$2"

if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" || -z "$OUTPUT_DIR" ]]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

awk -v outdir="$OUTPUT_DIR" '
# ---------- helpers ----------
function trim(s) {
  gsub(/^[ \t]+|[ \t]+$/, "", s)
  return s
}

function is_string(type) {
  return type ~ /(String|Date|Time|Timestamp|Char|Text|UUID|VARCHAR|NVARCHAR)/
}

function is_decimal(type) {
  return type ~ /(BigDecimal|Decimal|Numeric|Double|Float)/
}

function normalize_number(v) {
  if (v ~ /[eE]/)
    return sprintf("%.18f", v) + 0
  return v
}

# ---------- save one EXEC ----------
function save_exec() {
  if (sql == "") return

  fname = sprintf("%s/exec_%s_%03d.sql", outdir, ts_compact, exec_count)
  exec_count++

  print "-- Generated from MyBatis log" > fname
  if (ts != "")     print "-- Time   : " ts     >> fname
  if (mapper != "") print "-- Mapper : " mapper >> fname
  print "" >> fname

  # DECLARE OUT params
  for (i = 1; i <= param_count; i++) {
    if (param_mode[i] == "OUT") {
      print "DECLARE @p" i " INT;" >> fname
    }
  }

  if (out_count > 0) print "" >> fname

  print sql >> fname

  first = 1
  for (i = 1; i <= param_count; i++) {
    prefix = first ? "     " : "     ,"
    first = 0

    if (param_mode[i] == "OUT") {
      print prefix "@p" i " = @p" i " OUTPUT" >> fname
    } else {
      print prefix "@p" i " = " param_value[i] >> fname
    }
  }

  print ";" >> fname

  # SELECT OUT params
  for (i = 1; i <= param_count; i++) {
    if (param_mode[i] == "OUT") {
      print "SELECT @p" i " AS p" i ";" >> fname
    }
  }

  # reset state
  sql = ""
  param_count = 0
  out_count = 0
  delete param_value
  delete param_mode
}

# ---------- init ----------
BEGIN {
  exec_count = 1
  sql = ""
  param_count = 0
  out_count = 0
  ts = ""
  ts_compact = ""
  mapper = ""
}

# ---------- capture timestamp / mapper ----------
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
  ts = substr($0, 1, 19)
  ts_compact = ts
  gsub(/[^0-9]/, "", ts_compact)

  if (match($0, /[A-Za-z0-9_]+Mapper/))
    mapper = substr($0, RSTART, RLENGTH)
}

# ---------- Preparing ----------
/Preparing:/ {
  save_exec()

  sql = $0
  sub(/.*Preparing:[ \t]*/, "", sql)

  param_coun_
