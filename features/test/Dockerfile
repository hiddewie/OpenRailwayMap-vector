FROM node:24-alpine@sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f

WORKDIR /build/test

COPY test/package.json test/package-lock.json .
RUN npm install

COPY test/test.js .

WORKDIR /build

COPY schema schema
COPY *.yaml .

ENTRYPOINT ["node"]
CMD ["test/test.js"]
