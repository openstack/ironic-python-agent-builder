
#NOTE(pas-ha)
# The first URL is the official TC repo,
# the rest of the list is taken from
# http://wiki.tinycorelinux.net/wiki:mirrors
# as of time of this writing.
# Only HTTP mirrors were considered with the following ordering
# - those that were unavailable are moved to the bottom of the list
# - those that already responded with 404 are moved to the very bottom

# List Updated on 9-Dec-2019
TC_MIRRORS="http://repo.tinycorelinux.net
http://mirror.cedia.org.ec/tinycorelinux
http://mirror.epn.edu.ec/tinycorelinux
http://ftp.vim.org/os/Linux/distr/tinycorelinux
http://mirrors.163.com/tinycorelinux
"

TINYCORE_MIRROR_URL=${TINYCORE_MIRROR_URL:-}

# NOTE(TheJulia): Removed mirrors because they are out
# of date
# http://distro.ibiblio.org/tinycorelinux ~1.5 months out of sync.
# http://mirrors.163.com/tinycorelinux - Two weeks out of date
# ftp.vim.org and ftp.nluug.nl are the same host.
# http://www.gtlib.gatech.edu/pub/tinycore - No longer mirrors tinycore
# http://l4u-00.ninr.ru no longer mirrors.
# http://kambing.ui.ac.id/tinycorelinux - Stopped mirroring at 9.x
# http://tinycore.mirror.uber.com.au - Unreachable?
function probe_url {
    wget -q --spider --tries 1 --timeout 10 "$1" 2>&1
}

function choose_tc_mirror {
    if [ -z ${TINYCORE_MIRROR_URL} ]; then
        for url in ${TC_MIRRORS}; do
            echo "Checking Tiny Core Linux mirror ${url}"
            if probe_url ${url} ; then
                echo "Check succeeded: ${url} is responding."
                TINYCORE_MIRROR_URL=${url}
                break
            else
                echo "Check failed: ${url} is not responding"
            fi
        done
        if [ -z ${TINYCORE_MIRROR_URL} ]; then
            echo "Failed to find working Tiny Core Linux mirror"
            exit 1
        fi
    else
        echo "Probing provided Tiny Core Linux mirror ${TINYCORE_MIRROR_URL}"
        if probe_url ${TINYCORE_MIRROR_URL} ; then
            echo "Check succeeded: ${TINYCORE_MIRROR_URL} is responding."
        else
            echo "Check failed: ${TINYCORE_MIRROR_URL} is not responding"
            exit 1
        fi
    fi
}
