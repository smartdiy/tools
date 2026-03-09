# Maven Execution Authority

Rule:

- Implementor and Tester have full authority to execute Maven commands as needed to complete their task.
- This includes:
  - `mvn compile`, `mvn test`, `mvn package`, `mvn install`, etc.
- No human approval or discussion is required for executing Maven commands.
- All other workflow rules remain:
  - Implementor ↔ Reviewer for design review
  - Implementor ↔ Tester for testing iterations
  - Architect, Auditor, Documentor phases continue as usual

# /auto-dev

Run the **AI Development Team workflow**.

This command orchestrates multiple agents to complete a development task.

---

# Parameters

Task (required)

Description of today's work.

Agents (optional)

Comma-separated list of agents to use.

If **Agents parameter is not provided**, the system uses the **default agent team**.

---

# Default Agent Team

If no agents are specified, use the following agents:

architect
implementor
reviewer
tester
documentor
auditor
performance-engineer
concurrency-engineer
db-optimizer
messaging-architect
security-auditor
observability-engineer
microservice-designer
rest-api-designer
cache-optimizer
docker-k8s-engineer
legacy-migration-engineer
test-generator
integration-tester
performance-tester
compliance-auditor
trace-analyzer
logging-engineer
config-manager
refactor-engineer
task-planner
devops-engineer
api-gateway-designer
cloud-security-engineer
observability-consultant
release-manager

---

# Agent Selection Logic

1. If `Agents` parameter is provided:

   * Use only those agents.

2. If `Agents` parameter is NOT provided:

   * Use the Default Agent Team.

3. Agents not listed must not participate.

---

# Input Examples

Default team:

```
/auto-dev
Task: Fix deadlock in OrderService transaction handling
```

Custom team:

```
/auto-dev
Agents: architect,implementor,reviewer,tester
Task: Implement new REST API for transaction history
```

Performance investigation example:

```
/auto-dev
Agents: architect,performance-engineer,concurrency-engineer,db-optimizer,tester
Task: Investigate slow order processing under high concurrency
```

---

# Workflow Execution

The workflow executes the following phases.

Only the selected agents participate.

---

# Phase 1 — Architecture Analysis

Agent:

architect

Responsibilities:

* analyze the task
* evaluate current architecture
* identify affected modules
* define architecture solution

Output:

* architecture overview
* module changes
* API changes
* risks and constraints

No code generation allowed.

---

# Phase 2 — Implementation Design

Agent:

implementor

Responsibilities:

* read architecture output
* design implementation strategy
* define classes and modules
* describe algorithms and logic
* **Can execute Maven commands** as needed to build, compile, or verify code
* Participate in design review iterations with Reviewer

Output:

* class structure
* module interactions
* algorithm outline

No implementation code yet.

---

# Phase 3 — Design Review Iterations

Agents:

reviewer
implementor

Process:

1 Reviewer evaluates design.
2 Implementor responds to feedback.
3 Reviewer reassesses.

Rules:

* Minimum **3 iterations**
* Stop early if agreement is reached.
* **Can execute Maven commands** as needed to build, compile, or verify code
* Participate in design review iterations with Implementor

Label iterations:

Design Review Iteration 1
Design Review Iteration 2
Design Review Iteration 3

---

# Phase 4 — Implementation

Agent:

implementor

Responsibilities:

* implement the solution
* follow coding standards
* maintain backward compatibility

Output:

* source code
* explanation of key logic

---

# Phase 5 — Testing Iterations

Agents:

tester
implementor

Tester responsibilities:

* generate unit tests
* generate integration tests
* generate performance tests if needed

Tester reviews implementation and provides feedback.

Implementor adjusts code accordingly.

Rules:

Minimum **3 testing iterations**.

Label iterations:

Test Iteration 1
Test Iteration 2
Test Iteration 3

---

# Phase 6 — Documentation

Agent:

documentor

Document:

* architecture decisions
* design decisions
* implementation changes
* API updates
* configuration changes

Include reasoning for decisions.

---

# Phase 7 — Audit

Agent:

auditor

Audit must verify:

* architecture compliance
* coding standards
* security risks
* performance risks
* test completeness

Output:

Audit report.

---

# Phase 8 — Final Architecture Report

Agent:

architect

Produce final report including:

* task summary
* architecture decisions
* implementation results
* testing outcomes
* audit findings
* final project status

---

# Output Structure

The response must contain the following sections:

Phase 1 — Architect Analysis
Phase 2 — Implementation Design
Phase 3 — Design Review Iterations
Phase 4 — Implementation
Phase 5 — Testing Iterations
Phase 6 — Documentation
Phase 7 — Audit Report
Phase 8 — Final Architecture Report

---

# Development Rules

1 Architecture must be defined before coding.
2 Design must be reviewed before implementation.
3 Testing must iterate with implementation.
4 Documentation must capture reasoning.
5 Audit ensures production readiness.
6 Architect produces final report.
