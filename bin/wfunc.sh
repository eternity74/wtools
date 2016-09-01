#/bin/bash
export WTOOLS_ROOT=$(cd `dirname "${BASH_SOURCE[0]}"` && git rev-parse --show-toplevel)
export WTOOLS_CACHE=$WTOOLS_ROOT/.cache
source $WTOOLS_ROOT/bin/acd_func.sh
$WTOOLS_ROOT/bin/clean_viminfo
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
    if [[ "$1" == "-" && -n "$aroot_prev" ]];then
        gotodir "vendor/lge/external/$aroot_prev/src"
        return
    fi
    local old=$(shopt -p nullglob)
    shopt -s nullglob
    aroot_dirs=( $(get_android_root_with_cache)/vendor/lge/external/chromium*/src )
    aroot_dirs2=( ${aroot_dirs[@]//\/src/} )
    eval "$old"
    if [[ ${#aroot_dirs2[@]} -eq 0 ]]; then
        gotodir "vendor/lge/apps/ACE/src"
        return
    elif [[ ${#aroot_dirs2[@]} -le 1 ]]; then
        gotodir "vendor/lge/external/${aroot_dirs2[0]//*\//}/src"
        return
    fi
    select opt in ${aroot_dirs2[@]//*\//};do
        aroot_prev=$opt
        gotodir "vendor/lge/external/$opt/src"
        return
    done
}

# goto browser root
function broot {
    if [ -d "$(get_android_root_with_cache)/vendor/lge/apps/Browser4_KLP" ]; then
        gotodir "vendor/lge/apps/Browser4_KLP"
    elif [ -d "$(get_android_root_with_cache)/vendor/lge/apps/LGBrowser" ]; then
        gotodir "vendor/lge/apps/LGBrowser"
    fi
}

# goto android root
function croot {
    gotodir "."
}

# goto ACE build output
function droot {
    gotodir "out*/target/product/*/obj/ACE/build_intermediates/out/Release*/"
}

function get_android_root_with_cache {
    android_root=$(get_android_root)
    cache_file=$WTOOLS_CACHE/working_android_root
    if [[ $WTOOLS_CACHED_ANDROID_ROOT == "" && -f $cache_file ]]; then
        WTOOLS_CACHED_ANDROID_ROOT=$(cat $cache_file)
    fi
    if [[ $android_root == "/" ]]
    then
        echo $WTOOLS_CACHED_ANDROID_ROOT
    else
        echo $android_root
    fi
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
    if [[ -d $cwd"/android" && -d $cwd"/android/vendor" ]]; then
        echo $cwd/android
        return 0
    fi
    while [ "$cwd" != '/' ]
    do
        if [[ $(basename $cwd) = 'android' && -d $cwd"/vendor" ]]
        then
            break
        fi
        cwd=$(dirname $cwd)
    done

    echo $cwd
}
