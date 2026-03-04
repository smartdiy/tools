package com.common.utils.db;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class MsSqlDumpService extends AbstractDumpService {

    public MsSqlDumpService(String outputDir) {
        super(outputDir);
    }

    @Override
    public void performDump(Connection conn) throws SQLException, IOException {
        dumpTables(conn);
        dumpViews(conn);
        dumpRoutines(conn);
        dumpTriggers(conn);
    }

    private void dumpTables(Connection conn) throws SQLException, IOException {
        List<String> tables = new ArrayList<>();
        try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")) {
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    tables.add(rs.getString(1));
                }
            }
        }
        for (String table : tables) {
            StringBuilder ddl = new StringBuilder("--- Table: " + table + " ---\nCREATE TABLE " + table + " (\n");
            try (PreparedStatement pstmt = conn.prepareStatement(
                    "SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ?")) {
                pstmt.setString(1, table);
                try (ResultSet rs = pstmt.executeQuery()) {
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) ddl.append(",\n");
                        ddl.append("  ").append(rs.getString("COLUMN_NAME")).append(" ").append(rs.getString("DATA_TYPE"));
                        if (rs.getObject("CHARACTER_MAXIMUM_LENGTH") != null) {
                            ddl.append("(").append(rs.getInt("CHARACTER_MAXIMUM_LENGTH")).append(")");
                        }
                        if ("NO".equals(rs.getString("IS_NULLABLE"))) ddl.append(" NOT NULL");
                        first = false;
                    }
                }
            }
            ddl.append("\n);");
            saveItem("tables", table, ddl.toString());
        }
    }

    private void dumpViews(Connection conn) throws SQLException, IOException {
        try (PreparedStatement pstmt = conn.prepareStatement("SELECT TABLE_NAME, VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS")) {
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    saveItem("views", rs.getString("TABLE_NAME"), rs.getString("VIEW_DEFINITION"));
                }
            }
        }
    }

    private void dumpRoutines(Connection conn) throws SQLException, IOException {
        try (PreparedStatement pstmt = conn.prepareStatement(
                "SELECT ROUTINE_NAME, ROUTINE_TYPE, ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES")) {
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    String type = rs.getString("ROUTINE_TYPE");
                    String dir = "PROCEDURE".equalsIgnoreCase(type) ? "stored-procedures" : "functions";
                    saveItem(dir, rs.getString("ROUTINE_NAME"), rs.getString("ROUTINE_DEFINITION"));
                }
            }
        }
    }

    private void dumpTriggers(Connection conn) throws SQLException, IOException {
        try (PreparedStatement pstmt = conn.prepareStatement("SELECT name, OBJECT_DEFINITION(object_id) as definition FROM sys.triggers")) {
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    saveItem("triggers", rs.getString("name"), rs.getString("definition"));
                }
            }
        }
    }
}          
