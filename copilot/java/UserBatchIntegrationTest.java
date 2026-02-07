@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
class UserBatchIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private UserService userService;

    @Autowired
    private UserMapper userMapper;

    @Test
    void verifyActualBatchPersistence() {
        List<UserEntity> users = IntStream.range(0, 500)
            .mapToObj(i -> UserEntity.builder()
                .username("user" + i)
                .email("user" + i + "@example.com")
                .build())
            .toList();

        userService.processMediumBatch(users);

        // Verification
        Integer count = sqlSessionTemplate.selectOne("SELECT count(*) FROM users");
        assertThat(count).isEqualTo(500);
    }
}
