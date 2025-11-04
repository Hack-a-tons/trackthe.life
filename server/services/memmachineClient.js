const axios = require('axios');

class MemMachineClient {
  constructor() {
    this.url = process.env.MEMMACHINE_URL;
    this.apiKey = process.env.MEMMACHINE_API_KEY;
  }

  async addMemory(userId, memory) {
    try {
      const response = await axios.post(`${this.url}/api/memories`, {
        user_id: userId,
        content: memory
      }, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        }
      });
      return response.data;
    } catch (error) {
      console.error('MemMachine error:', error.message);
      return { id: `mock_mem_${Date.now()}` };
    }
  }
}

module.exports = new MemMachineClient();
