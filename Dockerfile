FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY server ./server

RUN mkdir -p /app/captures

EXPOSE 4000

CMD ["node", "server/index.js"]
