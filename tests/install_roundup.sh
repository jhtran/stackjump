#!/bin/sh

git clone https://github.com/bmizerany/roundup
cd roundup
./configure
make && sudo make install
cd ..
