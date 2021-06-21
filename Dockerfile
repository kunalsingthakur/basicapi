FROM node:14
WORKDIR /usr/src/app
COPY *.json ./
RUN npm install
COPY . .
EXPOSE 3500
CMD [ "node", "server.js" ]
