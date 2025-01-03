FROM alpine:latest AS prep
RUN apk --update add ca-certificates

FROM golang:1.23 AS builder
RUN go install go.opentelemetry.io/collector/cmd/builder@latest
COPY ./otelcol-dev ./otelcol-dev
COPY ./builder-config.yaml .
ENV CGO_ENABLED=0
RUN builder --skip-generate --skip-get-modules  --config builder-config.yaml

FROM scratch

ARG USER_UID=10001
ARG USER_GID=10001
USER ${USER_UID}:${USER_GID}

COPY --from=prep /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /go/otelcol-dev/otelcontribcol /
EXPOSE 4317 55680 55679
ENTRYPOINT ["/otelcontribcol"]
CMD ["--config", "/etc/otel/config.yaml"]