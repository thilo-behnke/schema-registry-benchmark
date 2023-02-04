#! /bin/bash

set -e

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

n="$1"
if [[ -z "$n" ]]; then
  n=1
fi

echo "Called to create $n schemas. This might take a while!"

for i in $(seq $n); do
  createSchema "$i";
  if [[ $(($i%100)) == 0 ]]; then
    echo "In progress: created $i schemas so far..."
  fi
done

echo "Done. Created $n schemas in total."

