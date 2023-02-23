FROM ruby:3.2.0-alpine AS build-env
WORKDIR /metadata_server
RUN apk update && apk upgrade && apk add --no-cache build-base openssl-dev readline-dev
COPY Gemfile* ./
RUN bundle config deployment true \
    && bundle install \
    && rm -rf vendor/bundle/ruby/3.2.0/cache/*.gem \
    && find vendor/bundle/ruby/3.2.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/3.2.0/gems/ -name "*.o" -delete
COPY . ./

FROM ruby:3.2.0-alpine
LABEL org.opencontainers.image.description Metadata Stub Server for Course Manager Script Templates
WORKDIR /metadata_server
RUN apk update && apk upgrade && apk add --no-cache curl
COPY --from=build-env /metadata_server /metadata_server
COPY --from=build-env /usr/local/bundle/config /usr/local/bundle/config
EXPOSE 80
HEALTHCHECK --interval=1s --timeout=5s --start-period=5s --retries=3 CMD ["curl", "--fail", "http://localhost/skytap"]
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "80"]