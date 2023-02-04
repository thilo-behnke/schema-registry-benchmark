#! /bin/bash

set -e

log_dir=logs
docker_usage_log=docker_usage.log
java_heap_log=java-heap.log

function createSchema {
  payload='{"schemaType": "AVRO", "schema": "{\"name\": \"MyRecord\", \"type\": \"record\", \"test.field\": \"'$1'\", \"fields\": ['
  payload="$payload"'{\"name\": \"first_name\", \"type\": \"string\"}'
  payload="$payload"', {\"name\": \"last_name\", \"type\": \"string\"}'
  payload="$payload"', {\"name\": \"address\", \"type\": \"string\"}'
  payload="$payload"', {\"name\": \"zip\", \"type\": \"int\"}'
  payload="$payload"', {\"name\": \"country\", \"type\": {\"type\": \"enum\", \"name\": \"country_enum\", \"symbols\": [\"DE\", \"AU\"]}}'
  payload="$payload"', {\"name\": \"interests\", \"type\": {\"type\": \"array\", \"items\": \"string\"}}'
  payload="$payload"']}"}'
#  echo "PAYLOAD: $payload"
  create_res=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" localhost:8081/subjects/my-subject/versions)
  error_code=$(echo "$create_res" | jq ".error_code?")
  error_message=$(echo "$create_res" | jq ".message?")
  if [[ "$error_code" != "null" ]]; then
    echo "Failed to create schema: $error_code -> $error_message"
    echo "Schema: $payload"
    exit 1
  fi
}

function log_docker_usage {
  if [[ ! -f "$log_dir/$docker_usage_log" ]]; then
    echo "TIME" "TIMESTAMP" "NR SCHEMAS" $(docker stats schema-registry-tests_schema-registry_1 --no-stream | head -1) >> "$log_dir/$docker_usage_log"
  fi
  echo $(date +%d.%m.%Y-%H:%M:%S) "$i" $(docker stats schema-registry-tests_schema-registry_1 --no-stream | tail -1) >> "$log_dir/$docker_usage_log"
}

function log_java_heap_histo {
  docker exec -it schema-registry-tests_schema-registry_1 /bin/bash -c "jmap -histo 1 | head -50" >> "$log_dir/$(date +%s)_$1_$java_heap_log"
}

rm -rf $log_dir
mkdir -p $log_dir

echo "Launching docker containers..."
docker-compose down > /dev/null
docker-compose up -d > /dev/null
sleep 10s
echo "Docker containers ready."

n="$1"
if [[ -z "$n" ]]; then
  n=1
fi

echo "Called to create $n schemas. This might take a while!"

for i in $(seq $n); do
  i_padded="$(printf '0%.0s' $(seq $(($(echo "$n" | wc -c)-$(echo "$i" | wc -c)))))$i"
  createSchema "$i_padded";
  if [[ $(($i%100)) == 0 ]]; then
    log_docker_usage $i_padded
    echo "In progress: created $i_padded schemas so far..."
  fi
  if [[ $(($i%1000)) == 0 ]]; then
    log_java_heap_histo "$i_padded"
  fi
done

echo "Done. Created $n schemas in total."

