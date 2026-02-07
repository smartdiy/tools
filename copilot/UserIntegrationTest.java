package com.performance.tests;

import com.performance.mapper.UserMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Testcontainers
class UserIntegrationTest {

    // 🐳 Auto-wires DataSource to this container
    @Container
    @ServiceConnection 
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @Autowired
    private UserMapper userMapper;

    @Test
    void testBatchInsertThroughput() {
        // Prepare large dataset
        List<User> users = generateUsers(1000);
        
        long start = System.currentTimeMillis();
        userMapper.insertBatch(users); // Uses <foreach> XML
        long end = System.currentTimeMillis();

        assertThat(userMapper.count()).isEqualTo(1000);
        System.out.println("🚀 Batch Insert 1000 rows: " + (end - start) + "ms");
    }
}
