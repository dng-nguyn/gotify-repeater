BUILDDIR=./build
GOTIFY_VERSION=master
PLUGIN_NAME=cekwebhooks
PLUGIN_ENTRY=plugin.go
GO_VERSION=`cat $(BUILDDIR)/gotify-server-go-version`
VERSION_YEAR=$(shell date +%Y)
VERSION_MAJOR=$(shell echo $$(($$(git tag -l --sort=-creatordate|grep -v 'pre'|head -n 1|sed -E 's/^[^\.]+\.//g;s/\..+//g')+1)))
VERSION_MINOR=$(shell git log --oneline HEAD...$$(git tag -l --sort=-creatordate|grep -v 'pre'|head -n 1)|wc -l)
PLUGIN_VERSION=${VERSION_YEAR}.${VERSION_MAJOR}.${VERSION_MINOR}
DOCKER_BUILD_IMAGE=gotify/build
DOCKER_WORKDIR=/proj
DOCKER_RUN=sudo docker run --rm -v "$$PWD/.:${DOCKER_WORKDIR}" -v "`go env GOPATH`/pkg/mod/.:/go/pkg/mod:rw" -w ${DOCKER_WORKDIR}
DOCKER_GO_BUILD=go build -mod=readonly -a -installsuffix cgo -ldflags "$$LD_FLAGS -X main.VERSION=${PLUGIN_VERSION}" -buildmode=plugin 
TEST_SERVER_PLUGINS=./test-server/plugins

all: build-linux-amd64

run: build-linux-amd64 ${BUILDDIR}/${PLUGIN_NAME}-linux-amd64${FILE_SUFFIX}.so
	mkdir -p ./test-server/plugins
	sudo mv ${BUILDDIR}/${PLUGIN_NAME}-linux-amd64${FILE_SUFFIX}.so ${TEST_SERVER_PLUGINS}/${PLUGIN_NAME}-linux-amd64${FILE_SUFFIX}.so
	sudo docker compose up --build -d

download-tools:
	GO111MODULE=off go get -u github.com/gotify/plugin-api/cmd/gomod-cap

create-build-dir:
	mkdir -p ${BUILDDIR} || true

update-go-mod: create-build-dir
	wget -LO ${BUILDDIR}/gotify-server.mod https://raw.githubusercontent.com/gotify/server/${GOTIFY_VERSION}/go.mod
	go run github.com/gotify/plugin-api/cmd/gomod-cap -from ${BUILDDIR}/gotify-server.mod -to go.mod
	rm ${BUILDDIR}/gotify-server.mod || true
	go mod tidy

get-gotify-server-go-version: create-build-dir
	rm ${BUILDDIR}/gotify-server-go-version || true
	wget -LO ${BUILDDIR}/gotify-server-go-version https://raw.githubusercontent.com/gotify/server/${GOTIFY_VERSION}/GO_VERSION

build-linux-amd64: get-gotify-server-go-version update-go-mod
	${DOCKER_RUN} ${DOCKER_BUILD_IMAGE}:$(GO_VERSION)-linux-amd64 ${DOCKER_GO_BUILD} -o ${BUILDDIR}/${PLUGIN_NAME}-linux-amd64${FILE_SUFFIX}.so ${DOCKER_WORKDIR}

build-linux-arm-7: get-gotify-server-go-version update-go-mod
	${DOCKER_RUN} ${DOCKER_BUILD_IMAGE}:$(GO_VERSION)-linux-arm-7 ${DOCKER_GO_BUILD} -o ${BUILDDIR}/${PLUGIN_NAME}-linux-arm-7${FILE_SUFFIX}.so ${DOCKER_WORKDIR}

build-linux-arm64: get-gotify-server-go-version update-go-mod
	${DOCKER_RUN} ${DOCKER_BUILD_IMAGE}:$(GO_VERSION)-linux-arm64 ${DOCKER_GO_BUILD} -o ${BUILDDIR}/${PLUGIN_NAME}-linux-arm64${FILE_SUFFIX}.so ${DOCKER_WORKDIR}

build: build-linux-arm-7 build-linux-amd64 build-linux-arm64

.PHONY: build
