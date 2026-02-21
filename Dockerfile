# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /bin/product_service ./cmd/main.go

# Runtime stage
FROM alpine:3.19

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY --from=builder /bin/product_service /app/product_service

RUN mkdir -p /app/logs

EXPOSE 8012

ENTRYPOINT ["/app/product_service"]
CMD ["-log.file", "/app/logs"]
