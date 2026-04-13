# Claude Grimoire 🔮

**A reusable agentic toolkit for Product Engineers** - Skills, agents, and teams that make your work across repositories efficient and repeatable.

## Overview

Claude Grimoire is a Claude Code plugin that provides:

- **Skills** - User-invocable workflows for common tasks (PR authoring, visual PRDs, incident handling)
- **Agents** - Specialized subagents for autonomous work (GitHub context gathering, incident analysis, documentation)
- **Teams** - Multi-agent orchestration for complex workflows (feature delivery, incident response, PR automation)

Built specifically for Product Engineers who work across multiple repositories and need efficient, repeatable workflows for:
- Creating comprehensive PR descriptions with proper issue references
- Planning features with visual PRDs and architectural diagrams
- Handling incidents from alert to post-mortem
- Breaking down initiatives into actionable tasks
- Automating the PR process after code review

## Quick Start

### Installation

```bash
# Install as a Claude Code plugin
/plugin install claude-grimoire

# Or clone for customization
git clone https://github.com/yourusername/claude-grimoire
cd claude-grimoire
```

### First Use

```bash
# Make a change in your repo
git checkout -b feature/my-change
# ... make changes ...
git add .
git commit -m "Add feature"

# Generate a comprehensive PR description
/pr-author
```

That's it! The skill will analyze your changes, fetch related GitHub issues, and generate a professional PR description.

## Skills

### 🎯 pr-author
Generate comprehensive PR descriptions with GitHub issue references.

```bash
/pr-author
```

**When to use:** Ready to create a PR and need a clear description

**What it does:**
- Analyzes your git changes
- Fetches related GitHub issues/initiatives
- Generates structured PR description with test plan
- Optionally creates the PR for you

[Full documentation →](skills/pr-author/skill.md)

---

### 📐 visual-prd
Create visual Product Requirements Documents with interactive mockups and diagrams.

```bash
/visual-prd
```

**When to use:** Starting a complex feature that needs visual planning

**What it does:**
- Interviews you about feature requirements
- Creates UI mockups and user flows
- Generates architecture diagrams
- Outputs HTML for GitHub Pages

[Full documentation →](skills/visual-prd/skill.md) *(Phase 2)*

---

### 📋 initiative-creator
Create well-structured GitHub initiatives with proper metadata.

```bash
/initiative-creator
```

**When to use:** Starting a new initiative or large project

**What it does:**
- Guides you through initiative planning
- Creates GitHub initiative with proper structure
- Links related issues and stakeholders
- Optionally generates visual PRD

[Full documentation →](skills/initiative-creator/skill.md) *(Phase 2)*

---

### 🔨 initiative-breakdown
Break GitHub initiatives into actionable tasks with acceptance criteria.

```bash
/initiative-breakdown https://github.com/org/repo/issues/123
```

**When to use:** After initiative creation, ready for execution planning

**What it does:**
- Fetches initiative details
- Analyzes current codebase
- Generates ordered tasks with dependencies
- Creates GitHub issues linked to parent initiative

[Full documentation →](skills/initiative-breakdown/skill.md) *(Phase 2)*

---

### 🚨 incident-handler
End-to-end incident response from alert to post-mortem.

```bash
/incident-handler
```

**When to use:** Responding to production incidents or alerts

**What it does:**
- Gathers context from Firehydrant and logs
- Guides diagnosis and root cause analysis
- Helps implement and test the fix
- Generates post-mortem documentation

[Full documentation →](skills/incident-handler/skill.md) *(Phase 3)*

## Agents

Agents are specialized subagents that skills and teams delegate to. They run autonomously and return structured results.

### 🔍 github-context-agent
Gather comprehensive GitHub context for issues, initiatives, and PRs.

**Invoked by:** pr-author, initiative-breakdown, initiative-creator, feature-delivery-team

[Full documentation →](agents/github-context-agent/agent.md)

---

### 🔥 incident-context-agent
Query Firehydrant and affected services for incident intelligence.

**Invoked by:** incident-handler, incident-response-team

[Full documentation →](agents/incident-context-agent/agent.md) *(Phase 3)*

---

### 📝 documentation-agent
Generate post-mortems and technical documentation.

**Invoked by:** incident-handler, incident-response-team, pr-autopilot-team

[Full documentation →](agents/documentation-agent/agent.md) *(Phase 3)*

---

### 🏗️ system-architect-agent
Design abstraction layers and create architecture visualizations with mermaid diagrams.

**Invoked by:** visual-prd, initiative-breakdown, feature-delivery-team

[Full documentation →](agents/system-architect-agent/agent.md) *(Phase 2)*

## Teams

Teams orchestrate multiple agents and skills for complex end-to-end workflows.

### 🚀 feature-delivery-team
Complete feature delivery from planning to implementation.

**Workflow:** Planning → Architecture → Visual PRD → Breakdown → Plan Review → Implementation → Code Review

[Full documentation →](teams/feature-delivery-team/team.md) *(Phase 4)*

---

### 🆘 incident-response-team
End-to-end incident response from alert to documentation.

**Workflow:** Context Gathering → Diagnosis → Plan Review → Implementation → Code Review → Verification → Documentation

[Full documentation →](teams/incident-response-team/team.md) *(Phase 3)*

---

### 🤖 pr-autopilot-team
Fully automated PR creation after code review passes.

**Workflow:** Verification → Context Gathering → PR Generation → Git Operations → PR Creation

[Full documentation →](teams/pr-autopilot-team/team.md) *(Phase 4)*

## Configuration

### Per-Repository Config

Create `.claude-grimoire/config.json` in your repository:

```json
{
  "github": {
    "defaultLabels": ["needs-review", "automated"],
    "defaultReviewers": ["team-lead", "senior-dev"],
    "codeownersPath": ".github/CODEOWNERS"
  },
  "prAuthor": {
    "titlePrefix": "[FEAT]",
    "requireIssueReference": true,
    "includeTestPlan": true
  },
  "prAutopilot": {
    "autoAssignReviewers": true,
    "setAsDraft": false,
    "runTests": true
  }
}
```

### Global Config

Create `~/.claude/claude-grimoire/config.json`:

```json
{
  "firehydrant": {
    "apiUrl": "https://api.firehydrant.io",
    "orgSlug": "your-org"
  },
  "coralogix": {
    "apiUrl": "https://api.coralogix.com",
    "region": "us"
  },
  "github": {
    "org": "your-org",
    "defaultRepos": ["repo1", "repo2"]
  }
}
```

### Environment Variables

```bash
# Required
export GITHUB_TOKEN=ghp_your_token_here

# Optional (for incident-handler)
export FIREHYDRANT_API_KEY=your_key
export CORALOGIX_API_KEY=your_key
export COMPANY_CLI_PATH=/path/to/cli
```

## Documentation

- [Getting Started Guide](docs/getting-started.md)
- [Skills Reference](docs/skills-reference.md) *(Coming soon)*
- [Agents Reference](docs/agents-reference.md) *(Coming soon)*
- [Teams Reference](docs/teams-reference.md) *(Coming soon)*
- [Examples](docs/examples/)

## Roadmap

### ✅ Phase 1: Foundation & Core Skills (Current)
- [x] Project structure and plugin.json
- [x] pr-author skill
- [x] github-context-agent
- [x] Basic documentation

### 🚧 Phase 2: Planning & Breakdown Tools
- [ ] initiative-creator skill
- [ ] initiative-breakdown skill
- [ ] visual-prd skill
- [ ] system-architect-agent

### 📋 Phase 3: Incident Response
- [ ] incident-handler skill
- [ ] incident-context-agent
- [ ] documentation-agent
- [ ] incident-response-team

### 📋 Phase 4: Advanced Teams
- [ ] feature-delivery-team
- [ ] pr-autopilot-team
- [ ] Integration with staff-developer and staff-engineer

### 📋 Phase 5: Polish & Documentation
- [ ] Complete documentation suite
- [ ] Example repositories
- [ ] Marketplace submission

## Architecture

```
Layer 1: Skills → User-invocable workflows (entry points)
Layer 2: Agents → Specialized subagents (autonomous workers)
Layer 3: Teams → Multi-agent orchestration (complex workflows)
```

**Principles:**
- **Portability** - Each component works independently
- **Composability** - Skills call agents, teams call skills and agents
- **Discoverability** - Clear naming and organization
- **Marketplace-Ready** - Follows Claude marketplace plugin format

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/claude-grimoire/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/claude-grimoire/discussions)
- **Documentation:** [Full Docs](docs/)

## Acknowledgments

Built for Product Engineers who need efficient, repeatable workflows across repositories. Inspired by the pain points of context switching, inconsistent PR descriptions, and manual workflow orchestration.

Special thanks to the Claude Code team for building an extensible platform for agentic tooling.

---

**Made with 🔮 by Product Engineers, for Product Engineers**
