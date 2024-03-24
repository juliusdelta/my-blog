#!/bin/bash
echo "Building hugo..."

hugo -b $CF_PAGES_URL 2>&1
echo "Hugo site built!"

echo "Copying _redirects..."
cp _redirects public/
echo "Redirects copied!"

echo "Build successful"
