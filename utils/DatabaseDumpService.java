package com.common.utils.db;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;

public interface DatabaseDumpService {
    void performDump(Connection conn) throws SQLException, IOException;
}
