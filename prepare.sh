#!/bin/bash

rm -rf libs
mkdir libs
for f in ./plugins/*.zip; do \ 
   unzip -o "$f" -d ./libs; \
done    
