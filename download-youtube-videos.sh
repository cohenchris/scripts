#!/bin/bash

while IFS= read -r line; do
  yt-dlp "$line"
done < $1
