# Download and Cache Medical Code CSV

Fetches a CSV file for the specified medical code from a remote server,
caches it locally, and returns the path to the cached file.

## Usage

``` r
download_medcode(name)
```

## Arguments

- name:

  A single `character` string specifying the code name (without
  `".csv"`), e.g. `"ICD10"` or `"CPT"`.

## Value

A single `character` string giving the full path to the downloaded or
previously cached CSV file.

## Details

By default, when the package is loaded, `.onLoad()` sets
`options(RHealth.medcode_base)` to
`"https://storage.googleapis.com/pyhealth/resource/"`. The CSV will be
downloaded from
`file.path(getOption("RHealth.medcode_base"), paste0(name, ".csv"))`.

To override the download location, set your own base URL before calling:

    options(RHealth.medcode_base = "https://your.server/medcode/")

Cached files are stored under:
`file.path(rappdirs::user_cache_dir("RHealth"), "medcode")`.

## See also

[`path`](https://fs.r-lib.org/reference/path.html),
[`dir_create`](https://fs.r-lib.org/reference/create.html),
[`user_cache_dir`](https://rappdirs.r-lib.org/reference/user_cache_dir.html),
[`GET`](https://httr.r-lib.org/reference/GET.html),
[`write_disk`](https://httr.r-lib.org/reference/write_disk.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Use default server
path1 <- download_medcode("ICD10")

# Use a custom server
options(RHealth.medcode_base = "https://internal.example.com/medcode/")
path2 <- download_medcode("CPT")
} # }
```
