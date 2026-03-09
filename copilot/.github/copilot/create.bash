#!/usr/bin/env bash
set -e

echo "Creating Advanced Copilot AI Team structure..."

BASE=".github"
AGENTS="$BASE/agents"
SKILLS="$BASE/skills"
PROMPTS="$BASE/prompts"

mkdir -p "$AGENTS"
mkdir -p "$SKILLS"
mkdir -p "$PROMPTS"

########################################
# GLOBAL COPILOT INSTRUCTIONS
########################################

cat <<'EOF' > "$BASE/copilot-instructions.md"
Project Stack

Java versions:
- 17
- 21
- 25

Framework:
- Spring Boot 2 / 3 / 4

Architecture:
- Clean Architecture
- Constructor injection only
- No field injection
- SOLID principles

Testing:
- JUnit5 / Mockito / Testcontainers

Observability:
- Micrometer / OpenTelemetry / Jaeger

Messaging:
- Kafka / Solace / RabbitMQ

Deployment:
- Docker / Kubernetes
EOF

########################################
# FUNCTION TO CREATE AGENT
########################################

create_agent() {
NAME=$1
DESC=$2
mkdir -p "$AGENTS/$NAME"
cat <<EOF > "$AGENTS/$NAME/AGENT.md"
---
name: $NAME
description: $DESC
---
Role: $NAME
Responsibilities:
- Analyze tasks
- Collaborate with other agents
- Follow engineering workflow
- Maintain architecture alignment
Output must be structured and clear.
EOF
}

########################################
# CREATE SPECIALIZED AGENTS
########################################

create_agent "architect" "System architect responsible for architecture decisions"
create_agent "implementor" "Implementation engineer"
create_agent "reviewer" "Design and code reviewer"
create_agent "tester" "Automated testing agent"
create_agent "documentor" "Documentation and decision recorder"
create_agent "auditor" "Final audit and compliance agent"
create_agent "performance-engineer" "Analyzes high-throughput and performance"
create_agent "concurrency-engineer" "Deadlock and multithreading specialist"
create_agent "db-optimizer" "Database tuning expert"
create_agent "messaging-architect" "Kafka / Solace messaging expert"
create_agent "security-auditor" "Security and auth specialist"
create_agent "observability-engineer" "Monitoring, tracing, metrics"
create_agent "microservice-designer" "Microservices architecture specialist"
create_agent "rest-api-designer" "REST API best practices"
create_agent "cache-optimizer" "Caching strategies specialist"
create_agent "docker-k8s-engineer" "Containerization and deployment expert"
create_agent "legacy-migration-engineer" "Spring Boot upgrade & legacy migration"
create_agent "test-generator" "Automated test generator"
create_agent "integration-tester" "Integration test expert"
create_agent "performance-tester" "Performance test expert"
create_agent "compliance-auditor" "Enterprise compliance reviewer"
create_agent "trace-analyzer" "Distributed tracing analysis"
create_agent "logging-engineer" "Logging standardization and analysis"
create_agent "config-manager" "Configuration and environment management"
create_agent "refactor-engineer" "Code refactoring expert"
create_agent "task-planner" "Daily task orchestration agent"
create_agent "devops-engineer" "CI/CD automation and deployment"
create_agent "api-gateway-designer" "API gateway & routing specialist"
create_agent "cloud-security-engineer" "Cloud security & policy enforcement"
create_agent "observability-consultant" "Advanced observability design"
create_agent "release-manager" "Final release validation and readiness"

########################################
# CREATE SKILLS (example per agent)
########################################

create_skill(){
NAME=$1
DESC=$2
mkdir -p "$SKILLS/$NAME"
cat <<EOF > "$SKILLS/$NAME/SKILL.md"
---
name: $NAME
description: $DESC
---
EOF
}

# Example skills
create_skill "spring-performance-analysis" "Analyze thread pools, blocking calls, DB latency"
create_skill "spring-deadlock-debugging" "Detect and resolve multithreading deadlocks"
create_skill "spring-db-query-tuning" "Analyze slow queries and optimize indexes"
create_skill "spring-kafka-architecture" "Design Kafka topics, consumers, and partitioning"
create_skill "spring-solace-messaging" "Design Solace queues with guaranteed delivery"
create_skill "spring-test-generation" "Auto-generate unit and integration tests"
create_skill "spring-observability" "Setup Micrometer, OpenTelemetry, Jaeger metrics and traces"
create_skill "spring-security-audit" "Check JWT, OAuth2, CSRF, CORS and endpoints"
create_skill "spring-migration-upgrade" "Upgrade Spring Boot versions safely"
create_skill "spring-cache-optimization" "Design Redis/Caffeine caching strategies"
create_skill "spring-rest-api-design" "Define REST API standards and pagination"

########################################
# CREATE AUTO-DEV COMMAND
########################################

cat <<'EOF' > "$PROMPTS/auto-dev.prompt.md"
# /auto-dev

Run the **full AI development workflow** automatically.

Agents included:
architect, implementor, reviewer, tester, documentor, auditor, performance-engineer, concurrency-engineer, db-optimizer, messaging-architect, security-auditor, observability-engineer, microservice-designer, rest-api-designer, cache-optimizer, docker-k8s-engineer, legacy-migration-engineer, test-generator, integration-tester, performance-tester, compliance-auditor, trace-analyzer, logging-engineer, config-manager, refactor-engineer, task-planner, devops-engineer, api-gateway-designer, cloud-security-engineer, observability-consultant, release-manager

---

# Input
User provides task:

/auto-dev
Task: <describe today's work>

---

# Workflow

1. Architect analyzes and defines architecture
2. Implementor designs solution based on architecture
3. Reviewer iterates design review (min 3 loops)
4. Implementor implements solution
5. Tester iterates testing (unit, integration, performance; min 3 loops)
6. Documentor records architecture, design, and implementation decisions
7. Auditor performs audit and compliance check
8. Architect produces final progress report

Output sections labeled clearly:

Phase 1 — Architect Analysis
Phase 2 — Implementation Design
Phase 3 — Design Review Iterations
Phase 4 — Implementation
Phase 5 — Testing Iterations
Phase 6 — Documentation
Phase 7 — Audit Report
Phase 8 — Final Architecture Report
EOF

echo ""
echo "------------------------------------"
echo "Advanced Copilot AI Team setup complete!"
echo "------------------------------------"
echo ""
echo "Use in Copilot Chat:"
echo "/auto-dev"
echo "Task: <describe today's work>"
