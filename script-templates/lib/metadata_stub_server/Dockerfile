FROM ruby:3.1.0


LABEL org.opencontainers.image.description Metadata Stub Server for Course Manager Script Templates

WORKDIR /metadata_server
COPY . /metadata_server
RUN bundle install
EXPOSE 80

CMD ["rackup", "-o", "0.0.0.0", "-p", "80"]
