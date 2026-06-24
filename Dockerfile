FROM node:18-alpine

WORKDIR /app

RUN addgroup -S namegen && adduser -S namegen -G namegen

COPY --chown=namegen:namegen package*.json ./
RUN npm ci --omit=dev

COPY --chown=namegen:namegen . .

ENV SERVER_PORT=8080
EXPOSE 8080

USER namegen

CMD ["node", "server.js"]
