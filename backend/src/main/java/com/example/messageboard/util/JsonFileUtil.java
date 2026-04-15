package com.example.messageboard.util;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.locks.ReentrantReadWriteLock;

@Component
public class JsonFileUtil {
    
    @Value("${message.data.path}")
    private String dataPath;
    
    private final ReentrantReadWriteLock lock = new ReentrantReadWriteLock();
    
    @PostConstruct
    public void init() {
        try {
            Path path = Paths.get(dataPath);
            if (!Files.exists(path)) {
                Files.createDirectories(path.getParent());
                Files.createFile(path);
                writeArray(new ArrayList<>());
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to initialize data file", e);
        }
    }
    
    public <T> List<T> readArray(Class<T> clazz) {
        lock.readLock().lock();
        try {
            String content = readFile();
            if (content == null || content.trim().isEmpty()) {
                return new ArrayList<>();
            }
            JSONArray array = JSON.parseArray(content);
            List<T> list = new ArrayList<>();
            for (int i = 0; i < array.size(); i++) {
                list.add(array.getObject(i, clazz));
            }
            return list;
        } finally {
            lock.readLock().unlock();
        }
    }
    
    public <T> void writeArray(List<T> list) {
        lock.writeLock().lock();
        try {
            String json = JSON.toJSONString(list, true);
            writeFile(json);
        } finally {
            lock.writeLock().unlock();
        }
    }
    
    private String readFile() {
        try {
            byte[] bytes = Files.readAllBytes(Paths.get(dataPath));
            return new String(bytes, StandardCharsets.UTF_8);
        } catch (IOException e) {
            return null;
        }
    }
    
    private void writeFile(String content) {
        try (OutputStreamWriter writer = new OutputStreamWriter(
                new FileOutputStream(dataPath), StandardCharsets.UTF_8)) {
            writer.write(content);
        } catch (IOException e) {
            throw new RuntimeException("Failed to write file", e);
        }
    }
}
