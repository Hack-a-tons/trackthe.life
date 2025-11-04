const axios = require('axios');

class CometClient {
  constructor() {
    this.apiKey = process.env.COMET_API_KEY;
    this.workspace = process.env.COMET_WORKSPACE;
  }

  async logTrace(operation, data) {
    try {
      console.log(`[Comet] ${operation}:`, data);
      // Actual Comet/Opik integration would go here
      return { logged: true };
    } catch (error) {
      console.error('Comet error:', error.message);
      return { logged: false };
    }
  }
}

module.exports = new CometClient();
