# List Supported Crosswalk Code Systems

Returns the names of all supported code‐to‐code mappings (crosswalks)
provided by the package.

## Usage

``` r
supported_cross()
```

## Value

A character vector of mapping identifiers in the form
`"<from>_to_<to>"`, for example `"ICD9CM_to_CCSCM"` or `"NDC_to_ATC"`.

## Examples

``` r
supported_cross()
#>  [1] "ICD9CM_to_CCSCM"      "ICD9PROC_to_CCSPROC"  "ICD10CM_to_CCSCM"    
#>  [4] "ICD10PROC_to_CCSPROC" "NDC_to_ATC"           "ICD10CM_to_ICD9CM"   
#>  [7] "ICD9CM_to_ICD10CM"    "ICD10PCS_to_ICD9PCS"  "ICD9PCS_to_ICD10PCS" 
#> [10] "ICD10CMPCS_to_ICD9CM"
```
