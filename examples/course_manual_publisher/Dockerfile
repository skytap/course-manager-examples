FROM ruby:3.2.0-bullseye

LABEL org.opencontainers.image.description Course Manager course manual publishing script

WORKDIR /script
COPY Gemfile publish_manual.rb /script
# RUN apk update && apk add --no-cache build-base curl openssl-dev readline-dev
RUN gem update && gem cleanup
RUN gem install bundler
RUN bundle install
ENTRYPOINT ["bundle", "exec", "ruby", "publish_manual.rb"]

