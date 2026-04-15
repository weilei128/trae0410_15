<template>
  <div class="message-list">
    <h2>留言列表</h2>
    
    <div v-if="loading" class="loading">
      加载中...
    </div>
    
    <div v-else-if="messages.length === 0" class="empty">
      暂无留言
    </div>
    
    <div v-else class="messages">
      <div 
        v-for="message in messages" 
        :key="message.id" 
        class="message-card"
        :class="{ 'admin-message': message.isAdmin }"
      >
        <div class="message-header">
          <div class="user-info">
            <span class="username">{{ message.username }}</span>
            <span v-if="message.isAdmin" class="admin-badge">管理员</span>
          </div>
          <span class="time">{{ formatTime(message.createTime) }}</span>
        </div>
        
        <div class="message-content">
          {{ message.content }}
        </div>
        
        <div v-if="message.email" class="message-email">
          邮箱: {{ message.email }}
        </div>
        
        <div v-if="isAdmin" class="message-actions">
          <button class="delete-btn" @click="$emit('delete', message.id)">
            删除
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'MessageList',
  props: {
    messages: {
      type: Array,
      default: () => []
    },
    loading: {
      type: Boolean,
      default: false
    },
    isAdmin: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    formatTime(time) {
      if (!time) return ''
      const date = new Date(time)
      return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
  }
}
</script>

<style scoped>
.message-list {
  background: white;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.message-list h2 {
  color: #333;
  margin-bottom: 20px;
  font-size: 1.5rem;
}

.loading,
.empty {
  text-align: center;
  padding: 40px;
  color: #999;
  font-size: 16px;
}

.messages {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.message-card {
  background: #f8f9fa;
  border-radius: 10px;
  padding: 18px;
  border-left: 4px solid #667eea;
  transition: transform 0.2s, box-shadow 0.2s;
}

.message-card:hover {
  transform: translateX(5px);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.message-card.admin-message {
  border-left-color: #ff6b6b;
  background: #fff5f5;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.username {
  font-weight: 600;
  color: #333;
  font-size: 15px;
}

.admin-badge {
  background: #ff6b6b;
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.time {
  color: #999;
  font-size: 13px;
}

.message-content {
  color: #444;
  line-height: 1.6;
  margin-bottom: 10px;
  word-break: break-word;
}

.message-email {
  color: #888;
  font-size: 13px;
  margin-bottom: 10px;
}

.message-actions {
  display: flex;
  justify-content: flex-end;
}

.delete-btn {
  padding: 6px 16px;
  background: #ff6b6b;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 13px;
  transition: background 0.2s;
}

.delete-btn:hover {
  background: #ee5a5a;
}
</style>
