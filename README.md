# Go Release GitHub Action
Automatically publish `Go` binaries to Github Release Assets through Github Action.    

## Features    
- Build `Go` binaries for release and publish to Github Release Assets.     
- Uses `golang 1.14`.    
- Support different `Go` project path in repository.     
- Support multiple binaries in same repository.    
- Customizable binary name.     
- Support multiple `GOOS`/`GOARCH` build in parallel by [Github Action Matrix Strategy](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idstrategymatrix) gracefully.         
- Publish `.zip` instead of `.tar.gz` for `windows`.     
- No `musl` library dependency issue on `linux`.     

## Usage

### Basic Example

```yaml
# .github/workflows/release.yaml
name: Release Go Binaries

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
| project_path | **Optional** | Where to run `go build`. <br>Use `.` by default. |
| binary_name | **Optional** | Specify another binary name if do not want to use repository basename. <br>Use your repository's basename if not set. |

### Advanced Example

- Release for multiple OS/ARCH in parallel by matrix strategy.    
- `Go` code is not in `.` of your repository.    
- Customize binary name.    

```yaml
# .github/workflows/release.yaml
name: Release Go Binaries

on: 
  release:
    types: [created]

env:
  GO_PROJECT_PATH: ./cmd/test-binary
  BINARY_NAME: test-binary


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
        project_path: "${{ env.GO_PROJECT_PATH }}"
        binary_name: "${{ env.BINARY_NAME }}"
```

