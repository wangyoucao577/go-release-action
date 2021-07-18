
LDFLAGS =

GIT_COMMIT = $(shell git rev-parse HEAD)
BUILD_TIME = $(shell date)

LDFLAGS += -X main.gitCommit=${GIT_COMMIT}
LDFLAGS += -X main.gitRef=${GIT_COMMIT}
LDFLAGS += -X "main.buildTime=${BUILD_TIME}"
LDFLAGS += $(EXT_LDFLAGS)

BUILD_PATH = build

all: app

# Run tests
test: fmt vet
	go test ./... -coverprofile cover.out

# Build friendly-yaml binary
app: fmt vet md
	go build -o ${BUILD_PATH}/testmain -ldflags '$(LDFLAGS)' ./test_main.go

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Create build folder
md:
	mkdir -p ${BUILD_PATH}