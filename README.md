# Go Release GitHub Action    
![Build Docker](https://github.com/wangyoucao577/go-release-action/workflows/Build%20Docker/badge.svg) ![PR Build](https://github.com/wangyoucao577/go-release-action/workflows/PR%20Build/badge.svg)       
Automatically publish `Go` binaries to Github Release Assets through Github Action.    

## Features    
- Build `Go` binaries for release and publish to Github Release Assets.     
- Customizable `Go` versions. `golang 1.14` by default.    
- Support different `Go` project path in repository.     
- Support multiple binaries in same repository.    
- Customizable binary name.     
- Support multiple `GOOS`/`GOARCH` build in parallel by [Github Action Matrix Strategy](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix) gracefully.         
- Publish `.zip` instead of `.tar.gz` for `windows`.     
- No `musl` library dependency issue on `linux`.     
- Support extra command that will be executed before `go build`. You may want to use it to solve dependency if you're NOT using [Go Modules](https://github.com/golang/go/wiki/Modules).       
- Rich parameters support for `go build`(e.g. `-ldflags`, etc.).     
- Support package extra files into artifacts (e.g., `LICENSE`, `README.md`, etc).    
- Support customize build command, e.g., use [packr2](https://github.com/gobuffalo/packr/tree/master/v2)(`packr2 build`) instead of `go build`.     
- Support optional `.md5` along with artifacts. 
- Support optional `.sha256` along with artifacts.     
- Customizable release tag to support publish binaries per `push`.      
- Support overwrite assets if it's already exist.    
- Support private repositories.     

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
    - uses: wangyoucao577/go-release-action@v1.12
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        goos: linux
        goarch: amd64
```

### Choose a version
- **Prefer latest release**(**faster** & **stable**): `wangyoucao577/go-release-action@v1.11`     
- If always want to work with newest changes:     
  - try out **faster** pre-built master: `wangyoucao577/go-release-action@master-prebuilt`
  - or use classic master: `wangyoucao577/go-release-action@master`

### Parameters

| Parameter | **Mandatory**/**Optional** | Description | 
| --------- | -------- | ----------- |
| github_token | **Mandatory** | Your `GITHUB_TOKEN` for uploading releases to Github asserts. |
| goos | **Mandatory** | `GOOS` is the running program's operating system target: one of `darwin`, `freebsd`, `linux`, and so on. |
| goarch | **Mandatory** | `GOARCH` is the running program's architecture target: one of `386`, `amd64`, `arm`, `s390x`, and so on. |
| goversion |  **Optional** | The `Go` compiler version. `1.14` by default, optional `1.13`. <br>It also takes download URL instead of version string if you'd like to use more specified version. But make sure your URL is `linux-amd64` package, better to find the URL from [Go - Downloads](https://golang.org/dl/).<br>E.g., `https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz`. |
| project_path | **Optional** | Where to run `go build`. <br>Use `.` by default. |
| binary_name | **Optional** | Specify another binary name if do not want to use repository basename. <br>Use your repository's basename if not set. |
| pre_command | **Optional** | Extra command that will be executed before `go build`. You may want to use it to solve dependency if you're NOT using [Go Modules](https://github.com/golang/go/wiki/Modules). |
| build_command | **Optional** | The actual command to build binary, typically `go build`. You may want to use other command wrapper, e.g., [packr2](https://github.com/gobuffalo/packr/tree/master/v2), example `build_command: 'packr2 build'`. Remember to use `pre_command` to set up `packr2` command in this scenario.|
| build_flags | **Optional** | Additional arguments to pass the `go build` command. |
| ldflags | **Optional** | Values to provide to the `-ldflags` argument. |
| extra_files | **Optional** | Extra files that will be packaged into artifacts either. Multiple files separated by space. Note that extra folders can be allowed either since internal `cp -r` already in use. <br>E.g., `extra_files: LICENSE README.md` |
| md5sum | **Optional** | Publish `.md5` along with artifacts, `TRUE` by default. |
| sha256sum | **Optional** | Publish `.sha256` along with artifacts, `FALSE` by default. |
| release_tag | **Optional** | Target release tag to publish your binaries to. It's dedicated to publish binaries on every `push` into one specified release page since there's no target in this case. DON'T set it if you trigger the action by `release: [created]` event as most people do.|
| overwrite | **Optional** | Overwrite asset if it's already exist. `FALSE` by default. |

### Advanced Example

- Release for multiple OS/ARCH in parallel by matrix strategy.    
- `Go` code is not in `.` of your repository.    
- Customize binary name.    
- Use `go 1.13.1` from downloadable URL instead of default `1.14`.
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
        # build and publish in parallel: linux/386, linux/amd64, windows/386, windows/amd64, darwin/386, darwin/amd64 
        goos: [linux, windows, darwin]
        goarch: ["386", amd64]
    steps:
    - uses: actions/checkout@v2
    - uses: wangyoucao577/go-release-action@v1.12
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