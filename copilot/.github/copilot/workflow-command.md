# Copilot Workflow Commands

This file defines reusable **AI workflow commands** for daily development.

These commands orchestrate the following agents:

* Architect
* Implementor
* Reviewer
* Tester
* Documentor
* Auditor

The commands guide Copilot through the **standard engineering lifecycle**.

---

# Command: /start-task

Purpose:
Start a new development task.

Prompt format:

```
/start-task
Task:
<describe feature or bug>

Context:
<files, modules, services>

Constraints:
<performance, backward compatibility, security>
```

Execution:

1 Architect analyzes the task
2 Architect defines system architecture
3 Architect identifies affected modules
4 Architect outputs architecture report

Expected output:

* architecture summary
* affected modules
* API changes
* design constraints
* risks

---

# Command: /design-implementation

Purpose:
Design implementation based on architecture.

Process:

Implementor reads architecture output and produces design.

Expected output:

* class structure
* interfaces
* service layer flow
* data flow
* dependency changes

Rule:

No production code allowed.

---

# Command: /review-design

Purpose:

Review implementation design.

Reviewer responsibilities:

* validate architecture alignment
* detect design flaws
* propose improvements

Output:

* review comments
* suggested improvements
* risk analysis

---

# Command: /design-iteration

Purpose:

Run design discussion between implementor and reviewer.

Process:

1 implementor evaluates reviewer feedback
2 implementor responds
3 reviewer reassesses

Rules:

* minimum 3 iterations
* stop early if agreement reached

Goal:

Design consensus.

---

# Command: /implement-solution

Purpose:

Implement the finalized design.

Implementor responsibilities:

* write production code
* follow project standards
* maintain backward compatibility

Deliverables:

* source code
* ready for testing

---

# Command: /test-cycle

Purpose:

Generate and validate tests.

Tester generates:

* unit tests
* integration tests
* performance tests (if applicable)

Tester reviews implementation and provides feedback.

Implementor must respond.

Rules:

* minimum 3 iterations
* continue until design expectations met

---

# Command: /document-changes

Purpose:

Generate project documentation.

Documentor responsibilities:

Document:

* architecture decisions
* design decisions
* implementation changes
* API changes
* migration notes

Documentation must include reasoning.

---

# Command: /audit-project

Purpose:

Perform final audit.

Auditor verifies:

* architecture compliance
* security risks
* performance risks
* coding standards
* testing completeness

Output:

Audit report.

---

# Command: /final-report

Purpose:

Produce final architecture report.

Architect summarizes:

* original task
* architecture decisions
* design process
* implementation results
* testing results
* audit findings

Output:

Final progress report.

---

# Recommended Workflow

```
/start-task
      ↓
/design-implementation
      ↓
/review-design
      ↓
/design-iteration
      ↓
/implement-solution
      ↓
/test-cycle
      ↓
/document-changes
      ↓
/audit-project
      ↓
/final-report
```

---

# Example Usage

Example development session:

```
/start-task fix deadlock in order processing service
```

```
/design-implementation
```

```
/review-design
```

```
/design-iteration
```

```
/implement-solution
```

```
/test-cycle
```

```
/document-changes
```

```
/audit-project
```

```
/final-report
```

---

# Key Rules

1 Architecture must be defined before coding.
2 Implementation must follow reviewed design.
3 Testing must iterate with implementation.
4 Documentation must capture reasoning.
5 Audit ensures production readiness.

---

# Expected Outcome

Using these commands ensures:

* structured AI collaboration
* safer refactoring
* high test coverage
* traceable engineering decisions
* enterprise-grade development workflow
