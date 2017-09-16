#!/bin/bash

#
# Set up and run Xvfb (X virtual framebuffer)
# This allows us to run headless X applications in docker. E.g. firefox.
#
export XVFB_LOG=/tmp/xvfb.docker.log
export DISPLAY=:99

pkill Xvfb
Xvfb $DISPLAY -ac 2>&1 -screen 0 1920x1080x16 >> $XVFB_LOG &

#
# To watch these tests run, start a vnc server in the docker container with:
# x11vnc -display :99
# Ensure port 5900 is exposed (the default vnc port)
# and then connect from outside of docker with:
# vncviewer localhost
#

#
# Run cucumber tests
#
export RAILS_ENV=cucumber
export TEST_SUITE=ci:cucumber_javascript

bundle exec rake db:schema:load
bundle exec rake db:migrate
bundle exec rake db:test:prepare

bundle exec rake $TEST_SUITE


