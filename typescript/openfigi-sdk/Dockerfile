FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY example.ts ./

CMD ["npx", "tsx", "example.ts"]
