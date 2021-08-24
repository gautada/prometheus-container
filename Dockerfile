FROM alpine:3.14.1 as config-alpine

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone

FROM config-alpine as config-prometheus

RUN apk add --no-cache bash build-base curl git go yarn

RUN git config --global advice.detachedHead false
# RUN git clone --branch v1.8.4 --depth 1 https://github.com/coredns/coredns.git coredns

RUN mkdir /usr/lib/go/src/github.com
WORKDIR /usr/lib/go/src/github.com
RUN git clone --branch v2.29.1 --depth 1 https://github.com/prometheus/prometheus.git
WORKDIR /usr/lib/go/src/github.com/prometheus
RUN make build
RUN make assets

WORKDIR /

FROM alpine:3.14.1

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone  /etc/timezone

COPY --from=config-prometheus /usr/lib/go/src/github.com/prometheus/prometheus  /usr/bin/prometheus
COPY --from=config-prometheus /usr/lib/go/src/github.com/prometheus/promtool  /usr/bin/promtool

COPY config.yml /etc/prometheus/config.yml

ENTRYPOINT ["/usr/bin/prometheus"]
CMD ["--config.file=/etc/prometheus/config.yml"]
