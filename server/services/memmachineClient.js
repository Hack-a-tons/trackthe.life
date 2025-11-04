const axios = require('axios');

class MemMachineClient {
  constructor() {
    this.url = process.env.MEMMACHINE_URL || 'http://localhost:7000';
  }

  async addMemory(userId, content, metadata = {}) {
    try {
      const response = await axios.post(`${this.url}/v1/memories`, {
        session: {
          group_id: 'trackthelife',
          agent_id: ['system'],
          user_id: [userId],
          session_id: `session_${Date.now()}`
        },
        producer: userId,
        produced_for: 'system',
        episode_content: content,
        episode_type: 'event',
        metadata
      }, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 5000
      });
      
      return { id: `mem_${Date.now()}`, success: true };
    } catch (error) {
      console.error('MemMachine error:', error.message);
      return { id: `mock_mem_${Date.now()}`, success: false };
    }
  }

  async searchMemories(userId, query, limit = 5) {
    try {
      const response = await axios.post(`${this.url}/v1/memories/search`, {
        session: {
          group_id: 'trackthelife',
          agent_id: ['system'],
          user_id: [userId],
          session_id: `session_${Date.now()}`
        },
        query,
        filter: {},
        limit
      }, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 5000
      });
      
      return response.data;
    } catch (error) {
      console.error('MemMachine search error:', error.message);
      return [];
    }
  }
}

module.exports = new MemMachineClient();
