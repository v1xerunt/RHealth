## Initial CRAN Submission

This is the first CRAN submission of RHealth.

## Test environments

* Local: Windows 11 x64 (build 26200), R 4.4.3
* GitHub Actions (planned):
  - macOS-latest, R-release
  - windows-latest, R-release
  - ubuntu-latest, R-devel
  - ubuntu-latest, R-release

## R CMD check results

There were no ERRORs or WARNINGs.

There was 1 NOTE:

* New submission

## Package Dependencies

This package has a dependency on the `torch` package, which is essential for the deep learning functionality that forms the core of RHealth. The torch dependency cannot be moved to Suggests as:

1. All model implementations require torch for neural network operations
2. The package's primary purpose is to provide deep learning tools for healthcare
3. Users explicitly install RHealth for its deep learning capabilities
4. The BaseModel and all derived models fundamentally depend on torch::nn_module

The torch package is well-maintained, cross-platform, and widely used in the R community for deep learning applications.

## Target Audience

RHealth is designed for:
* Healthcare researchers conducting predictive modeling studies
* Data scientists working with Electronic Health Records (EHR)
* Machine learning practitioners in healthcare
* Academic researchers in medical informatics

The package requires access to healthcare datasets (MIMIC, eICU, OMOP, etc.) which users must obtain separately through proper institutional channels (e.g., PhysioNet). Example datasets are referenced in documentation and vignettes.

## Additional Repositories

The DESCRIPTION includes:
```
Additional_repositories: https://community.r-multiverse.org
```

This is to facilitate installation of the torch package for users, as torch binaries are distributed through r-multiverse in addition to CRAN. This repository URL is optional and does not affect CRAN installation.

## Documentation and Vignettes

The package includes comprehensive vignettes demonstrating:
* Quick start guide with sample MIMIC-IV data
* Medical code module usage
* Dataset processing workflows
* Model training examples
* Task-specific tutorials (eICU, EHRShot, OMOP)

Some vignette code blocks use `\dontrun{}` or `\donttest{}` as they require large external datasets that users must download separately.

## Testing

The package includes unit tests covering:
* Model architectures (CNN, Transformer, AdaCare, ConCare)
* Metrics calculation (binary, multiclass, multilabel, regression)
* OMOP dataset integration
* All tests pass successfully

## Downstream Dependencies

There are currently no downstream dependencies for this package.

## Links and References

* GitHub repository: https://github.com/v1xerunt/RHealth
* Documentation: https://v1xerunt.github.io/RHealth
* Related Python library: https://github.com/sunlabuiuc/PyHealth
* Funding: R Consortium ISC Grant (2024)
