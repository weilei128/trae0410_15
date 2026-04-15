package com.example.messageboard.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

@Component
public class SensitiveWordUtil {
    
    @Value("${message.sensitive.words}")
    private String sensitiveWordsConfig;
    
    private Set<String> sensitiveWords;
    private static final String REPLACE_CHAR = "*";
    
    @PostConstruct
    public void init() {
        sensitiveWords = new HashSet<>();
        if (sensitiveWordsConfig != null && !sensitiveWordsConfig.trim().isEmpty()) {
            String[] words = sensitiveWordsConfig.split(",");
            for (String word : words) {
                sensitiveWords.add(word.trim().toLowerCase());
            }
        }
    }
    
    public boolean containsSensitiveWord(String text) {
        if (text == null || text.trim().isEmpty()) {
            return false;
        }
        String lowerText = text.toLowerCase();
        for (String word : sensitiveWords) {
            if (lowerText.contains(word)) {
                return true;
            }
        }
        return false;
    }
    
    public String filterSensitiveWord(String text) {
        if (text == null || text.trim().isEmpty()) {
            return text;
        }
        String result = text;
        for (String word : sensitiveWords) {
            if (word.isEmpty()) continue;
            String lowerText = result.toLowerCase();
            int index = lowerText.indexOf(word.toLowerCase());
            while (index != -1) {
                String replacement = REPLACE_CHAR.repeat(word.length());
                result = result.substring(0, index) + replacement + result.substring(index + word.length());
                lowerText = result.toLowerCase();
                index = lowerText.indexOf(word.toLowerCase(), index + replacement.length());
            }
        }
        return result;
    }
    
    public Set<String> getSensitiveWords() {
        return new HashSet<>(sensitiveWords);
    }
}
