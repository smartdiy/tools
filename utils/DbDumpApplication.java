package com.common.utils.db;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
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

            DatabaseDumpService dumpService = new DatabaseDumpService(props);
            dumpService.performDump();

            logger.info("Database dump completed successfully.");
        } catch (Exception e) {
            logger.error("Failed to complete database dump", e);
            System.exit(1);
        }
    }
}
