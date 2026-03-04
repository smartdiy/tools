package com.common.utils.db;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.util.Properties;

public class DbDumpApplication {

    private static final Logger logger = LoggerFactory.getLogger(DbDumpApplication.class);

    public static void main(String[] args) {
        String profile = (args.length > 0) ? args[0] : "dev";
        String fileName = "application-" + profile + ".properties";

        logger.info("Starting standalone database dump application with profile: {}", profile);

        Properties props = new Properties();
        try (InputStream input = DbDumpApplication.class.getClassLoader().getResourceAsStream(fileName)) {
            if (input == null) {
                logger.error("Could not find configuration file: {}", fileName);
                System.exit(1);
            }
            props.load(input);

            String outputDir = props.getProperty("dump.output-dir", "./output");
            File dir = new File(outputDir);
            if (!dir.exists() && !dir.mkdirs()) {
                logger.error("Failed to create output directory: {}", outputDir);
                System.exit(1);
            }

            try (Connection conn = DriverManager.getConnection(
                    props.getProperty("spring.datasource.url"),
                    props.getProperty("spring.datasource.username"),
                    props.getProperty("spring.datasource.password"))) {

                DatabaseMetaData metaData = conn.getMetaData();
                String dbName = metaData.getDatabaseProductName().toLowerCase();
                String catalog = conn.getCatalog();
                String schema = conn.getSchema();

                logger.info("Connected to {} (Catalog: {}, Schema: {})", dbName, catalog, schema);

                DatabaseDumpService dumpService;
                if (dbName.contains("postgresql")) {
                    dumpService = new PostgresDumpService(outputDir);
                } else if (dbName.contains("mysql") || dbName.contains("mariadb")) {
                    dumpService = new MySqlDumpService(outputDir);
                } else if (dbName.contains("microsoft sql server")) {
                    dumpService = new MsSqlDumpService(outputDir);
                } else {
                    logger.error("Database type {} not supported.", dbName);
                    System.exit(1);
                    return;
                }

                dumpService.performDump(conn);
                logger.info("Database dump completed successfully.");
            }
        } catch (Exception e) {
            logger.error("Failed to complete database dump", e);
            System.exit(1);
        }
    }
}                
