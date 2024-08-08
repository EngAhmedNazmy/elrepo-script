#!/bin/bash

usage() {
  echo "Usage: $0 -r <redhat_release> <drivers...>"
  echo "This script updates old drivers not found in your Red Hat release."
  echo "Options:"
  echo "  -r <redhat_release>  Specify the Red Hat release version."
  echo "  -h                   Display this help message."
}

# Parse command-line options
while getopts ":r:h" opt; do
  case ${opt} in
    r)
      redhat_release=${OPTARG}
      echo "Red Hat release is ${OPTARG}"
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}"
      usage
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument."
      usage
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [[ -z "${redhat_release}" ]]; then
  echo "Error: Red Hat release is required."
  usage
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  echo "Error: No drivers specified."
  usage
  exit 1
fi

if [[ -e elrepo-scripts/mkdd.iso ]]; then
  echo "Error: A file named mkdd.iso already exists in elrepo-scripts. Rename or move it before proceeding."
  exit 1
fi

# Create the necessary directory structure
mkdir -p mkdd/rpms/x86_64
echo "Driver Update Disk version 3" > mkdd/rhdd3

# Change to the driver directory
cd mkdd/rpms/x86_64 || { echo "Failed to change directory"; exit 1; }

# Download drivers
for driver in "$@"; do
  driver_name=$(curl -s "https://elrepo.org/linux/elrepo/el${redhat_release}/x86_64/RPMS/" | grep -Po '(?<=href=")[^"]*(?=")' | grep "${driver}" | tail -1)
  if [[ -n "${driver_name}" ]]; then
    curl -O "https://elrepo.org/linux/elrepo/el${redhat_release}/x86_64/RPMS/${driver_name}" && echo "${driver_name} downloaded successfully"
  else
    echo "Driver ${driver} not found for Red Hat release ${redhat_release}"
  fi
done

# Return to the initial directory and create the ISO
cd ../../.. || { echo "Failed to change directory"; exit 1; }
genisoimage -o mkdd.iso -J -R "mkdd" && echo "ISO file created successfully"

# Move the ISO and clean up
mv mkdd.iso "elrepo-scripts"
rm -rf "mkdd"

