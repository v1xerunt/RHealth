
<!-- README.md is generated from README.Rmd. Please edit that file -->

# RHealth

<!-- badges: start -->

<!-- badges: end -->

RHealth is an open-source R package specifically designed to bring
comprehensive deep learning toolkits to the R community for healthcare
predictive modeling. Funded by the [ISC grant from the R
Consortium](https://r-consortium.org/all-projects/2024-group-2.html#deeprhealth-a-deep-learning-toolkit-for-healthcare-predictive-modeling),
RHealth aims to provide an accessible, integrated environment for R
users.

This package is built upon its python version
[PyHealth](https://github.com/sunlabuiuc/PyHealth).

## Citing RHealth :handshake:

Zhixia Ren, Ji Song, Liantao Ma, Ewen M Harrison, and Junyi Gao. 2025.
“RHealth: A Deep Learning Toolkit for Healthcare Predictive Modeling”.
GitHub.

``` bibtex
@misc{Ren2025,
  author = {Zhixia Ren, Ji Song, Liantao Ma, Ewen M Harrison, Junyi Gao},
  title = {RHealth},
  year = {2025},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/v1xerunt/RHealth}}
}
```

## Installation

You can install the development version of RHealth from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("RHealth")
```

Alternatively, using devtools:

``` r
# install.packages("devtools")
devtools::install_github("RHealth")
```

Once RHealth is installed, you can load the package to access medcode
functionalities:

``` r
library(RHealth)
```

## 1. Medical Code Map

Our medical code mapping module provides tools to map medical codes
between and within various medical coding systems. **This module can be
used independently.**

### 1.1. Code Lookup with lookup_code()

Retrieve the description for a specific medical code.

``` r
# Example: Look up ICD-9-CM code "428.0"
code_description <- lookup_code(code = "428.0", system = "ICD9CM")
print(code_description)
```

### 1.2. Hierarchy Navigation

Explore relationships within coding systems. \#### Get Ancestors with
get_ancestors():

``` r
# Example: Find ancestors for ICD-9-CM code "428.22"
ancestor_codes <- get_ancestors(code = "428.22", system = "ICD9CM")
print(ancestor_codes)
```

#### Get Descendants with get_descendants():

``` r
# Example: Find descendants for ICD-9-CM code "428"
descendant_codes <- get_descendants(code = "428", system = "ICD9CM")
print(head(descendant_codes)) # Showing first few for brevity
print(paste("Total descendants for '428':", length(descendant_codes)))
```

### 1.3. Cross-System Mapping with map_code()

Translate codes from one system to another. First, see available
mappings:

``` r
supported_cross()
```

Then, map a code:

``` r
# Example: Map ICD-9-CM "428.0" to CCSCM
mapped_ccscm_code <- map_code(code = "428.0", from = "ICD9CM", to = "CCSCM")
print(mapped_ccscm_code)
```

### 1.4. ATC Specific Utilities

#### ATC Level Conversion with atc_convert():

``` r
atc_code <- "L01BA01" # Methotrexate
print(paste("L1 (Anatomical Main Group):", atc_convert(atc_code, level = 1)))
print(paste("L3 (Therapeutic/Pharmacological Subgroup):", atc_convert(atc_code, level = 3)))
print(paste("L4 (Chemical/Therapeutic/Pharmacological Subgroup):", atc_convert(atc_code, level = 4)))
```

#### Drug-Drug Interactions (DDI) with get_ddi():

``` r
ddi_data <- get_ddi()
print("First few known Drug-Drug Interactions (ATC pairs):")
print(head(ddi_data))
```

## Current Development and Future Plans

RHealth is currently under active development. The initial phase focuses
on establishing two foundational modules:

1.  **EHR Database Module:** This module is being developed to provide a
    standardized framework for ingesting, processing, and managing
    diverse Electronic Health Record (EHR) datasets. It aims to support
    public datasets like MIMIC-III, MIMIC-IV, and eICU, as well as
    user-specific data formats such as OMOP-CDM. The goal is to ensure
    data consistency for subsequent modeling tasks.
2.  **EHR Code Mapping Module (medcode):** This module, with its core
    `medcode` component, facilitates mapping between and within various
    medical coding systems (e.g., ICD, NDC, RxNorm). Key functionalities
    like code lookup, hierarchy navigation, cross-system mapping, and
    ATC utilities are already implemented, as demonstrated in the
    examples above.

Looking further ahead, our development roadmap includes the expansion of
RHealth with several key modules and enhancements:

- **Healthcare DL Core Module:** This module will integrate traditional
  machine learning models (e.g., Random Forests, Support Vector
  Machines) and state-of-the-art healthcare-specific deep learning
  models (e.g., RETAIN, AdaCare, Transformers, graph networks,
  convolutional networks, recurrent networks).
- **Prediction Task Module:** This module will be designed to handle
  various clinical prediction tasks using EHR data, including
  patient-level predictions (e.g., mortality, disease risk), intra-visit
  predictions (e.g., length of stay, drug recommendation), and
  inter-visit predictions (e.g., readmission risk, future diagnoses).
- **Support for Multi-modal Data Integration:** Enhancements to handle
  and integrate diverse data types beyond structured EHR data.
- **Clinical Trial Applications:** Developing functionalities to support
  research and analysis in the context of clinical trials.
- **Large Language Model (LLM) Enhancement:** Exploring the integration
  of LLMs to augment package capabilities.

RHealth aims to provide the R community with a powerful and
user-friendly toolkit for healthcare predictive modeling using deep
learning. We are glad to hear your feedbacks and suggestions via email
or submitting issues.
