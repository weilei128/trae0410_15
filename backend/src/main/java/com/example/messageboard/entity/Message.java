package com.example.messageboard.entity;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class Message {
    private Long id;
    private String username;
    private String content;
    private String email;
    private LocalDateTime createTime;
    private Boolean isAdmin;
    private Boolean isDeleted;
    
    public Message() {
        this.createTime = LocalDateTime.now();
        this.isAdmin = false;
        this.isDeleted = false;
    }
}
