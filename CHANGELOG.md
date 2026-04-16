# Changelog

All notable changes to Claude Grimoire will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-04-15

### Added
- Optional `repo` field for JIRA tasks in initiative schema v2.1
- Milestone-based repo inference when field omitted
- Cross-repo tracking support with validation warnings
- Ambiguous milestone detection

### Changed
- initiative-validator (v2.1.0): Repo-aware validation with inference
- initiative-discoverer (v2.1.0): Repo-aware deduplication (repo|num format)

### Fixed
- Issue number collision in multi-repo initiatives

### Compatibility
- Backward compatible with schema v2.0 (no breaking changes)

## [2.0.0] - 2026-04-14

### Added
- Schema v2 support for initiative YAML files
- GitHub Project v2 validation
- Workstreams with milestone objects
- JIRA epic task validation with github_issue references

### Changed
- initiative-validator: Supports schema v2
- initiative-discoverer: GitHub-first workflow

### Breaking Changes
- Schema v1 no longer supported (use v1.0.0 for legacy files)

## [1.0.0] - 2026-04-13

### Added
- Initial release of Claude Grimoire
- pr-author skill
- incident-handler skill
- github-context-agent
- incident-context-agent
- documentation-agent
- feature-delivery-team
- pr-autopilot-team
- incident-response-team
