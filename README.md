# Go Release GitHub Action
![Build Docker](https://github.com/wangyoucao577/go-release-action/workflows/Build%20Docker/badge.svg) ![PR Build](https://github.com/wangyoucao577/go-release-action/workflows/PR%20Build/badge.svg) [![Test](https://github.com/wangyoucao577/go-release-action/actions/workflows/autotest.yml/badge.svg)](https://github.com/wangyoucao577/go-release-action/actions/workflows/autotest.yml)
Automatically publish `Go` binaries to Github Release Assets through Github Action.

## Features
- Build `Go` binaries for release and publish to Github Release Assets.
- Customizable `Go` versions. `latest` by default.
- Support different `Go` project path in repository.
- Support multiple binaries in same repository.
- Customizable binary name.
- Support multiple `GOOS`/`GOARCH` build in parallel by [Github Action Matrix Strategy](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix) gracefully.
- Publish `.zip` instead of `.tar.gz` for `windows`.
- No `musl` library dependency issue on `linux`.
- Support extra command that will be executed before `go build`. You may want to use it to solve dependency if you're NOT using [Go Modules](https://github.com/golang/go/wiki/Modules).
- Rich parameters support for `go build`(e.g. `-ldflags`, etc.).
- Support package extra files into artifacts (e.g., `LICENSE`, `README.md`, etc).
- Support customize build command, e.g., use [packr2](https://github.com/gobuffalo/packr/tree/master/v2)(`packr2 build`) instead of `go build`. Another important usage is to use `make`(`Makefile`) for building on Unix-like systems.
- Support optional `.md5` along with artifacts.
- Support optional `.sha256` along with artifacts.
- Customizable release tag to support publish binaries per `push` or `workflow_dispatch`(manually trigger).
- Support overwrite assets if it's already exist.
- Support customizable asset names.
- Support private repositories.
- Support executable compression by [upx](https://github.com/upx/upx).
- Support retry if upload phase fails.

## Usage

### Basic Example

```yaml
# .github/workflows/release.yaml

on:
  release:
    types: [created]

jobs:
  release-linux-amd64:
    name: release linux/amd64
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: wangyoucao577/go-release-action@v1.23
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        goos: linux
        goarch: amd64
```

### Parameters

| Parameter | **Mandatory**/**Optional** | Description |
| --------- | -------- | ----------- |
| github_token | **Mandatory** | Your `GITHUB_TOKEN` for uploading releases to Github asserts. |
| goos | **Mandatory** | `GOOS` is the running program's operating system target: one of `darwin`, `freebsd`, `linux`, and so on. |
| goarch | **Mandatory** | `GOARCH` is the running program's architecture target: one of `386`, `amd64`, `arm`, `arm64`, `s390x`, and so on. |
| goversion |  **Optional** | The `Go` compiler version. `latest`([check it here](https://go.dev/VERSION?m=text)) by default, optional `1.13`, `1.14`, `1.15`, `1.16` or `1.17`. <br>It also takes download URL instead of version string if you'd like to use more specified version. But make sure your URL is `linux-amd64` package, better to find the URL from [Go - Downloads](https://go.dev/dl/).<br>E.g., `https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz`. |
| project_path | **Optional** | Where to run `go build`. <br>Use `.` by default. |
| binary_name | **Optional** | Specify another binary name if do not want to use repository basename. <br>Use your repository's basename if not set. |
| pre_command | **Optional** | Extra command that will be executed before `go build`. You may want to use it to solve dependency if you're NOT using [Go Modules](https://github.com/golang/go/wiki/Modules). |
| build_command | **Optional** | The actual command to build binary, typically `go build`. You may want to use other command wrapper, e.g., [packr2](https://github.com/gobuffalo/packr/tree/master/v2), example `build_command: 'packr2 build'`. Remember to use `pre_command` to set up `packr2` command in this scenario.<br>It also supports the `make`(`Makefile`) building system, example `build_command: make`. In this case both `build_flags` and `ldflags` will be ignored since they should be written in your `Makefile` already. Also, please make sure the generated binary placed in the path where `make` runs, i.e., `project_path`. |
| executable_compression | **Optional** | Compression executable binary by some third-party tools. It takes compression command with optional args as input, e.g., `upx` or `upx -v`. <br>Only [upx](https://github.com/upx/upx) is supported at the moment.|
| build_flags | **Optional** | Additional arguments to pass the `go build` command. |
| ldflags | **Optional** | Values to provide to the `-ldflags` argument. |
| extra_files | **Optional** | Extra files that will be packaged into artifacts either. Multiple files separated by space. Note that extra folders can be allowed either since internal `cp -r` already in use. <br>E.g., `extra_files: LICENSE README.md` |
| md5sum | **Optional** | Publish `.md5` along with artifacts, `TRUE` by default. |
| sha256sum | **Optional** | Publish `.sha256` along with artifacts, `FALSE` by default. |
| release_tag | **Optional** | Target release tag to publish your binaries to. It's dedicated to publish binaries on every `push` into one specified release page since there's no target in this case. DON'T set it if you trigger the action by `release: [created]` event as most people do.|
| overwrite | **Optional** | Overwrite asset if it's already exist. `FALSE` by default. |
| asset_name | **Optional** | Customize asset name if do not want to use the default format `${BINARY_NAME}-${RELEASE_TAG}-${GOOS}-${GOARCH}`. <br>Make sure set it correctly, especially for matrix usage that you have to append `-${{ matrix.goos }}-${{ matrix.goarch }}`. A valid example could be  `asset_name: binary-name-${{ matrix.goos }}-${{ matrix.goarch }}`. |
| retry | **Optional** | How many times retrying if upload fails. `3` by default. |
| post_command | **Optional** | Extra command that will be executed for teardown work. e.g. you can use it to upload artifacts to AWS s3 or aliyun OSS |

### Advanced Example

- Release for multiple OS/ARCH in parallel by matrix strategy.
- `Go` code is not in `.` of your repository.
- Customize binary name.
- Use `go 1.13.1` from downloadable URL instead of the default version.
- Package extra `LICENSE` and `README.md` into artifacts.

```yaml
# .github/workflows/release.yaml

on:
  release:
    types: [created]

jobs:
  releases-matrix:
    name: Release Go Binary
    runs-on: ubuntu-latest
    strategy:
      matrix:
        # build and publish in parallel: linux/386, linux/amd64, linux/arm64, windows/386, windows/amd64, darwin/amd64, darwin/arm64
        goos: [linux, windows, darwin]
        goarch: ["386", amd64, arm64]
        exclude:
          - goarch: "386"
            goos: darwin
          - goarch: arm64
            goos: windows
    steps:
    - uses: actions/checkout@v2
    - uses: wangyoucao577/go-release-action@v1.23
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        goos: ${{ matrix.goos }}
        goarch: ${{ matrix.goarch }}
        goversion: "https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz"
        project_path: "./cmd/test-binary"
        binary_name: "test-binary"
        extra_files: LICENSE README.md
```

### More Examples
Welcome share your usage for other people's reference!
- [wiki/More-Examples](https://github.com/wangyoucao577/go-release-action/wiki/More-Examples)

[:clap:](":clap:")[:clap:](":clap:")[:clap:](":clap:") Enjoy! Welcome [star](https://github.com/wangyoucao577/go-release-action/) if like it[:smile:](:smile:)
