FROM ruby:3.2.0-bullseye AS build-env
WORKDIR /script
COPY Gemfile* /script/
RUN bundle config deployment true \
    && bundle install \
    && rm -rf vendor/bundle/ruby/3.2.0/cache/*.gem \
    && find vendor/bundle/ruby/3.2.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/3.2.0/gems/ -name "*.o" -delete

FROM ruby:3.2.0-slim-bullseye
LABEL org.opencontainers.image.description Course Manager course script publishing script
WORKDIR /script
COPY --from=build-env /script /script
COPY --from=build-env /usr/local/bundle/config /usr/local/bundle/config
COPY publish *.rb /script/
ENTRYPOINT ["/script/publish"]