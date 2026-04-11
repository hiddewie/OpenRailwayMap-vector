#!/usr/bin/env bash

set -eof pipefail

ajv validate --spec draft2020 --errors text --strict true --all-errors -s schema/signals_railway_signals.yaml -d signals_railway_signals.yaml
