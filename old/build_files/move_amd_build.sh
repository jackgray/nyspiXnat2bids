#!/bin/bash

# USE: bash build.sh <path-to-file-to-add-to-image-during-build> <2nd-file>

# First generate conda lock file for environment config to add to build
# nevermind- conda not installed on doctor
docker buildx build \
--platform linux/amd64 \
--push \
-t jackgray/nifti2bids:amd64latest \
../move_image