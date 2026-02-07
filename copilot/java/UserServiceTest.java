@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private UserService userService;

    @Test
    void testProcessMediumBatch() {
        List<UserEntity> users = List.of(new UserEntity(), new UserEntity());
        userService.processMediumBatch(users);
        
        // Verify exactly one call was made with the whole list
        verify(userMapper, times(1)).insertBatch(anyList());
    }
}
