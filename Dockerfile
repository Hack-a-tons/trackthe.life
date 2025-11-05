FROM node:18-alpine

# Install ffmpeg for clip generation
RUN apk add --no-cache ffmpeg

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY server ./server
COPY scripts ./scripts

RUN mkdir -p /app/captures /app/uploads /app/clips

EXPOSE 4000

CMD ["node", "server/index.js"]
