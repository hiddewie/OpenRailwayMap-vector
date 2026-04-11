#!/usr/bin/env bash

set -eof pipefail

ajv validate --spec draft2020 --strict true --all-errors -s schema/signals_railway_signals.yaml signals_railway_signals.yaml
