FROM golang:1.26-alpine AS build

ARG GOPROXY=https://proxy.golang.org,direct
ARG GOSUMDB=sum.golang.org
WORKDIR /src
COPY go.mod go.sum ./
RUN GOPROXY="$GOPROXY" GOSUMDB="$GOSUMDB" go mod download
COPY cmd ./cmd
COPY internal ./internal
COPY migrations ./migrations
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /api ./cmd/api
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /xingshe-migrate ./cmd/migrate

FROM alpine:3.23
RUN addgroup -S api && adduser -S -G api api
WORKDIR /app
COPY --from=build /api /usr/local/bin/api
COPY --from=build /xingshe-migrate /usr/local/bin/xingshe-migrate
COPY --from=build /src/migrations ./migrations
USER api
EXPOSE 8080
ENTRYPOINT ["api"]
