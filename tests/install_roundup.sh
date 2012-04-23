#!/bin/sh

git clone https://github.com/bmizerany/roundup
(cd roundup && make && sudo make install)
