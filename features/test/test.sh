#!/usr/bin/env bash

set -eo pipefail

for file in *.yaml
do
  ajv validate --spec draft2020 --strict true --all-errors -s "schema/$file" "$file"
done
