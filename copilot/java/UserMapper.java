package com.performance.mapper;

import com.performance.model.UserEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface UserMapper {
    /**
     * 🚀 High Performance: XML-based Multi-row Insert
     * Best for batches of 100-1000 records.
     */
    int insertBatch(@Param("users") List<UserEntity> users);

    /**
     * Standard insert used by the Batch Executor
     */
    int insert(UserEntity user);
}
