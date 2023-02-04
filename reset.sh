#! /bin/bash

set -e pipefail

subject_error=$(curl -s localhost:8081/subjects/my-subject/versions | jq '.error_code?')

if [[ -n "$subject_error" ]]; then
  echo "subject does not exist -> nothing to do"
  exit 0
else
  echo "subject exists, will now try to delete it..."
fi

delete_res=$(curl -s -X DELETE localhost:8081/subjects/my-subject)
perm_delete_res=$(curl -s -X DELETE localhost:8081/subjects/my-subject?permanent=true)

delete_res_error_code=$(echo "$delete_res" | jq ".error_code?")
perm_delete_res_error_code=$(echo "$perm_delete_res" | jq ".error_code?")

if [[ -z "$delete_res_error_code" ]] && [[ -z "$perm_delete_res_error_code" ]]; then
  deleted_count=$(echo "$perm_delete_res" | jq "length")
  echo "Done: $deleted_count subject successfully deleted."
  docker-compose down
  exit 0
else
  echo "ERROR: Failed to delete subject: $delete_res_error_code -> $perm_delete_res_error_code"
  exit 1
fi
