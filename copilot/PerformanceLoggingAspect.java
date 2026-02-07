package com.performance.config;

import io.micrometer.tracing.Tracer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Aspect
@Component
@Slf4j
@RequiredArgsConstructor
public class PerformanceLoggingAspect {

    private final Tracer tracer; // Autowired from Micrometer Tracing

    @Around("execution(* com.performance.service..*(..)) || execution(* com.performance.mapper..*(..))")
    public Object trackTimeAndTrace(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        
        // Extract Trace ID from current context
        String traceId = Optional.ofNullable(tracer.currentSpan())
                .map(span -> span.context().traceId())
                .orElse("no-trace-id");

        try {
            return joinPoint.proceed();
        } finally {
            long executionTime = System.currentTimeMillis() - start;
            
            // Focus on performance: only warn if execution is slow
            if (executionTime > 200) {
                log.warn("[PERF-ALERT] TraceID: {} | Method: {} | Execution Time: {}ms", 
                    traceId, joinPoint.getSignature().toShortString(), executionTime);
            } else {
                log.debug("TraceID: {} | Method: {} | Execution Time: {}ms", 
                    traceId, joinPoint.getSignature().toShortString(), executionTime);
            }
        }
    }
}
