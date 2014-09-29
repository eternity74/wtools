#/bin/bash
if [[ ! -d ~/.wtools ]]
then
    mkdir ~/.wtools
    echo ~/.wtools created
fi
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
    cache_file=~/.wtools/working_android_root
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
