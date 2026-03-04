package com.common.utils.db;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public abstract class AbstractDumpService implements DatabaseDumpService {
    protected final String outputDir;

    protected AbstractDumpService(String outputDir) {
        this.outputDir = outputDir;
    }

    protected void saveItem(String subDirName, String name, String content) throws IOException {
        File subDir = new File(outputDir, subDirName);
        if (!subDir.exists() && !subDir.mkdirs()) {
            throw new IOException("Failed to create directory: " + subDir.getAbsolutePath());
        }
        String fileName = name.replaceAll("[^a-zA-Z0-9._-]", "_") + ".sql";
        File file = new File(subDir, fileName);
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {
            writer.write(content);
        }
    }
}
