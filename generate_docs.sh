#!/bin/bash

# This script generates the README.md file from the terraform-docs output.

terraform-docs markdown table --output-file README.md --output-mode inject .
