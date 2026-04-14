#!/bin/bash

# Test: skill.md has required frontmatter
if ! grep -q "^name: initiative-validator$" skills/initiative-validator/skill.md; then
    echo "FAIL: Missing or incorrect skill name in frontmatter"
    exit 1
fi

if ! grep -q "^description:" skills/initiative-validator/skill.md; then
    echo "FAIL: Missing description in frontmatter"
    exit 1
fi

if ! grep -q "^version: 1.0.0$" skills/initiative-validator/skill.md; then
    echo "FAIL: Missing or incorrect version in frontmatter"
    exit 1
fi

echo "PASS: Skill metadata is valid"
