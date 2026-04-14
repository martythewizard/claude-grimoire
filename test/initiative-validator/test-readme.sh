#!/bin/bash

if ! grep -q "initiative-validator" README.md; then
    echo "FAIL: initiative-validator not mentioned in README.md"
    exit 1
fi

if ! grep -q "/initiative-validator" README.md; then
    echo "FAIL: Missing skill invocation example in README.md"
    exit 1
fi

echo "PASS: README.md documents initiative-validator skill"
