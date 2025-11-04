const axios = require('axios');

class GeoIPClient {
  async lookup(ip) {
    try {
      // Skip private/local IPs
      if (!ip || ip === '::1' || ip.startsWith('127.') || ip.startsWith('192.168.') || ip.startsWith('10.')) {
        return null;
      }

      const response = await axios.get(`http://ip-api.com/json/${ip}`, {
        timeout: 3000
      });

      if (response.data.status === 'success') {
        return {
          ip: response.data.query,
          country: response.data.country,
          countryCode: response.data.countryCode,
          region: response.data.region,
          regionName: response.data.regionName,
          city: response.data.city,
          zip: response.data.zip,
          lat: response.data.lat,
          lon: response.data.lon,
          timezone: response.data.timezone,
          isp: response.data.isp,
          org: response.data.org,
          as: response.data.as
        };
      }
      return null;
    } catch (error) {
      console.error('GeoIP lookup error:', error.message);
      return null;
    }
  }
}

module.exports = new GeoIPClient();
