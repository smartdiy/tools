package com.performance.aspect;

import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.stereotype.Component;

@Aspect
@Component
@Slf4j
public class PerformanceLoggingAspect {

    @Around("execution(* com.performance.service..*(..))")
    public Object logPerformance(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.nanoTime();
        // traceId is automatically handled by MDC + Micrometer Bridge
        try {
            return joinPoint.proceed();
        } finally {
            long duration = (System.nanoTime() - start) / 1_000_000;
            // Only log if slow (> 50ms) to reduce noise in high-throughput systems
            if (duration > 50) {
                log.warn("⚠️ Slow Method: {} | Duration: {}ms", joinPoint.getSignature().toShortString(), duration);
            } else {
                log.debug("✅ Method: {} | Duration: {}ms", joinPoint.getSignature().toShortString(), duration);
            }
        }
    }
}
