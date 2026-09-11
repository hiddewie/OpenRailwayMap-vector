FROM node:24-alpine@sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f

WORKDIR /build

RUN npm install -g @jirutka/ajv-cli@6.0.0

COPY . .

ENTRYPOINT ["sh"]
CMD ["test/test.sh"]
