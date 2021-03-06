#!/bin/bash
DAEMONIZED=false
WORKERS=6

for i in "$@"
do
  case $i in
      -d|--daemonized)
      DAEMONIZED=true
      shift # past argument=value
      ;;

      -w=*|--workers=*)
      WORKERS="${i#*=}"
      shift # past argument=value
      ;;

      -?|--help)
      echo "USAGE: ./run_canary.sh -d -w=10"
      echo "-d | --daemonized : run in daemonized mode"
      echo "-w | --workers : the number of canary-worker processes to spawn (defaults to 6)"
      exit

      shift
      ;;

      *)
      echo "Invalid Options"
      echo "Run ./run_canary.sh --help for valid parameters."
      exit
              # unknown option
      ;;
  esac
done

# kill existing canary's
./kill_canary.sh

# remove existing containers
docker kill docker_mongo_1
docker rm docker_mongo_1

# run mongo
pip install docker-compose
docker-compose -f docker/dependencies.yml up -d


# start the canary workers
COUNTER=0
while [ $COUNTER -lt $WORKERS ]; do
  exec canary-worker > /dev/null 2>&1 &
  echo "canary-worker spawned."
  let COUNTER=COUNTER+1 
done


# start the canary producer
exec canary-producer > /dev/null 2>&1 &

# run the dashboard
export MONGO_URL=mongodb://dockerhost:27017/canary
cd dashboard
exec meteor > /dev/null 2>&1 &
echo "canary-dashboard started."

