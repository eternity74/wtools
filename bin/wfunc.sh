#/bin/bash
if [[ ! -d ~/.wtools ]]
then
    mkdir ~/.wtools
    echo ~/.wtools created
fi
function aroot {
    ace_root=$(get_android_root)
    if [[ $ace_root == "/" && -f ~/.wtools/ace_root_cache ]]
    then
        cd $(cat ~/.wtools/ace_root_cache)
    elif [[ $ace_root != "/" ]]
    then
        ace_root=$ace_root"/vendor/lge/external/chromium34_lge/src"
        cd $ace_root
        echo $ace_root > ~/.wtools/ace_root_cache
    fi
}
function get_android_root {
    cwd=$(pwd)
    while [ "$cwd" != '/' ]
    do
        cwd=$(dirname $cwd)
        if [[ $(basename $cwd)=='android' && -d $cwd"/dalvik" ]]
        then
            break
        fi
    done

    echo $cwd
}
