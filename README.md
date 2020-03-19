# Go Release GitHub Action
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
    - uses: wangyoucao577/go-release-action@master
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
| goarch | **Mandatory** | `GOARCH` is the running program's architecture target: one of `386`, `amd64`, `arm`, `s390x`, and so on. |
| goversion |  **Optional** | The `Go` compiler version. `1.14` by default, optional `1.13`. <br>It also takes download URL instead of version string if you'd like to use more specified version. But make sure your URL is `linux-amd64` package, better to find the URL from [Go - Downloads](https://golang.org/dl/).<br>E.g., `https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz`. |
| project_path | **Optional** | Where to run `go build`. <br>Use `.` by default. |
| binary_name | **Optional** | Specify another binary name if do not want to use repository basename. <br>Use your repository's basename if not set. |
| pre_command | **Optional** | Extra command that will be executed before `go build`. You may want to use it to solve dependency if you're NOT using [Go Modules](https://github.com/golang/go/wiki/Modules). |
| build_flags | **Optional** | Additional arguments to pass the go build command. |
| ldflags | **Optional** | Values to provide to the -ldflags argument. |

### Advanced Example

- Release for multiple OS/ARCH in parallel by matrix strategy.    
- `Go` code is not in `.` of your repository.    
- Customize binary name.    
- Use `go 1.13.1` from downloadable URL instead of default `1.14`.

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
    - uses: wangyoucao577/go-release-action@master
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        goos: ${{ matrix.goos }}
        goarch: ${{ matrix.goarch }}
        goversion: "https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz"
        project_path: "./cmd/test-binary"
        binary_name: "test-binary"
```

