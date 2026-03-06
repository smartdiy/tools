#!/bin/bash

# Base repo root (current directory)
REPO_ROOT="$(pwd)"

echo "Creating .copilot structure and populating markdown files under $REPO_ROOT"

# Create folders
mkdir -p "$REPO_ROOT/.copilot/agents"
mkdir -p "$REPO_ROOT/.copilot/skills"
mkdir -p "$REPO_ROOT/.copilot/tools"
mkdir -p "$REPO_ROOT/.copilot/prompts"
mkdir -p "$REPO_ROOT/.copilot/config"
mkdir -p "$REPO_ROOT/.copilot-output/2026-03-05"

# -------------------------------
# AGENTS
# -------------------------------
cat > "$REPO_ROOT/.copilot/agents/architect.md" << 'EOF'
# Agent: Architect
Model: Claude Sonnet

## Mission
Design architecture before coding begins.

## Responsibilities
- Understand business logic
- Define module boundaries
- Identify performance risks
- Define concurrency model

## Output
Write results to:
.copilot-output/{date}/01-architecture.md

## Format
- system overview
- module boundaries
- concurrency design
- refactor candidates
EOF

cat > "$REPO_ROOT/.copilot/agents/driver.md" << 'EOF'
# Agent: Driver
Model: GPT-5-mini

## Mission
Implement code based on architect instructions.

## Responsibilities
- follow architecture plan
- generate refactored code
- ensure logic equivalence

## Output
.copilot-output/{date}/04-refactored-code.md

## Constraints
- do not change business logic
- maintain API compatibility
EOF

cat > "$REPO_ROOT/.copilot/agents/reviewer.md" << 'EOF'
# Agent: Reviewer
Model: Claude Opus

## Mission
Deep review of refactored code.

## Responsibilities
- detect logic drift
- verify performance improvements
- check concurrency correctness

## Output
.copilot-output/{date}/06-review.md

## Output Sections
- logic comparison
- concurrency risks
- performance validation
EOF

cat > "$REPO_ROOT/.copilot/agents/tester.md" << 'EOF'
# Agent: Tester
Model: GPT-5-mini

## Mission
Generate tests for refactored code.

## Responsibilities
- unit tests
- concurrency tests
- regression tests

## Output
.copilot-output/{date}/05-test-plan.md
EOF

# -------------------------------
# SKILLS
# -------------------------------
cat > "$REPO_ROOT/.copilot/skills/architecture-design.md" << 'EOF'
# Skill: Architecture Design

Steps:
1. scan directories
2. detect major modules
3. identify entry points
4. identify core services
EOF

cat > "$REPO_ROOT/.copilot/skills/code-refactor.md" << 'EOF'
# Skill: Code Refactoring

Steps:
1. Identify duplication
2. simplify algorithms
3. improve readability
4. maintain behavior

Rules:
- preserve API
- preserve logic
- ensure testability
EOF

cat > "$REPO_ROOT/.copilot/skills/performance-analysis.md" << 'EOF'
# Skill: Performance Analysis

Focus areas:
- algorithm complexity
- thread contention
- database queries
- memory allocation

Output:
.copilot-output/{date}/02-analysis.md
EOF

cat > "$REPO_ROOT/.copilot/skills/concurrency-analysis.md" << 'EOF'
# Skill: Concurrency Analysis

Focus:
- deadlocks
- lock contention
- blocking operations
- unsafe shared state
EOF

cat > "$REPO_ROOT/.copilot/skills/test-generation.md" << 'EOF'
# Skill: Test Generation

Generate:
- unit tests
- concurrency tests
- integration tests
- regression tests
EOF

# -------------------------------
# TOOLS
# -------------------------------
cat > "$REPO_ROOT/.copilot/tools/code-search.md" << 'EOF'
# Tool: Code Search

Purpose:
Locate related code across repository.

Queries:
- class usage
- dependency graph
- method references
EOF

cat > "$REPO_ROOT/.copilot/tools/git-history.md" << 'EOF'
# Tool: Git History

Purpose:
Analyze repository commits for changes and trends.

Focus:
- commit frequency
- file changes
- authorship patterns
EOF

cat > "$REPO_ROOT/.copilot/tools/dependency-analysis.md" << 'EOF'
# Tool: Dependency Analysis

Purpose:
Identify module dependencies.

Focus:
- circular dependencies
- coupling
- service interactions
EOF

# -------------------------------
# CONFIG
# -------------------------------
cat > "$REPO_ROOT/.copilot/config/model-routing.md" << 'EOF'
# Copilot Model Routing Strategy

Goal: Minimize expensive model usage.

| Role | Model | Reason |
|-----|-----|-----|
Architect | Claude Sonnet | good reasoning but cheaper |
Driver | GPT-5-mini | cheap code generation |
Reviewer | Claude Opus | deep reasoning |
Tester | GPT-5-mini | cheap |
Performance Analyst | Claude Sonnet | good concurrency reasoning |

Rules:
1. Architecture and planning may use mid/high model.
2. Code generation uses cheap model.
3. Only review stage uses expensive model.
4. Batch all tasks into one request.
EOF

# -------------------------------
# PROMPTS
# -------------------------------
cat > "$REPO_ROOT/.copilot/prompts/daily-orchestrator.md" << 'EOF'
# Daily AI Engineering Workflow

You are a multi-agent AI system.

Agents:
Architect
Driver
Reviewer
Tester

Follow this pipeline.

Step 1 — Architect
Analyze repository and produce architecture report.
Output: .copilot-output/{date}/01-architecture.md

Step 2 — Performance Analysis
Output: .copilot-output/{date}/02-analysis.md

Step 3 — Refactor Plan
Output: .copilot-output/{date}/03-refactor-plan.md

Step 4 — Code Refactor
Output: .copilot-output/{date}/04-refactored-code.md

Step 5 — Generate Tests
Output: .copilot-output/{date}/05-test-plan.md

Step 6 — Deep Review
Output: .copilot-output/{date}/06-review.md

Rules:
- simulate each agent
- use assigned models
- preserve business logic
- ensure performance improvements
EOF

cat > "$REPO_ROOT/.copilot/prompts/refactor-workflow.md" << 'EOF'
# Refactor Workflow

Agents active:
- Architect
- Refactorer
- Verifier
- Documenter

Goal:
Improve maintainability while preserving behavior.

Output Channels:
#architecture
#refactor
#verification
#documentation
EOF

cat > "$REPO_ROOT/.copilot/prompts/performance-workflow.md" << 'EOF'
# Performance Workflow

Agents active:
- Architect
- Performance Engineer
- Verifier
- Documenter

Focus:
runtime efficiency and scalability.

Output Channels:
#architecture
#performance
#verification
#documentation
EOF

# -------------------------------
# OUTPUT FILES
# -------------------------------
touch "$REPO_ROOT/.copilot-output/2026-03-05/01-architecture.md"
touch "$REPO_ROOT/.copilot-output/2026-03-05/02-analysis.md"
touch "$REPO_ROOT/.copilot-output/2026-03-05/03-refactor-plan.md"
touch "$REPO_ROOT/.copilot-output/2026-03-05/04-refactored-code.md"
touch "$REPO_ROOT/.copilot-output/2026-03-05/05-test-plan.md"
touch "$REPO_ROOT/.copilot-output/2026-03-05/06-review.md"
touch "$REPO_ROOT/.copilot-output/index.md"

echo "✅ All markdown files created with content successfully!"
