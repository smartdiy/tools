#!/usr/bin/env bash
set -e

echo "Generating enterprise GitHub Copilot Java/Spring framework..."

BASE=".github"
SKILLS="$BASE/skills"
PROMPTS="$BASE/prompts"
AGENTS="$BASE/agents"

mkdir -p $SKILLS
mkdir -p $PROMPTS
mkdir -p $AGENTS

############################################################
# GLOBAL INSTRUCTIONS
############################################################

cat > $BASE/copilot-instructions.md << 'EOF'
# Global Copilot Instructions

Project type: Enterprise Java backend.

Supported Java versions:

- Java 17
- Java 21
- Java 25

Supported Spring Boot versions:

- Spring Boot 2.x
- Spring Boot 3.x
- Spring Boot 4.x

Architecture rules:

- Clean architecture
- Layered architecture
- Domain-driven design where applicable

Dependency injection:

- Constructor injection only
- No field injection

Testing:

- JUnit 5
- Mockito
- Testcontainers

Code standards:

- Avoid cyclic dependencies
- Prefer immutability
- Use records when possible
- Follow SOLID principles
EOF

############################################################
# AGENT 1
############################################################

mkdir -p $AGENTS/spring-architect

cat > $AGENTS/spring-architect/AGENT.md << 'EOF'
---
name: spring-architect
description: Senior architect for Spring Boot enterprise systems
---

# Spring Architect Agent

Expertise:

- Microservices architecture
- Spring Boot internals
- Domain driven design
- Event-driven architecture

Responsibilities:

1 Analyze repository structure
2 Detect architectural violations
3 Recommend refactor strategies
4 Ensure modular boundaries

Preferred stack:

Spring Boot
Kafka
Solace
PostgreSQL
Docker
Kubernetes
EOF

############################################################
# AGENT 2
############################################################

mkdir -p $AGENTS/performance-engineer

cat > $AGENTS/performance-engineer/AGENT.md << 'EOF'
---
name: performance-engineer
description: Performance optimization agent for Java microservices
---

Focus areas:

Thread pools
Deadlocks
Database bottlenecks
Memory leaks
High throughput systems

Workflow:

1 Identify hotspots
2 Analyze blocking operations
3 Inspect database access
4 Recommend concurrency improvements
EOF

############################################################
# SKILL 1
############################################################

mkdir -p $SKILLS/spring-boot-migration

cat > $SKILLS/spring-boot-migration/SKILL.md << 'EOF'
---
name: spring-boot-migration
description: Upgrade Spring Boot projects between major versions
---

# Spring Boot Migration Skill

Supported upgrades:

2.x -> 3.x
3.x -> 4.x

Checklist:

1 Jakarta namespace migration
2 Dependency upgrades
3 Spring Security changes
4 Hibernate updates
5 Configuration property updates

Output:

- migration plan
- code modifications
- compatibility risks
EOF

############################################################
# SKILL 2
############################################################

mkdir -p $SKILLS/spring-performance

cat > $SKILLS/spring-performance/SKILL.md << 'EOF'
---
name: spring-performance
description: Performance tuning for Spring Boot services
---

Analysis:

Thread blocking
Database latency
Connection pools
GC pressure

Tools:

JFR
Micrometer
OpenTelemetry

Deliverables:

performance report
optimization patches
benchmark suggestions
EOF

############################################################
# SKILL 3
############################################################

mkdir -p $SKILLS/spring-security-audit

cat > $SKILLS/spring-security-audit/SKILL.md << 'EOF'
---
name: spring-security-audit
description: Security review for Spring Boot applications
---

Audit items:

JWT validation
OAuth2 configuration
CORS policies
CSRF protection
Actuator exposure

Output:

security issues
severity classification
recommended fixes
EOF

############################################################
# SKILL 4
############################################################

mkdir -p $SKILLS/spring-messaging

cat > $SKILLS/spring-messaging/SKILL.md << 'EOF'
---
name: spring-messaging
description: Messaging architecture using Kafka or Solace
---

Focus:

Event driven design
Message durability
Retry patterns
Dead letter queues

Frameworks:

Spring Cloud Stream
Kafka
Solace
RabbitMQ
EOF

############################################################
# SKILL 5
############################################################

mkdir -p $SKILLS/spring-testing

cat > $SKILLS/spring-testing/SKILL.md << 'EOF'
---
name: spring-testing
description: Generate enterprise test coverage
---

Test strategy:

Unit tests
Integration tests
Contract tests

Frameworks:

JUnit 5
Mockito
Testcontainers

Coverage target:

80% minimum
EOF

############################################################
# PROMPT 1
############################################################

cat > $PROMPTS/refactor.prompt.md << 'EOF'
# Spring Refactor Workflow

Steps:

1 analyze module dependencies
2 detect cyclic references
3 propose refactoring plan
4 generate updated classes
5 maintain backward compatibility
EOF

############################################################
# PROMPT 2
############################################################

cat > $PROMPTS/performance.prompt.md << 'EOF'
# Spring Performance Investigation

Analyze:

thread pools
database queries
blocking calls
cache opportunities

Return:

performance hotspots
optimization plan
benchmark strategy
EOF

############################################################
# PROMPT 3
############################################################

cat > $PROMPTS/migration.prompt.md << 'EOF'
# Spring Boot Migration

Goal:

upgrade application safely

Process:

1 analyze dependencies
2 identify breaking changes
3 update configuration
4 adjust code
5 generate migration report
EOF

############################################################

echo "------------------------------------"
echo "Copilot enterprise Spring framework created"
echo "------------------------------------"
