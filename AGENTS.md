# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete. Each iteration is a fresh Claude code instance with clean context.

## Key Files

- `ralph.sh` - The bash loop that spawns fresh Claude Code instances
- `prompt.md` - Instructions given to each Claude Code instance
- `prd.json.example` - Example PRD format
- `ralph-flowchart/` - Flow diagram explaining how Ralph works

## Patterns

- Each iteration spawns a fresh Claude Code instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Always update AGENTS.md with discovered patterns for future iterations
