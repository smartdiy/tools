#!/usr/bin/env bash

LOG_FILE="$1"
OUTPUT_DIR="$2"

if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" || -z "$OUTPUT_DIR" ]]; then
  echo "Usage: $0 mybatis.log output_dir"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

awk -v outdir="$OUTPUT_DIR" '
function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
function is_string(type){return type ~ /(String|Date|Time|Timestamp|Char|Text|UUID)/}
function is_decimal(type){return type ~ /(BigDecimal|Decimal|Numeric|Double|Float)/}
function normalize_number(v){
  if(v ~ /[eE]/) return sprintf("%.18f", v)+0
  return v
}

function save_exec(){
  if(sql=="") return
  fname = sprintf("%s/exec_%s_%03d.sql", outdir, gsub_ts, exec_count)
  exec_count++

  print "-- " ts " | " mapper > fname
  for(i=1;i<=param_count;i++){
    if(param_value[i]=="OUT")
      print "DECLARE @p" i " INT;" >> fname
  }

  print "" >> fname
  print sql >> fname

  first=1
  for(i=1;i<=param_count;i++){
    prefix = first?"     ":"     ,"
    first=0
    if(param_value[i]=="OUT")
      print prefix "@p" i " = @p" i " OUTPUT" >> fname
    else
      print prefix "@p" i " = " param_value[i] >> fname
  }
  print ";" >> fname

  for(i=1;i<=param_count;i++)
    if(param_value[i]=="OUT")
      print "SELECT @p" i " AS p" i ";" >> fname

  # reset
  sql=""
  param_count=0
}

# reset counters
BEGIN{exec_count=1; gsub_ts=""; sql=""; param_count=0; mapper=""}

# capture timestamp + mapper (if present)
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/{
  ts = substr($0,1,19)
  gsub_ts = gensub(/[^0-9]/,"","g",ts)
  if(match($0, /[A-Za-z0-9_]+Mapper/))
    mapper = substr($0,RSTART,RLENGTH)
}

# Preparing line
/Preparing:/{
  save_exec()
  sql=$0
  sub(/.*Preparing:[ \t]*/, "", sql)
  collecting=1
  param_count=0
  delete param_value
  next
}

# Parameters line
/Parameters:/ && collecting{
  params=$0
  sub(/.*Parameters:[ \t]*/, "", params)
  split(params, arr, ", ")

  for(i=1;i<=length(arr);i++){
    val=arr[i]
    param_count++
    if(val ~ /^null/i){
      param_value[param_count]="OUT"
      continue
    }
    match(val,/^[^(]+/)
    v=trim(substr(val,RSTART,RLENGTH))
    match(val, /\(([^)]+)\)/, t)
    type=t[1]

    if(v != "NULL" && is_string(type)){
      gsub(/'\''/,"''''",v)
      v="'" v "'"
    } else if(v != "NULL" && is_decimal(type)){
      v=normalize_number(v)
    }

    param_value[param_count]=v
  }

  collecting=0
}

END{save_exec()}
' "$LOG_FILE"
