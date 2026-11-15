FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8

WORKDIR /build/test

COPY test/package.json test/package-lock.json .
RUN npm install

COPY test/test.js .

WORKDIR /build

COPY schema schema
COPY *.yaml .

ENTRYPOINT ["node"]
CMD ["test/test.js"]
