#!/bin/bash
bias=0
dist=1
widt=1
suff=
disp_path=0

usage () {
    echo "Usage: $0 [OPTIONS]"
    echo "Usage: $0 [WALK OPTIONS] -- [HIST OPTIONS]"
    echo "  ADDITIONAL OPTIONS:"
    echo "    -S suffix    suffix/variant for the filename/output,"
    echo "                 useful for concurrent runs of a given job"
    echo "    -P           display generated path and exit"
    echo
    echo "  - Otherwise options same as for ./walk"
    echo "  - -2v is added to options automatically"
    echo "  - Output filenames will be generated from"
    echo "    the supplied bias and supplied to ./walk"
    echo "  - The second form is used to generate histogram"
    echo "    data via ./distribution.py"
    echo
    ./walk -h
    echo
    ./distribution.py -h
}

argv=()
options () {
    while getopts ":b:d:w:S:hP" o; do
        case "${o}" in
            b)
                bias="${OPTARG}"
                argv+=(-b "$bias")
                ;;
            d)
                dist="${OPTARG}"
                argv+=(-d "$dist")
                ;;
            w)
                widt="${OPTARG}"
                argv+=(-w "$widt")
                ;;
            S)
                suff="-${OPTARG}"
                ;;
            h)
                usage 1>&2
                exit 1
                ;;
            \?|:)
                argv+=("-${OPTARG}")
                ;;
            P)
                disp_path=1
                ;;
        esac
    done
}

options "$@"
while [ "$OPTIND" -le "$#" ]; do
    # keep processing arguments after unexpected options...

    # check if stopped because of '--'
    optprev=$((OPTIND-1))
    if [ "${!optprev}" = "--" ]; then
        argh=("${@:$OPTIND:$#}")
        break
    fi

    argv+=("${!OPTIND}")
    OPTIND+=1
    options "$@"
done

dir="./jobs"
file="2d-$bias-$widt-$dist$suff"
log="$dir/$file.log"
csv="$dir/$file.csv"
dat="$dir/$file.dat"
hst="$dir/$file.dist"

mkdir -p "$dir"
if [ "$disp_path" -eq "1" ]; then
    echo "$dir/$file"
    exit 0
fi

argv+=(-2 -v)
argv+=(-p "$dat")
argv+=(-q "$csv")

if [ -z "${argh+x}" ]; then
    # first usage, regular mfpt job
    # run and catch errors and signals properly...

    _sig() { 
      kill -TERM "$child"
    }

    spin() {
        wait "$child" || spin
    }

    trap _sig SIGINT SIGTERM
    trap spin EXIT

    echo "#" "$0" "$@" >> "$log"
    echo "#" ./walk "${argv[@]}" >> "$log"
    ./walk "${argv[@]}" > >(tee -a "$log") 2>&1 &
    child=$!

else
    # second usage, generate distribution/histogram data
    # no need to catch signals differently here...

    argv+=(-r)
    ./walk "${argv[@]}" | ./distribution.py "${argh[@]}" -- "$hst"

fi