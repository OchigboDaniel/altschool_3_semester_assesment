
#Build
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./

RUN go mod download

COPY Server/MuchToDo/ .

RUN CGO_ENABLED=0 GOOS=linux go build -o muchtodo ./cmd/api/main.go


FROM alpine:3.19

RUN apk add --no-cache ca-certificates

RUN adduser -D -s /bin/sh appuser

WORKDIR /app

COPY --from=builder /app/muchtodo .

# Copy .env.example as .env
# Real values are overridden by docker-compose environment variables
COPY --from=builder /app/.env.example .env

RUN chown appuser:appuser /app/muchtodo

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./muchtodo"]