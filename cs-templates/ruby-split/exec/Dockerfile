FROM ruby:3.3-bullseye

WORKDIR /exec

COPY Gemfile /exec/Gemfile
COPY Gemfile.lock /exec/Gemfile.lock

RUN bundle install