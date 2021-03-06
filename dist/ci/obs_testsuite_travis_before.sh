#!/bin/bash
# This script prepares the CI build for running

# No need to do those steps for rubocop or jshint
if [ "$1" = "rubocop" ] || [ "$1" = "jshint" ]; then
  exit 0
fi

echo "Configuring backend"
sed -i -e "s|my \$hostname = .*$|my \$hostname = 'localhost';|" \
       -e "s|our \$bsuser = 'obsrun';|our \$bsuser = 'jenkins';|" \
       -e "s|our \$bsgroup = 'obsrun';|our \$bsgroup = 'jenkins';|" src/backend/BSConfig.pm.template
cp src/backend/BSConfig.pm.template src/backend/BSConfig.pm
chmod a+x src/api/script/start_test_backend

pushd src/api
echo "Creating database"
mysql -e 'create database ci_api_test;'

echo "Configuring database"
cp config/database.yml.example config/database.yml
sed -e 's,password:.*,password:,' -i config/database.yml
sed -i "s|database: api|database: ci_api|" config/database.yml

echo "Configuring frontend"
cp config/options.yml.example config/options.yml
cp config/thinking_sphinx.yml.example config/thinking_sphinx.yml

echo "Initialize database"
bundle exec rails db:drop db:create db:setup --trace

# Stuff
# travis rvm can not deal with our extended executable names
sed -i 1,1s,\.ruby2\.3,, {script,bin}/*
# Clear temp data
rm -rf log/* tmp/cache tmp/sessions tmp/sockets
popd

echo "Build apidocs"
pushd docs/api
make
popd
