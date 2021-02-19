# The effects of experimental bias on differential abundance analysis

[![DOI](https://zenodo.org/badge/340487467.svg)](https://zenodo.org/badge/latestdoi/340487467)

This repository contains an in-progress manuscript on the effects of experimental bias on differential abundance analysis.
I present a mathematical framework for determining how taxon-specific bias in metagenomics and other measurements affects both the relative and absolute abundances that are inferred under different experimental designs.
I then use this framework to derive expressions for the error in the inferred log fold changes (LFCs) and other linear regression coefficients. 
This framework predicts that certain approaches to relative and absolute differential abundance are more sensitive to bias than others.
The effects of bias can be mitigated by choosing an insensitive approach or performing a calibration procedure using targeted abundance measurements of one or more specific taxa.

The manuscript is structured as a [bookdown](https://github.com/rstudio/bookdown) article.
Once it is in a more complete state I will make a rendered version available.
