FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

CMD ["npx", "openfigi-mcp"]
