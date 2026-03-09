#!/usr/bin/env bash
set -e

BASE=".github"
AGENTS="$BASE/agents"
SKILLS="$BASE/skills"
PROMPTS="$BASE/prompts"

mkdir -p "$AGENTS"
mkdir -p "$SKILLS"
mkdir -p "$PROMPTS"

echo "Generating Enterprise Copilot Java/Spring Framework..."

############################################
# GLOBAL COPILOT INSTRUCTIONS
############################################

cat > "$BASE/copilot-instructions.md" << 'EOF'
# Copilot Instructions

This repository contains enterprise Java backend systems.

Supported Java versions:

- Java 17
- Java 21
- Java 25

Supported Spring Boot versions:

- Spring Boot 2.x
- Spring Boot 3.x
- Spring Boot 4.x

Architecture rules:

- Clean Architecture
- Domain Driven Design
- Layered Architecture

Coding standards:

- Constructor injection only
- No field injection
- Prefer immutability
- Prefer records when possible
- Avoid cyclic dependencies

Testing stack:

- JUnit 5
- Mockito
- Testcontainers

Observability:

- Micrometer
- OpenTelemetry
- Prometheus
- Jaeger

Messaging:

- Kafka
- Solace
- RabbitMQ

Deployment:

- Docker
- Kubernetes
EOF

############################################
# AGENTS
############################################

create_agent() {

NAME=$1
DESC=$2
FILE="$AGENTS/$NAME"

mkdir -p "$FILE"

cat > "$FILE/AGENT.md" << EOF
---
name: $NAME
description: $DESC
---

# Agent: $NAME

Responsibilities:

1 Analyze repository context
2 Identify architectural patterns
3 Recommend improvements
4 Generate safe refactors
5 Maintain business logic compatibility

Preferred stack:

Java 17 / 21 / 25  
Spring Boot 2 / 3 / 4  
Docker  
Kubernetes
EOF

}

create_agent "spring-architect" "Enterprise Spring Boot architecture advisor"
create_agent "performance-engineer" "High throughput performance tuning specialist"
create_agent "security-auditor" "Spring security vulnerability auditor"
create_agent "database-optimizer" "SQL and database performance expert"
create_agent "messaging-architect" "Kafka Solace event architecture designer"
create_agent "observability-engineer" "Monitoring logging tracing expert"
create_agent "test-engineer" "Enterprise automated testing expert"
create_agent "cloud-deployment-engineer" "Docker Kubernetes deployment expert"

############################################
# SKILLS
############################################

create_skill(){

NAME=$1
DESC=$2
BODY=$3

mkdir -p "$SKILLS/$NAME"

cat > "$SKILLS/$NAME/SKILL.md" << EOF
---
name: $NAME
description: $DESC
---

$BODY
EOF

}

create_skill "spring-boot-migration" "Upgrade Spring Boot versions" "
# Spring Boot Migration

Supported upgrades:

- Spring Boot 2 -> 3
- Spring Boot 3 -> 4

Checklist:

1 Update dependencies
2 Jakarta namespace migration
3 Spring Security config updates
4 Hibernate compatibility
5 Configuration changes

Output:

migration report
code patches
risk analysis
"

create_skill "spring-performance-analysis" "Analyze performance bottlenecks" "
# Performance Analysis

Investigate:

- thread pools
- blocking calls
- DB latency
- GC pauses

Provide:

performance report
optimization suggestions
benchmark ideas
"

create_skill "spring-deadlock-analysis" "Detect multithreading deadlocks" "
# Deadlock Analysis

Check:

- synchronized blocks
- database locks
- thread contention
- transaction conflicts

Provide:

deadlock diagnosis
recommended fix
"

create_skill "spring-thread-optimization" "Optimize concurrency" "
# Concurrency Optimization

Analyze:

- executor pools
- reactive vs blocking
- async patterns
- queue backpressure
"

create_skill "spring-security-audit" "Security audit for Spring Boot" "
# Security Audit

Check:

- JWT validation
- OAuth2 configuration
- CSRF protection
- CORS rules
- actuator exposure
"

create_skill "spring-jpa-optimization" "Optimize JPA performance" "
# JPA Optimization

Detect:

- N+1 queries
- inefficient joins
- lazy loading issues
"

create_skill "spring-query-tuning" "SQL tuning skill" "
# Query Tuning

Focus:

- indexes
- execution plans
- slow queries
"

create_skill "spring-kafka-design" "Kafka event architecture" "
# Kafka Architecture

Design:

- partition strategy
- consumer groups
- retry topics
"

create_skill "spring-solace-messaging" "Solace messaging architecture" "
# Solace Messaging

Design:

- queue vs topic
- guaranteed delivery
- retry queue
"

create_skill "spring-observability" "Observability setup" "
# Observability

Implement:

- Micrometer metrics
- OpenTelemetry traces
- distributed tracing
"

create_skill "spring-test-generation" "Generate tests" "
# Test Generation

Create:

- unit tests
- integration tests
- testcontainers setup
"

create_skill "spring-microservice-design" "Design microservices" "
# Microservice Architecture

Focus:

- bounded contexts
- API contracts
- service communication
"

create_skill "spring-rest-api-design" "REST API best practices" "
# REST API Design

Follow:

- REST standards
- pagination
- idempotency
"

create_skill "spring-cache-optimization" "Caching strategies" "
# Cache Optimization

Implement:

- Redis
- Caffeine
- cache eviction
"

create_skill "spring-dockerization" "Docker containerization" "
# Docker

Generate:

- Dockerfile
- container best practices
"

create_skill "spring-kubernetes-deploy" "Kubernetes deployment" "
# Kubernetes

Generate:

- deployment.yaml
- service.yaml
- scaling configuration
"

############################################
# PROMPTS
############################################

create_prompt(){

FILE=$1
BODY=$2

cat > "$PROMPTS/$FILE.prompt.md" << EOF
$BODY
EOF

}

create_prompt "refactor" "
# Refactor Spring Application

1 Analyze project modules
2 Detect cyclic dependencies
3 Improve architecture
4 Maintain existing behavior
"

create_prompt "performance-investigation" "
# Performance Investigation

Steps:

1 analyze thread pools
2 analyze DB queries
3 detect blocking code
"

create_prompt "security-audit" "
# Security Audit

Analyze:

authentication
authorization
token validation
"

create_prompt "migration-plan" "
# Spring Boot Migration

Goal:

upgrade safely

Steps:

analyze dependencies
detect breaking changes
"

create_prompt "microservice-review" "
# Microservice Architecture Review

Evaluate:

service boundaries
communication patterns
"

echo "--------------------------------------"
echo "Copilot Enterprise Spring System Ready"
echo "--------------------------------------"
