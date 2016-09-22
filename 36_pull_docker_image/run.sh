#!/bin/bash

if [ -e "./credentials.yml" ]; then
  stub="./credentials.yml"
else
  stub=$1; shift
fi

set -uex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ATC_URL=${ATC_URL:-"http://192.168.100.4:8080"}
export fly_target=${fly_target:-tutorial}
echo "Concourse API target ${fly_target}"
echo "Concourse API $ATC_URL"
echo "Tutorial $(basename $DIR)"

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

if [[ "${stub}X" == "X" ]]; then
  echo "USAGE: run.sh path/to/credentials.yml"
  exit 1
fi
stub=$(realpath $stub)
if [[ ! -f ${stub} ]]; then
  echo "USAGE: run.sh path/to/credentials.yml"
  exit 1
fi

pushd $DIR
  fly sp -t ${fly_target} configure -c pipeline.yml -p main --load-vars-from ${stub} -n
  fly -t ${fly_target} unpause-pipeline --pipeline main
  curl $ATC_URL/pipelines/main/jobs/job-pull-image/builds -X POST
  fly -t ${fly_target} watch -j main/job-pull-image
popd
