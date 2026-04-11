FROM node:22-alpine@sha256:dbcedd8aeab47fbc0f4dd4bffa55b7c3c729a707875968d467aaaea42d6225af

WORKDIR /build

RUN npm install -g ajv-cli@5.0.0

COPY . .

ENTRYPOINT ["sh"]
CMD ["test/test.sh"]
