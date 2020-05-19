FROM alpine:3.10.2

RUN apk add --no-cache curl

RUN addgroup --system curler && adduser --system curler curler
USER curler:curler

ENTRYPOINT ["/usr/bin/curl"]
