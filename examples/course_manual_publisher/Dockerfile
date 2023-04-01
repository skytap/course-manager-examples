FROM ruby:3.2.0-bullseye

LABEL org.opencontainers.image.description Course Manager course manual publishing script

WORKDIR /script
COPY Gemfile* publish course_manual_publisher.rb /script/
RUN gem update && gem cleanup
RUN gem install bundler
RUN bundle install
ENTRYPOINT ["/script/publish"]

