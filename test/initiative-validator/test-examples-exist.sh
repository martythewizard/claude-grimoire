#!/bin/bash

EXAMPLES_DIR="skills/initiative-validator/examples"

if [ ! -f "$EXAMPLES_DIR/valid-report.md" ]; then
    echo "FAIL: Missing valid-report.md example"
    exit 1
fi

if [ ! -f "$EXAMPLES_DIR/missing-milestone-report.md" ]; then
    echo "FAIL: Missing missing-milestone-report.md example"
    exit 1
fi

if [ ! -f "$EXAMPLES_DIR/invalid-schema-report.md" ]; then
    echo "FAIL: Missing invalid-schema-report.md example"
    exit 1
fi

echo "PASS: All example files exist"
