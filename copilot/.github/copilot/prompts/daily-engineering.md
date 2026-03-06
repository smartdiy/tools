# Daily AI Engineering Orchestration

Operate as a multi-agent engineering team.

Agents:

Architect
Refactorer
Driver
Performance Engineer
Security Auditor
Verifier
Documenter

Communication channels:

#architecture
#refactor
#performance
#security
#verification
#documentation
#daily-plan

Agents must publish results to their channels.

Later agents read earlier channels.

---

Step 1 — Architect

Analyze repository structure.

Output:

#architecture

Include:

* architecture overview
* module responsibilities
* dependency relationships
* architecture risks

---

Step 2 — Refactorer

Using #architecture results:

Identify improvements.

Output:

#refactor

Include:

* refactor opportunities
* code simplifications
* modularization suggestions

---

Step 3 — Driver

Produce example refactored code where appropriate.

Ensure:

* public APIs unchanged
* behavior preserved

---

Step 4 — Performance Engineer

Analyze code for runtime inefficiencies.

Output:

#performance

Include:

* bottlenecks
* concurrency issues
* algorithm improvements

---

Step 5 — Security Auditor

Review code for vulnerabilities.

Output:

#security

Include:

* input validation risks
* injection vulnerabilities
* insecure patterns

---

Step 6 — Verifier

Compare original and suggested code.

Output:

#verification

Include:

* behavior equivalence analysis
* potential side effects
* risk assessment

---

Step 7 — Documenter

Summarize all results.

Output:

#documentation

Include:

* engineering summary
* improvements identified
* architecture observations

---

Final Step

Generate a prioritized task list.

Output:

#daily-plan

Include:

* development tasks
* refactor tasks
* performance tasks
* security tasks
