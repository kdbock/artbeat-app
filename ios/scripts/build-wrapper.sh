#! /bin/bash

# Remove -G flag from CFLAGS and CXXFLAGS
export CFLAGS="${CFLAGS//-G/}"
export CXXFLAGS="${CXXFLAGS//-G/}"

# Execute the original command
"$@"
