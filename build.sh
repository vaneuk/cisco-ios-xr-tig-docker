#!/usr/bin/env bash

export TELEGRAF_CONFIG="`pwd`/etc/telegraf"
export GRAFANA_CONFIG="`pwd`/etc/grafana"
export INFLUXDB_CONFIG="`pwd`/etc/influxdb"
export INFLUXDB_ENGINE="`pwd`/influxdb"

export TELEGRAF_IMAGE="telegraf:latest"
export INFLUXDB_IMAGE="influxdb:latest"
export GRAFANA_IMAGE="grafana/grafana:latest"

export INFLUXDB_USER="admin"
export INFLUXDB_PASSWD="cisco!123"
export INFLUXDB_ORG="cisco"
export INFLUXDB_BUCKET="cisco_mdt_bucket"

export GRAFANA_ADMIN_USER="admin"
export GRAFANA_ADMIN_PASSWD="cisco!123"
export INFLUXDB_INIT_TOKEN="MySecretToken"

self=$0

function log() {
    ts=`date '+%Y-%m-%dT%H:%M:%S'`
    echo "$ts--LOG--$@"
}

function join_by {
    local d=$1
    shift
    echo -n "$1"
    shift
    printf "%s" "${@/#/$d}"
}

function clean() {
    # clean database of influxdb and volume of grafana
    log "cleaning influxdb database"
    rm -rf $INFLUXDB_ENGINE
    rm -rf $INFLUXDB_CONFIG/influx-configs

    log "remove generated telegraf config"
    rm -rf $TELEGRAF_CONFIG/telegraf.conf

    # log "deleting grafana volume $CHRONOGRAF_VOLUME"
    log "deleting grafana volume"
    docker volume rm cisco-ios-xr-tig-docker_grafana-volume
}

function prepare_telegraf() {
    log "prepare telegraf"

    # modify token of telegraf.conf
    if [ ! -e $TELEGRAF_CONFIG/telegraf.conf ]; then
        sed -e "s/^  token\ =.*/  token\ = \"$INFLUXDB_INIT_TOKEN\"/" \
            -e "s/^  bucket\ =.*/  bucket\ = \"$INFLUXDB_BUCKET\"/" \
        $TELEGRAF_CONFIG/telegraf.conf.example > $TELEGRAF_CONFIG/telegraf.conf
    fi
}

function check_influxdb () {
    # check if influxdb is ready for connection
    log "waiting for influxdb getting ready"
    while true; do
        result=`curl --noproxy '*' -w %{http_code} --silent --output /dev/null http://localhost:8086/api/v2/setup`
        if [ $result -eq 200 ]; then
            log "influxdb is online!"
            break
        fi
        sleep 3
    done
}

function setup_influxdb() {
    # initalize infludb
    result=`curl --silent http://localhost:8086/api/v2/setup`
    if [[ $result == *'true'* ]]; then
        log "influxbd is not initialized, setup influxdb"
        docker exec -t influxdb influx setup \
            --org $INFLUXDB_ORG\
            --bucket $INFLUXDB_BUCKET\
            --username $INFLUXDB_USER\
            --password $INFLUXDB_PASSWD\
            --token $INFLUXDB_INIT_TOKEN\
            --retention 2h \
            --force
    fi
}

function start() {
    docker --version >/dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        log "docker is not installed, exist"
        exit 1
    fi
    prepare_telegraf
    log "starting docker containers"
    docker-compose up -d
    check_influxdb
    setup_influxdb
}

function stop () {
    log "stopping docker containers"
    docker-compose stop
}

function down () {
    log "stopping and cleaning docker containers"
    docker-compose down
}

function reset () {
    # reset project to initial state
    down
    clean
}

function restart_svc () {
    if [ $# -eq 0 ]; then
        stop
        start
        exit 0
    fi
    case "$1" in
        telegraf)
            docker-compose restart telegraf
            ;;
        influxdb)
            docker-compose restart influxdb
            ;;
        grafana)
            docker-compose restart grafana
            ;;
        *)
            display_help
            exit 1
    esac
}

function display_help() {
    echo "Usage: $self {start|stop|restart|cert|clean}"
    echo "  start  :   start docker containers for telegraf/influxdb/grafana"
    echo "  stop   :   stop docker containers for telegraf/influxdb/grafana"
    echo "  down   :   stop and remove docker containers for telegraf/influxdb/grafana"
    echo "  restart:   restart docker containers for telegraf/influxdb/grafana"
    echo "  clean  :   clean the database of influxdb, volume of grafana"
    echo "  reset  :   reset project to inital state"
}


case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    down)
        down
        ;;
    restart)
        restart_svc $2
        ;;
    clean)
        clean
        ;;
    reset)
        reset
        ;;
    *)
        display_help
        exit 1
    esac
