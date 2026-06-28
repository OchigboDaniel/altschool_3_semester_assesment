# STAGE 1: Builder
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY Server/MuchToDo/go.mod Server/MuchToDo/go.sum ./

RUN go mod download

COPY Server/MuchToDo/ .

RUN CGO_ENABLED=0 GOOS=linux go build -o muchtodo ./cmd/api/main.go

# STAGE 2: Final
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

RUN adduser -D -s /bin/sh appuser

WORKDIR /app

COPY --from=builder /app/muchtodo .

RUN printf "PORT=8080\nMONGO_URI=mongodb://mongodb:27017\nDB_NAME=much_todo_db\nJWT_SECRET_KEY=changeme\nENABLE_CACHE=false\nLOG_LEVEL=INFO\nLOG_FORMAT=json\n" > .env && \
    chown appuser:appuser /app/muchtodo && \
    chown appuser:appuser .env

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./muchtodo"]