
<a href="https://www.harmonize-tools.org/">
    <img height="120" align="right" src="https://harmonize-tools.github.io/harmonize-logo.png" />
</a>

<a href="https://harmonize-tools.github.io/socio4health/">
    <img height="120" src="https://raw.githubusercontent.com/harmonize-tools/socio4health/main/docs/source/_static/image.png" />
</a>

# socio4healthR

## R Wrapper for socio4health
                                                             
<!-- badges: start -->

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![MIT
license](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/harmonize-tools/socio4healthR/blob/main/LICENSE.md)
[![GitHub
contributors](https://img.shields.io/github/contributors/harmonize-tools/socio4healthR)](https://github.com/harmonize-tools/socio4healthR/graphs/contributors)
![commits](https://badgen.net/github/commits/harmonize-tools/socio4healthR/main)
<!-- badges: end -->

## Overview  
<p style="font-family: Arial, sans-serif; font-size: 14px;">
  socio4healthR is an R wrapper for the <a href="https://github.com/harmonize-tools/socio4health">Python socio4health library</a>. It is an extraction, transformation and loading (ETL) classification tool designed to simplify the intricate process of collecting and merging data from multiple sources, focusing on sociodemographic and census datasets from Colombia, Brazil, and Peru, into a harmonized dataset.
</p>

### Key Features

- **Data Extraction**: Seamlessly retrieve data from online sources via web scraping or from local files
- **Format Support**: CSV, Excel, JSON, Parquet, SPSS, geospatial files, and fixed-width format files
- **Data Harmonization**: Align and merge datasets using column mapping and value standardization
- **Automatic Type Conversion**: Seamlessly convert between Dask DataFrames, pandas, and R data.frames
- **Advanced Features**: Text classification with BERT, dictionary standardization, and data filtering



## Dependencies

<table>
  <tr>
    <td align="center">
      <a href="https://www.dask.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/17131925?s=200&v=4" height="50" alt="pandas logo">
      </a>
    </td>
    <td align="left">
      <strong>Dask</strong><br>
     Dask is a flexible parallel computing library for analytics.<br>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://pandas.pydata.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/21206976?s=280&v=4" height="50" alt="pandas logo">
      </a>
    </td>
    <td align="left">
      <strong>Pandas</strong><br>
      Pandas is a well-known open source data analysis and manipulation tool.<br>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://geopandas.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/8130715?s=48&v=4" height="50" alt="pandas logo">
      </a>
    </td>
    <td align="left">
      <strong>Geopandas</strong><br>
     Python tools for geographic data.<br>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://numpy.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/288276?s=48&v=4" height="50" alt="numpy logo">
      </a>
    </td>
    <td align="left">
      <strong>Numpy</strong><br>
      The fundamental package for scientific computing with Python.<br>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://scrapy.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/733635?s=48&v=4" height="50" alt="scrapy logo">
      </a>
    </td>
    <td align="left">
      <strong>Scrapy</strong><br>
      Framework for extracting the data you need from websites.<br>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://matplotlib.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/215947?s=48&v=4" height="50" alt="scrapy logo">
      </a>
    </td>
    <td align="left">
      <strong>Matplotlib</strong><br>
      Library for creating static, animated, and interactive visualizations in Python.<br>
    </td>
  </tr>
  <tr>
    <td align="center">
      <a href="https://pytorch.org/" target="_blank">
        <img src="https://avatars.githubusercontent.com/u/21003710?s=48&v=4" height="50" alt="scrapy logo">
      </a>
    </td>
    <td align="left">
      <strong>Torch</strong><br>
      Python package for tensor computation and deep neural networks.<br>
    </td>
  </tr>
</table>

- <a href="https://openpyxl.readthedocs.io/en/stable/">openpyxl</a>
- <a href="https://py7zr.readthedocs.io/en/latest/">py7zr</a>
- <a href="https://pypi.org/project/pyreadstat/">pyreadstat</a>
- <a href="https://tqdm.github.io/">tqdm</a>
- <a href="https://requests.readthedocs.io/en/latest/">requests</a>
- <a href="https://pypi.org/project/appdirs/">appdirs</a>
- <a href="https://pypi.org/project/pyarrow/">pyarrow</a>
- <a href="https://pypi.org/project/deep-translator/">deep_translator</a>
- <a href="https://pypi.org/project/transformers/">transformers</a>
- <a href="https://pypi.org/project/pytest/">pytest</a>

## Installation

### Requirements

Before installing socio4healthR, ensure you have:

- **R** >= 4.1.0
- An internet connection the first time Python functionality is used

Python >= 3.10 and the complete `socio4health` dependency stack are managed
automatically by `reticulate`. You do not need to create a Python environment
or run `pip install` manually. On Windows, the package selects the compatible
PyTorch 2.8 release to avoid the DLL initialization regression in newer
PyTorch releases when embedded in Qt applications such as RStudio. It also
uses pandas 2.x because the current `socio4health` release is not yet compatible
with pandas 3.x.

### Install socio4healthR from CRAN

```r
install.packages("socio4healthR")
```

### Install the development version from GitHub

```r
# Install devtools if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install from GitHub
devtools::install_github("harmonize-tools/socio4healthR")
```

Unless the user explicitly selects another Python installation, socio4healthR
gives the managed environment priority over legacy environments such as
`r-reticulate`. The first call to a function backed by Python creates this
cached, isolated environment and installs `socio4health` with all its
dependencies. To perform this provisioning immediately and inspect the
selected Python installation:

```r
library(socio4healthR)
s4h_check_env(initialize = TRUE)
```

Users who explicitly set `RETICULATE_PYTHON`, `RETICULATE_PYTHON_ENV`, or
`RETICULATE_USE_MANAGED_VENV = "no"` remain responsible for installing
compatible dependencies in that environment. To force the managed environment
before loading the package, set `Sys.setenv(RETICULATE_PYTHON = "managed")`.

## How to Use it

To use socio4healthR, follow these steps:

1. Load the package in your R script:

   ```r
   library(socio4healthR)
   ```

2. Create an instance of the `Extractor` class:

   ```r
   extractor <- s4h_extractor(input_path = "./path/to/data")
   ```

3. Extract data and create a list of DataFrames:

   ```r
   data_list <- s4h_extract(
     extractor = extractor,
     return_as = "dask"
   )
   
   # Create a Harmonizer
   harmonizer <- s4h_harmonizer()
   
   # Harmonize your data
   merged_data <- s4h_vertical_merge(
     harmonizer,
     data_list,
     return_as = "data.frame"
   )
   ```

For more detailed examples and use cases, please refer to the [socio4health documentation](https://harmonize-tools.github.io/socio4health/).

## Resources

<details>
<summary>
Package Website
</summary>

The [socio4health website](https://harmonize-tools.github.io/socio4health/) package website includes **API reference**, **user guide**, and **examples**. The site mainly concerns the release version, but you can also find documentation for the latest development version.

</details>
<details>
<summary>
Organisation Website
</summary>

[Harmonize](https://www.harmonize-tools.org/) is an international project that develops cost-effective and reproducible digital tools for stakeholders in Latin America and the Caribbean (LAC) affected by a changing climate. These stakeholders include cities, small islands, highlands, and the Amazon rainforest.

The project consists of resources and [tools](https://harmonize-tools.github.io/) developed in conjunction with different teams from Brazil, Colombia, Dominican Republic, Peru, and Spain.

</details>

## Organizations

<table>
  <tr>
    <td align="center">
      <a href="https://www.bsc.es/" target="_blank">
        <img src="https://imgs.search.brave.com/t_FUOTCQZmDh3ddbVSX1LgHYq4mzCxvVA8U_YHywMTc/rs:fit:500:0:0/g:ce/aHR0cHM6Ly9zb21t/YS5lcy93cC1jb250/ZW50L3VwbG9hZHMv/MjAyMi8wNC9CU0Mt/Ymx1ZS1zbWFsbC5q/cGc" height="64" alt="bsc logo">
      </a>
    </td>
    <td align="center">
      <a href="https://uniandes.edu.co/" target="_blank">
        <img src="https://raw.githubusercontent.com/harmonize-tools/socio4health/refs/heads/main/docs/img/uniandes.png" height="64" alt="uniandes logo">
      </a>
    </td>
  </tr>
</table>


## Authors / Contact information

Here is the contact information of authors/contributors in case users have questions or feedback.
</br>
</br>
<a href="https://github.com/dirreno">
  <img src="https://avatars.githubusercontent.com/u/39099417?v=4" style="width: 50px; height: auto;" />
</a>
<span style="display: flex; align-items: center; margin-left: 10px;">
  <strong>Diego Irreño</strong> (developer)
</span>
</br>
<a href="https://github.com/Ersebreck">
  <img src="https://avatars.githubusercontent.com/u/81669194?v=4" style="width: 50px; height: auto;" />
</a>
<span style="display: flex; align-items: center; margin-left: 10px;">
  <strong>Erick Lozano</strong> (developer)
</span>
</br>
<a href="https://github.com/Juanmontenegro99">
  <img src="https://avatars.githubusercontent.com/u/60274234?v=4" style="width: 50px; height: auto;" />
</a>
<span style="display: flex; align-items: center; margin-left: 10px;">
  <strong>Juan Montenegro</strong> (developer, R package maintainer)
</span>
</br>
<a href="https://github.com/ingridvmoras">
  <img src="https://avatars.githubusercontent.com/u/91691844?s=400&u=945efa0d09fcc25d1e592d2a9fddb984fdc6ceea&v=4" style="width: 50px; height: auto;" />
</a>
<span style="display: flex; align-items: center; margin-left: 10px;">
  <strong>Ingrid Mora</strong> (documentation)
</span>
