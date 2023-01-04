FROM ruby:3.1.3-alpine

LABEL org.opencontainers.image.description Metadata Stub Server for Course Manager Script Templates

WORKDIR /metadata_server
COPY . /metadata_server
RUN apk update && apk add --no-cache build-base curl
RUN bundle install
EXPOSE 80
HEALTHCHECK --interval=1s --timeout=5s --start-period=5s --retries=3 CMD ["curl", "--fail", "http://localhost/skytap"]
CMD ["rackup", "-o", "0.0.0.0", "-p", "80"]
