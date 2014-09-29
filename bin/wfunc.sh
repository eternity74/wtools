#/bin/bash
WTOOLS_ROOT=$(git rev-parse --show-toplevel)
WTOOLS_CACHE=$WTOOLS_ROOT/.cache
if [[ ! -d $WTOOLS_CACHE ]]
then
    mkdir $WTOOLS_CACHE
    echo $WTOOLS_CACHE created
fi

# keep updating wtools within a week
WTOOLS_ROOT=$WTOOLS_ROOT WTOOLS_CACHE=$WTOOLS_CACHE $WTOOLS_ROOT/update


function aroot {
    gotodir "vendor/lge/external/chromium34_lge/src"
}
function broot {
    gotodir "vendor/lge/apps/Browser4_KLP"
}
function croot {
    gotodir "."
}

function gotodir {
    android_root=$(get_android_root)
    target_dir=$1
    cache_file=$WTOOLS_CACHE/working_android_root
    if [[ $android_root == "/" && -f $cache_file ]]
    then
        cd $(cat $cache_file)/$target_dir
    elif [[ $android_root != "/" ]]
    then
        full_dir=$android_root/$target_dir
        cd $full_dir
        echo $android_root > $cache_file
    fi
}

function get_android_root {
    cwd=$(pwd)
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
