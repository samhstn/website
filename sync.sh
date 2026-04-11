#!/bin/bash

if [ "$1" == "read" ]; then
  echo "Reading from S3"
  aws s3 sync s3://samhstn-website/assets ./assets
  aws s3 sync s3://samhstn-website/blog ./blog
else [ "$1" == "write" ]
  echo "Writing to S3"
  aws s3 sync ./assets s3://samhstn-website/assets
  aws s3 sync ./blog s3://samhstn-website/blog
  # todo add script which generates a sitemap.xml and a blog.json file
fi

