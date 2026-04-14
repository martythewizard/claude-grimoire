# Feature Delivery Team - Project Workflow

## Scenario

User wants to add tasks to an existing GitHub Project.

## Flow

```
User: I need to add observability tasks to project 14

Team Phase 1:
  Skill: Invoking github-context-agent with project eci-global#14...
  
  ✓ Project found: 2026 Q1 - AI Cost Intelligence Platform
    Related initiative detected
    
Team Phase 3:
  Skill: Invoking /initiative-breakdown with project...
  
  Created 3 observability tasks, linked to project
  
Team Phase 5-7:
  [Implement → Review → PR]
  
  PR includes project reference

✅ Complete
```
