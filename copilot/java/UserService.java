@Service
@Slf4j
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final SqlSessionTemplate sqlSessionTemplate;

    /**
     * Option A: Best for small/medium batches (100-1000)
     * One SQL statement, one network trip.
     */
    @Transactional
    public void processMediumBatch(List<UserEntity> users) {
        userMapper.insertBatch(users);
    }

    /**
     * Option B: Best for Massive Data (10,000+)
     * Uses JDBC Batching via SqlSession BATCH mode.
     */
    @Transactional
    public void processMassiveBatch(List<UserEntity> users) {
        // Switch to Batch Executor
        try (SqlSession session = sqlSessionTemplate.getSqlSessionFactory().openSession(ExecutorType.BATCH, false)) {
            UserMapper batchMapper = session.getMapper(UserMapper.class);
            
            int batchSize = 1000;
            for (int i = 0; i < users.size(); i++) {
                batchMapper.insert(users.get(i));
                if (i % batchSize == 0 && i > 0) {
                    session.flushStatements(); // Sends batch to DB
                }
            }
            session.flushStatements();
            session.commit();
        }
    }
}
