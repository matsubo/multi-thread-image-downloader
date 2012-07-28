#!/usr/bin/env bash
LOCKFILE=/tmp/scraper

lockfile -r0 $LOCKFILE

# load rvm ruby
source /Users/matsu/.rvm/scripts/rvm

#bundle install
ruby /Users/matsu/fire/scraping.rb
#rake do something


rm $LOCKFILE
