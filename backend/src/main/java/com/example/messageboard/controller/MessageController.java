package com.example.messageboard.controller;

import com.example.messageboard.common.PageResult;
import com.example.messageboard.common.Result;
import com.example.messageboard.entity.Message;
import com.example.messageboard.service.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/messages")
@CrossOrigin(origins = "*")
public class MessageController {
    
    @Autowired
    private MessageService messageService;
    
    @PostMapping
    public Result<Message> addMessage(@RequestBody Message message) {
        try {
            if (message.getContent() == null || message.getContent().trim().isEmpty()) {
                return Result.error(400, "留言内容不能为空");
            }
            if (message.getUsername() == null || message.getUsername().trim().isEmpty()) {
                return Result.error(400, "用户名不能为空");
            }
            
            Message savedMessage = messageService.addMessage(message);
            return Result.success(savedMessage);
        } catch (Exception e) {
            return Result.error("提交留言失败: " + e.getMessage());
        }
    }
    
    @GetMapping
    public Result<PageResult<Message>> getMessageList(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) Boolean isAdmin) {
        try {
            PageResult<Message> result = messageService.getMessageList(page, size, isAdmin);
            return Result.success(result);
        } catch (Exception e) {
            return Result.error("获取留言列表失败: " + e.getMessage());
        }
    }
    
    @GetMapping("/all")
    public Result<List<Message>> getAllMessages() {
        try {
            List<Message> messages = messageService.getAllMessages();
            return Result.success(messages);
        } catch (Exception e) {
            return Result.error("获取留言列表失败: " + e.getMessage());
        }
    }
    
    @GetMapping("/{id}")
    public Result<Message> getMessageById(@PathVariable Long id) {
        try {
            Message message = messageService.getMessageById(id);
            if (message == null) {
                return Result.error(404, "留言不存在");
            }
            return Result.success(message);
        } catch (Exception e) {
            return Result.error("获取留言失败: " + e.getMessage());
        }
    }
    
    @DeleteMapping("/{id}")
    public Result<Void> deleteMessage(@PathVariable Long id) {
        try {
            boolean success = messageService.deleteMessage(id);
            if (success) {
                return Result.success();
            } else {
                return Result.error(404, "留言不存在");
            }
        } catch (Exception e) {
            return Result.error("删除留言失败: " + e.getMessage());
        }
    }
}
