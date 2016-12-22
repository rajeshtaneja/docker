#!/bin/bash

if [ -n "$1" ] && [ "$1" = "all" ]; then
    # Stop all running docker instances.
    docker stop $(docker ps -aq) > /dev/null 2>&1
    docker rm $(docker ps -aq) > /dev/null 2>&1
else
    # Remove stopped + exited containers, which skipped Exit as jenkins job might have been stopped and not removed container.
    docker rm -v $(docker ps -a -q -f status=exited) > /dev/null 2>&1
    docker rm -v $(docker ps -a -q -f status=created) > /dev/null 2>&1
fi

# Clean up any unused volumes.
docker rmi $(docker images -f "dangling=true" -q) > /dev/null 2>&1
