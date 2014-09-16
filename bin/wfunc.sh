#/bin/bash
if [[ ! -d ~/.wtools ]]
then
    mkdir ~/.wtools
    echo ~/.wtools created
fi
function aroot {
    gotodir "vendor/lge/external/chromium34_lge/src" "ace_root_cache"
}
function broot {
    gotodir "vendor/lge/apps/Browser4_KLP" "browser_root_cache"
}

function gotodir {
    android_root=$(get_android_root)
    target_dir=$1
    cache_file=~/.wtools/$2
    if [[ $android_root == "/" && -f $cache_file ]]
    then
        cd $(cat $cache_file)
    elif [[ $android_root != "/" ]]
    then
        full_dir=$android_root/$target_dir
        cd $full_dir
        echo $full_dir > $cache_file
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
