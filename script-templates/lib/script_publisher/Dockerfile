FROM ruby:3.2.0-bullseye

LABEL org.opencontainers.image.description Course Manager course script publishing script

WORKDIR /script
COPY * /script/
RUN gem update && gem cleanup
RUN gem install bundler
RUN bundle install
ENTRYPOINT ["/script/publish"]