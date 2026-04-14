#!/bin/bash

if ! grep -q "^name: initiative-discoverer$" skills/initiative-discoverer/skill.md; then
    echo "FAIL: Missing or incorrect skill name"
    exit 1
fi

if ! grep -q "^description:" skills/initiative-discoverer/skill.md; then
    echo "FAIL: Missing description"
    exit 1
fi

if ! grep -q "^version: 1.0.0$" skills/initiative-discoverer/skill.md; then
    echo "FAIL: Missing or incorrect version"
    exit 1
fi

echo "PASS: Skill metadata is valid"
