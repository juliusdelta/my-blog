#!/bin/bash
echo "Building hugo..."

git submodule update --init

hugo 2>&1
echo "Hugo site built!"

# echo "Copying _redirects..."
# cp _redirects public/
# echo "Redirects copied!"

echo "Build successful"
