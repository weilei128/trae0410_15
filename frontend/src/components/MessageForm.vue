<template>
  <div class="message-form">
    <h2>发表留言</h2>
    <form @submit.prevent="submitForm">
      <div class="form-group">
        <label for="username">用户名 *</label>
        <input 
          type="text" 
          id="username" 
          v-model="form.username" 
          placeholder="请输入您的用户名"
          required
        />
      </div>
      
      <div class="form-group">
        <label for="email">邮箱</label>
        <input 
          type="email" 
          id="email" 
          v-model="form.email" 
          placeholder="请输入您的邮箱（选填）"
        />
      </div>
      
      <div class="form-group">
        <label for="content">留言内容 *</label>
        <textarea 
          id="content" 
          v-model="form.content" 
          placeholder="请输入留言内容..."
          rows="4"
          required
        ></textarea>
      </div>
      
      <button type="submit" class="submit-btn">提交留言</button>
    </form>
  </div>
</template>

<script>
export default {
  name: 'MessageForm',
  data() {
    return {
      form: {
        username: '',
        email: '',
        content: ''
      }
    }
  },
  methods: {
    submitForm() {
      if (!this.form.username.trim()) {
        alert('请输入用户名')
        return
      }
      if (!this.form.content.trim()) {
        alert('请输入留言内容')
        return
      }
      
      this.$emit('submit', {
        username: this.form.username.trim(),
        email: this.form.email.trim(),
        content: this.form.content.trim()
      })
      
      this.form.content = ''
    }
  }
}
</script>

<style scoped>
.message-form {
  background: white;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.message-form h2 {
  color: #333;
  margin-bottom: 20px;
  font-size: 1.5rem;
}

.form-group {
  margin-bottom: 18px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: #555;
  font-weight: 500;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 12px 15px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 14px;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.form-group textarea {
  resize: vertical;
  min-height: 100px;
}

.submit-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.submit-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.submit-btn:active {
  transform: translateY(0);
}
</style>
