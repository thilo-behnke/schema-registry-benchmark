#! /bin/bash

set -e

log_dir=logs/query
query_stats_log=query-stats.log

function query_schema {
  before=$(date +%s%3N)
  echo "$(date +%d.%m.%Y-%H:%M:%S) Querying schema version $1..." >> "$log_dir/$query_stats_log"
  after=$(date +%s%3N)
  create_res=$(curl -s localhost:8081/subjects/my-subject/versions/$1)
  error_code=$(echo "$create_res" | jq ".error_code?")
  error_message=$(echo "$create_res" | jq ".message?")
  if [[ "$error_code" != "null" ]]; then
    echo "Failed to query schema: $error_code -> $error_message"
    echo "Schema: $payload"
    exit 1
  fi
  echo "$(date +%d.%m.%Y-%H:%M:%S) Retrieved schema version $1: $create_res" >> "$log_dir/$query_stats_log"
  echo "$(date +%d.%m.%Y-%H:%M:%S) Schema query took $((after-before)) ms." >> "$log_dir/$query_stats_log"
}

rm -rf $log_dir
mkdir -p $log_dir

echo "Launching docker containers..."
docker-compose up -d > /dev/null
sleep 10s
echo "Docker containers ready."

n="$1"
if [[ -z "$n" ]]; then
  n=1
fi

offset="$2"
if [[ -z "$offset" ]]; then
  offset=0
fi

echo "Called to query $n schemas with offset $offset. This might take a while!"

for i in $(seq $(($offset+1)) $(($n+$offset))); do
  query_schema "$i";
  if [[ $(($i%100)) == 0 ]]; then
    echo "In progress: queried $i schemas so far..."
  fi
done

echo "Done. Queried $n schemas in total."

