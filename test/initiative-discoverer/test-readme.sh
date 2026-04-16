#!/bin/bash

if ! grep -q "initiative-discoverer" README.md; then
    echo "FAIL: initiative-discoverer not mentioned in README.md"
    exit 1
fi

if ! grep -q "/initiative-discoverer" README.md; then
    echo "FAIL: Missing skill invocation example in README.md"
    exit 1
fi

echo "PASS: README.md documents initiative-discoverer skill"
