FROM bash:5.2.15-alpine3.16

LABEL org.opencontainers.image.description Image for running Course Manager script utilities
COPY . /publisher
RUN apk update && apk add --no-cache yq jq zip curl
CMD ["/publisher/publish"]