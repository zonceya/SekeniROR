#!/bin/bash

while true; do
  curl -s https://sekeni.loca.lt/healthcheck > /dev/null
  echo "Pinged tunnel at $(date)"
  sleep 60
done
