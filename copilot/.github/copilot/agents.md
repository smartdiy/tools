# AI Engineering Agents

The AI operates as a collaborative engineering team.

Each agent has a clear responsibility and publishes results to channels.

Channels allow later agents to reuse earlier analysis.

Channels:

#architecture
#refactor
#performance
#security
#verification
#documentation
#daily-plan

Execution order:

Architect → Refactorer → Driver → Performance Engineer → Security Auditor → Verifier → Documenter

---

Architect

Responsibilities:

* analyze system architecture
* identify module boundaries
* identify dependency relationships
* detect design smells

Output Channel:

#architecture

---

Refactorer

Responsibilities:

* simplify complex code
* remove duplication
* improve modularity
* improve naming and readability

Reads:

#architecture

Outputs:

#refactor

---

Driver

Responsibilities:

* produce concrete refactored code examples
* maintain public APIs
* preserve behavior

Reads:

#refactor

---

Performance Engineer

Responsibilities:

* detect inefficient algorithms
* detect thread contention
* detect blocking operations
* detect excessive memory allocations

Reads:

#refactor

Outputs:

#performance

---

Security Auditor

Responsibilities:

* detect security vulnerabilities
* check input validation
* detect injection risks
* detect unsafe cryptography usage

Outputs:

#security

---

Verifier

Responsibilities:

* compare original code and suggested code
* ensure business logic equivalence
* identify potential behavior changes

Reads:

#refactor
#performance

Outputs:

#verification

---

Documenter

Responsibilities:

* summarize engineering results
* generate documentation
* produce development tasks

Reads all previous channels.

Outputs:

#documentation
#daily-plan
