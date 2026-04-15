package com.example.messageboard.service;

import com.example.messageboard.common.PageResult;
import com.example.messageboard.entity.Message;
import com.example.messageboard.util.JsonFileUtil;
import com.example.messageboard.util.SensitiveWordUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class MessageService {
    
    @Autowired
    private JsonFileUtil jsonFileUtil;
    
    @Autowired
    private SensitiveWordUtil sensitiveWordUtil;
    
    public Message addMessage(Message message) {
        List<Message> messages = jsonFileUtil.readArray(Message.class);
        
        Long maxId = messages.stream()
                .mapToLong(m -> m.getId() != null ? m.getId() : 0)
                .max()
                .orElse(0L);
        
        message.setId(maxId + 1);
        message.setCreateTime(LocalDateTime.now());
        message.setIsDeleted(false);
        
        if (message.getIsAdmin() == null) {
            message.setIsAdmin(false);
        }
        
        String filteredContent = sensitiveWordUtil.filterSensitiveWord(message.getContent());
        message.setContent(filteredContent);
        
        messages.add(message);
        jsonFileUtil.writeArray(messages);
        
        return message;
    }
    
    public PageResult<Message> getMessageList(Integer page, Integer size, Boolean isAdmin) {
        List<Message> allMessages = jsonFileUtil.readArray(Message.class);
        
        List<Message> filteredMessages = allMessages.stream()
                .filter(m -> !Boolean.TRUE.equals(m.getIsDeleted()))
                .filter(m -> isAdmin == null || isAdmin.equals(m.getIsAdmin()))
                .sorted(Comparator.comparing(Message::getCreateTime).reversed())
                .collect(Collectors.toList());
        
        Long total = (long) filteredMessages.size();
        
        int start = (page - 1) * size;
        int end = Math.min(start + size, filteredMessages.size());
        
        List<Message> pageMessages = start < filteredMessages.size() 
                ? filteredMessages.subList(start, end) 
                : List.of();
        
        return new PageResult<>(pageMessages, total, page, size);
    }
    
    public boolean deleteMessage(Long id) {
        List<Message> messages = jsonFileUtil.readArray(Message.class);
        
        for (Message message : messages) {
            if (message.getId().equals(id)) {
                message.setIsDeleted(true);
                jsonFileUtil.writeArray(messages);
                return true;
            }
        }
        return false;
    }
    
    public Message getMessageById(Long id) {
        List<Message> messages = jsonFileUtil.readArray(Message.class);
        return messages.stream()
                .filter(m -> m.getId().equals(id) && !Boolean.TRUE.equals(m.getIsDeleted()))
                .findFirst()
                .orElse(null);
    }
    
    public List<Message> getAllMessages() {
        List<Message> messages = jsonFileUtil.readArray(Message.class);
        return messages.stream()
                .filter(m -> !Boolean.TRUE.equals(m.getIsDeleted()))
                .sorted(Comparator.comparing(Message::getCreateTime).reversed())
                .collect(Collectors.toList());
    }
}
