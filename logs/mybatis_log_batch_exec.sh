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

# replace single quotes inside strings
function escape_single_quotes(s,   i, c, out) {
    out=""
    for(i=1;i<=length(s);i++){
        c=substr(s,i,1)
        if(c=="'") out = out "''"
        else out = out c
    }
    return out
}

BEGIN { idx=1 }

/Preparing:/ {
  sql = $0
  sub(/.*Preparing:[[:space:]]*/,"",sql)
  gsub(/[{}]/,"",sql)
  gsub(/\([[:space:]]*\?[[:space:]]*(,[[:space:]]*\?)*[[:space:]]*\)/,"",sql)
  sql=trim(sql)
  next
}

/Parameters:/ && sql != "" {
  file = sprintf("%s/exec_%03d.sql", outdir, idx++)
  line = $0
  sub(/.*Parameters:[[:space:]]*/,"",line)
  n = split(line, arr, ", ")

  vals=""
  for(i=1;i<=n;i++){
    raw = trim(arr[i])
    val = raw
    # remove (Type)
    sub(/\([^)]+\)$/,"",val)
    val = trim(val)

    if(tolower(val)=="null"){
        val_out="NULL"
    } else if(is_number(val)){
        val_out=normalize(val)
    } else {
        val_clean = escape_single_quotes(val)
        val_out = sprintf("%c%s%c", 39, val_clean, 39)
    }

    vals = vals (i==1?"":", ") val_out
  }

  print sql " " vals ";" > file
  close(file)
  sql=""
}
' "$LOG_FILE"
