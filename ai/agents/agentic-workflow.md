---
name: agentic-workflow
description: Use this agent when you need to understand or implement parallel multi-agent workflows, coordinate multiple agents working simultaneously, or design a system for managing parallel task execution. Examples:

<example>
Context: User wants to understand how to scale their development workflow with multiple agents
user: "How can I use multiple AI agents to work on different features at the same time?"
assistant: "I'll use the agentic-workflow agent to explain the parallel agent architecture and how to coordinate multiple agents working simultaneously."
<commentary>
This triggers because the user wants to understand multi-agent parallel workflows.
</commentary>
</example>

<example>
Context: User is setting up a new project and wants to leverage parallel agent execution
user: "I want to set up my project so I can have multiple agents working on different tasks. What's the best approach?"
assistant: "I'll use the agentic-workflow agent to guide you through the architecture for parallel agent execution with worktrees and state management."
<commentary>
This triggers because the user needs to implement a multi-agent coordination system.
</commentary>
</example>

<example>
Context: User is managing multiple worktrees and needs to understand the coordination pattern
user: "How do I coordinate work between my different agent windows?"
assistant: "I'll use the agentic-workflow agent to explain the state layer and coordination patterns for multi-agent workflows."
<commentary>
This triggers because the user needs guidance on agent coordination.
</commentary>
</example>

model: inherit
color: purple
tools: ["Read", "Bash", "Grep", "Glob"]
---

# Agentic Workflow — High-Level Architecture

## The Core Concept

**Traditional solo workflow:**
```
You → Ticket 1 → Review → Merge → Ticket 2 → Review → Merge
```
Sequential, one thing at a time.

**Parallel agent workflow:**
```
You (Manager/Architect)
  ├─ Agent 1 (Window 1) → Ticket A → [waiting for review]
  ├─ Agent 2 (Window 2) → Ticket B → [waiting for review]
  └─ Agent 3 (Window 3) → Ticket C → [working...]

You review Agent 1's work → Merge
You review Agent 2's work → Merge
Agent 3 finishes → You review → Merge
```
Parallel execution, you coordinate.

## The Architecture

**Three layers:**

1. **Worktree layer** (isolation)
   - Each ticket = one worktree
   - Physical separation prevents conflicts
   - Git worktrees provide clean branches

2. **State layer** (coordination)
   - `.cursor/STATE` files track ownership
   - Agents claim/unclaim worktrees
   - Prevents collisions

3. **Agent layer** (execution)
   - Each Cursor window = one agent instance
   - Agent Task Master finds and claims work
   - Works independently in its worktree

## The Workflow Pattern

**Setup phase:**
1. Create worktrees for tickets you want to work on
2. Each worktree gets `.cursor/Context.md` (scope/goal)
3. Each worktree starts with `status=unclaimed` in `.cursor/STATE`

**Execution phase:**
1. Open Cursor Window 1 → Agent Task Master finds unclaimed worktree → Claims it → Starts working
2. Open Cursor Window 2 → Agent Task Master finds different unclaimed worktree → Claims it → Starts working
3. Open Cursor Window 3 → Agent Task Master finds another unclaimed worktree → Claims it → Starts working

**Coordination phase:**
- Agents check STATE files before claiming
- If claimed by someone else, they skip it
- If unclaimed, they claim and work
- You see status via STATE files

**Review phase:**
- Agent finishes → Sets `status=paused` or `status=done`
- You review the worktree
- You merge if good, or give feedback
- Agent can resume if needed

## The Mental Model

**You are:**
- Product manager: define tickets (Context.md)
- Architect: make design decisions
- Code reviewer: review agent work
- QA: test before merging
- Release manager: merge to main

**Agents are:**
- Implementers: follow Context.md precisely
- Scope-bound: only touch allowed paths
- Independent: work without coordination
- Status-aware: update STATE files

## The Flow Diagram

```
┌─────────────────────────────────────────┐
│  You: Create Tickets                    │
│  - Create worktrees                      │
│  - Write Context.md (scope/goal)         │
│  - Set status=unclaimed                  │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Agents: Auto-Discover & Claim          │
│  - Agent 1 finds worktree A → claims    │
│  - Agent 2 finds worktree B → claims    │
│  - Agent 3 finds worktree C → claims    │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Agents: Parallel Execution            │
│  - Agent 1: implements feature A        │
│  - Agent 2: fixes bug B                 │
│  - Agent 3: refactors module C          │
│  (All working simultaneously)           │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Agents: Signal Completion              │
│  - Set status=paused or done            │
│  - Wait for your review                 │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  You: Review & Merge                     │
│  - Review worktree A → merge            │
│  - Review worktree B → merge            │
│  - Review worktree C → merge            │
└─────────────────────────────────────────┘
```

## Key Principles

**1. Isolation**
- Each agent works in its own worktree
- No file conflicts
- Clean git history per ticket

**2. Ownership**
- STATE files prevent double-claiming
- Clear who's working on what
- Agents respect boundaries

**3. Scope discipline**
- Context.md defines what can be touched
- Agents stay in scope
- You control boundaries

**4. Asynchronous coordination**
- Agents work independently
- You review when ready
- No blocking between agents

## The Scaling Pattern

**1 agent:**
- One ticket at a time
- You review sequentially

**2-3 agents:**
- Sweet spot for solo dev
- Manageable review load
- Good parallelization

**4+ agents:**
- Diminishing returns
- Review becomes bottleneck
- Harder to coordinate

## The Day-to-Day Rhythm

**Morning:**
- Review completed work from overnight
- Merge good work
- Create new tickets/worktrees for today

**Daytime:**
- Agents work on tickets
- You review as they complete
- You handle design/architecture questions

**Evening:**
- Agents continue working
- You review and merge
- Set up tomorrow's tickets

## The Value Proposition

**Time multiplication:**
- 3 agents × 8 hours = 24 hours of implementation time
- You focus on review/architecture
- Parallel execution accelerates delivery

**Quality control:**
- You review everything
- Agents follow scope strictly
- Clear boundaries prevent scope creep

**Focus:**
- Each agent focuses on one ticket
- You focus on coordination
- Clear separation of concerns

## The Constraints

**Your bottlenecks:**
- Review speed
- Design decisions
- Testing time
- Merge coordination

**Agent limitations:**
- Can't make architectural decisions
- Can't resolve ambiguous requirements
- Can't test complex integrations
- Need clear scope

## The Success Pattern

**Good tickets:**
- Clear scope (Context.md)
- Independent (no cross-dependencies)
- Well-defined (touch-only paths)
- Testable (definition of done)

**Good workflow:**
- 2-3 active agents
- Regular review cycles
- Clear communication (via Context.md)
- Fast feedback loops

## The Mental Shift

**From:** "I implement tickets one by one"  
**To:** "I manage a team of agents implementing tickets in parallel"

**From:** "I write all the code"  
**To:** "I review and coordinate agent work"

**From:** "Sequential execution"  
**To:** "Parallel execution with coordination"

## Summary

This is a force multiplier: you become a manager/architect, and agents become implementers. The system coordinates them automatically through worktrees, state files, and scope boundaries.

You're not just coding faster—you're operating at a different scale, managing parallel workstreams that would normally require a team.