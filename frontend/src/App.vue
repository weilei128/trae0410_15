<template>
  <div id="app">
    <header class="header">
      <h1>在线留言反馈系统</h1>
      <div class="admin-toggle">
        <label>
          <input type="checkbox" v-model="isAdminView" @change="toggleAdminView" />
          管理员视图
        </label>
      </div>
    </header>
    
    <main class="main">
      <MessageForm @submit="handleSubmit" />
      <MessageList 
        :messages="messages" 
        :loading="loading"
        :is-admin="isAdminView"
        @delete="handleDelete"
        @page-change="handlePageChange"
      />
    </main>
  </div>
</template>

<script>
import MessageForm from './components/MessageForm.vue'
import MessageList from './components/MessageList.vue'
import api from './utils/api'

export default {
  name: 'App',
  components: {
    MessageForm,
    MessageList
  },
  data() {
    return {
      messages: [],
      loading: false,
      isAdminView: false,
      currentPage: 1,
      pageSize: 10
    }
  },
  mounted() {
    this.fetchMessages()
  },
  methods: {
    async fetchMessages() {
      this.loading = true
      try {
        const response = await api.get('/messages', {
          params: {
            page: this.currentPage,
            size: this.pageSize,
            isAdmin: this.isAdminView || undefined
          }
        })
        if (response.code === 200) {
          this.messages = response.data.records || []
        }
      } catch (error) {
        console.error('获取留言失败:', error)
      } finally {
        this.loading = false
      }
    },
    async handleSubmit(formData) {
      try {
        const data = {
          ...formData,
          isAdmin: this.isAdminView
        }
        const response = await api.post('/messages', data)
        if (response.code === 200) {
          alert('留言提交成功！')
          this.fetchMessages()
        } else {
          alert('提交失败: ' + response.message)
        }
      } catch (error) {
        alert('提交失败，请稍后重试')
      }
    },
    async handleDelete(id) {
      if (!confirm('确定要删除这条留言吗？')) {
        return
      }
      try {
        const response = await api.delete(`/messages/${id}`)
        if (response.code === 200) {
          alert('删除成功')
          this.fetchMessages()
        } else {
          alert('删除失败: ' + response.message)
        }
      } catch (error) {
        alert('删除失败，请稍后重试')
      }
    },
    handlePageChange(page) {
      this.currentPage = page
      this.fetchMessages()
    },
    toggleAdminView() {
      this.currentPage = 1
      this.fetchMessages()
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
}

#app {
  max-width: 900px;
  margin: 0 auto;
  padding: 20px;
}

.header {
  text-align: center;
  color: white;
  margin-bottom: 30px;
}

.header h1 {
  font-size: 2.5rem;
  margin-bottom: 15px;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
}

.admin-toggle {
  background: rgba(255, 255, 255, 0.2);
  padding: 10px 20px;
  border-radius: 8px;
  display: inline-block;
}

.admin-toggle label {
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}

.admin-toggle input {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.main {
  display: flex;
  flex-direction: column;
  gap: 20px;
}
</style>
