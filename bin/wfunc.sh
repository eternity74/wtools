#/bin/bash
WTOOLS_ROOT=$(cd `dirname "${BASH_SOURCE[0]}"` && git rev-parse --show-toplevel)
WTOOLS_CACHE=$WTOOLS_ROOT/.cache
if [[ ! -d $WTOOLS_CACHE ]]
then
    mkdir $WTOOLS_CACHE
    echo $WTOOLS_CACHE created
fi

WTOOLS_CACHED_ANDROID_ROOT=

# keep updating wtools within a week
WTOOLS_ROOT=$WTOOLS_ROOT WTOOLS_CACHE=$WTOOLS_CACHE $WTOOLS_ROOT/update

# goto ace34 root
function aroot {
    gotodir "vendor/lge/external/chromium34_lge/src"
}

# goto browser root
function broot {
    gotodir "vendor/lge/apps/Browser4_KLP"
}

# goto android root
function croot {
    gotodir "."
}

function gotodir {
    android_root=$(get_android_root)
    target_dir=$1
    cache_file=$WTOOLS_CACHE/working_android_root
    if [[ $WTOOLS_CACHED_ANDROID_ROOT == "" && -f $cache_file ]]; then
        WTOOLS_CACHED_ANDROID_ROOT=$(cat $cache_file)
    fi
    if [[ $android_root == "/" ]]
    then
        if [[ "$WTOOLS_CACHED_ANDROID_ROOT" != "" ]]; then
            cd $WTOOLS_CACHED_ANDROID_ROOT/$target_dir
        fi
    else
        WTOOLS_CACHED_ANDROID_ROOT=$android_root
        full_dir=$WTOOLS_CACHED_ANDROID_ROOT/$target_dir
        cd $full_dir
        if [[ "$(cat $cache_file)" != "$WTOOLS_CACHED_ANDROID_ROOT" ]]; then
            echo $WTOOLS_CACHED_ANDROID_ROOT > $cache_file
       fi
    fi
}

function get_android_root {
    cwd=$(pwd)
    if [[ -d $cwd"/android" && -d $cwd"/android/dalvik" ]]; then
        echo $cwd/android
        return 0
    fi
    while [ "$cwd" != '/' ]
    do
        if [[ $(basename $cwd)=='android' && -d $cwd"/dalvik" ]]
        then
            break
        fi
        cwd=$(dirname $cwd)
    done

    echo $cwd
}
