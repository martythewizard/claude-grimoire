#!/bin/bash

if [ ! -f "skills/initiative-discoverer/examples/discovery-results.md" ]; then
    echo "FAIL: Missing discovery-results.md example"
    exit 1
fi

if [ ! -f "skills/initiative-discoverer/examples/no-results.md" ]; then
    echo "FAIL: Missing no-results.md example"
    exit 1
fi

echo "PASS: All example files exist"
