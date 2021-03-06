# ------------------------------------------------------------- [STAGE] INIT
ARG ALPINE_TAG=3.14.1
FROM alpine:$ALPINE_TAG as config-alpine

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone

# ------------------------------------------------------------- [STAGE] BUILD
FROM alpine:$ALPINE_TAG as config-prometheus

ARG BRANCH=v0.0.0

RUN apk add --no-cache bash build-base curl git go yarn

RUN git config --global advice.detachedHead false

RUN mkdir /usr/lib/go/src/github.com
WORKDIR /usr/lib/go/src/github.com
RUN git clone --branch $BRANCH --depth 1 https://github.com/prometheus/prometheus.git
WORKDIR /usr/lib/go/src/github.com/prometheus
RUN make assets
RUN make build

WORKDIR /

# ----------------------------------------------------------- [STAGE] FINAL
FROM alpine:$ALPINE_TAG

EXPOSE 9090

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone  /etc/timezone

COPY --from=config-prometheus /usr/lib/go/src/github.com/prometheus/prometheus  /usr/bin/prometheus
COPY --from=config-prometheus /usr/lib/go/src/github.com/prometheus/promtool  /usr/bin/promtool

COPY config.yaml /etc/prometheus/config.yaml

RUN mkdir -p /opt/prometheus-data

RUN chmod 777 /opt/prometheus-data
             
ARG USER=prometheus
RUN addgroup $USER \
 && adduser -D -s /bin/sh -G $USER $USER \
 && echo "$USER:$USER" | chpasswd
 
USER $USER
WORKDIR /home/prometheus

RUN ln -s /opt/prometheus-data /home/prometheus/data

ENTRYPOINT ["/usr/bin/prometheus"]
CMD ["--config.file=/etc/prometheus/config.yaml"]
