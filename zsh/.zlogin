#
#
# Below are my personal additions added on 24-08-2025
# Updated on 18-02-2026: improved memory parsing, os-release isolation,
# hardened fragmentation check, added load average and drive health
# Updated on 07-05-2026: TTY/TERM guard before ANSI; dpkg-query for OMV version;
# memory thresholds 80%/60%; consolidated zpool list calls; status -x via case;
# LOAD_1M precomputed (no echo|awk); removed dead DRIVE_ISSUES reference
#
# System information with colors for SSH logins
if { [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; } && [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
    # Define colors (portable way)
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
    
    # Get terminal width for adaptive display
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
    
    # Fixed labels (don't change with width)
    LABEL_OS="OS:"
    LABEL_KERNEL="Kernel:"
    LABEL_UPTIME="Uptime:"
    LABEL_MEMORY="Memory:"
    LABEL_LOAD="Load Avg:"
    
    # Adaptive labels and padding based on terminal width
    if [ "$TERM_WIDTH" -lt 50 ]; then
        LABEL_OMV="OMV:"
        PAD_WIDTH=8
        SHOW_GNU_LINUX=0  # Don't show GNU/Linux on narrow screens
    elif [ "$TERM_WIDTH" -lt 80 ]; then
        LABEL_OMV="OMV Version:"
        PAD_WIDTH=13
        SHOW_GNU_LINUX=0  # Don't show GNU/Linux on medium screens
    else
        LABEL_OMV="OMV Version:"
        PAD_WIDTH=16
        SHOW_GNU_LINUX=1  # Show full "GNU/Linux" on desktop
    fi
    
    # Gather the actual content to determine max width
    HOSTNAME_LINE=" System Information - $(hostname)"
    
    # Get OS line with adaptive Debian detection (in subshell to avoid leaking variables)
    OS_CONTENT=$(
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            RESULT="$PRETTY_NAME"
            if [ -f /etc/debian_version ] && [ "$ID" = "debian" ]; then
                DEB_VERSION=$(cat /etc/debian_version)
                if [ "$SHOW_GNU_LINUX" -eq 1 ]; then
                    RESULT="Debian GNU/Linux ${DEB_VERSION} (${VERSION_CODENAME})"
                else
                    RESULT="Debian ${DEB_VERSION} (${VERSION_CODENAME})"
                fi
            fi
            printf '%s' "$RESULT"
        else
            printf '%s' "Unknown OS"
        fi
    )
    
    # Get OMV version if present
    OMV_VERSION=""
    if [ -f /etc/openmediavault/config.xml ]; then
        OMV_VERSION=$(dpkg-query -W -f='${Version}' openmediavault 2>/dev/null)
    fi
    
    # Get memory info safely — calculate percentage from raw values,
    # then use human-readable values only for display
    MEM_INFO=""
    MEM_PERCENT=0
    if command -v free >/dev/null 2>&1; then
        MEM_PERCENT=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        MEM_INFO=$(free -h | awk -v pct="$MEM_PERCENT" 'NR==2{printf "%s/%s (%s%%)", $3, $2, pct}')
    fi
    
    # Get load average (1m, 5m, 15m); LOAD_1M used later for color thresholds
    LOAD_INFO=""
    LOAD_1M=""
    if [ -f /proc/loadavg ]; then
        LOAD_INFO=$(awk '{printf "%s %s %s", $1, $2, $3}' /proc/loadavg)
        LOAD_1M=${LOAD_INFO%% *}
    fi
    
    # Get other system info
    KERNEL_INFO=$(uname -r)
    UPTIME_INFO=$(uptime -p)
    
    # Calculate the maximum line length
    MAX_LEN=${#HOSTNAME_LINE}
    
    # Check all line lengths
    for content in "$OS_CONTENT" "$OMV_VERSION" "$KERNEL_INFO" "$UPTIME_INFO" "$MEM_INFO" "$LOAD_INFO"; do
        [ -z "$content" ] && continue
        LINE_LEN=$((PAD_WIDTH + ${#content}))
        [ $LINE_LEN -gt $MAX_LEN ] && MAX_LEN=$LINE_LEN
    done
    
    # Generate separator of appropriate length
    SEPARATOR_LEN=$((MAX_LEN + 2))
    [ $SEPARATOR_LEN -gt $TERM_WIDTH ] && SEPARATOR_LEN=$TERM_WIDTH
    SEPARATOR=$(printf '%*s' "$SEPARATOR_LEN" | tr ' ' '=')
    
    # Now display everything
    printf "${CYAN}%s${NC}\n" "$SEPARATOR"
    printf "${WHITE}%s${NC}\n" "$HOSTNAME_LINE"
    printf "${CYAN}%s${NC}\n" "$SEPARATOR"
    
    # OS
    printf "${GREEN}%-${PAD_WIDTH}s${NC}%s\n" "$LABEL_OS" "$OS_CONTENT"
    
    # OpenMediaVault version (only if present)
    [ -n "$OMV_VERSION" ] && printf "${GREEN}%-${PAD_WIDTH}s${NC}%s\n" "$LABEL_OMV" "$OMV_VERSION"
    
    # Kernel
    printf "${GREEN}%-${PAD_WIDTH}s${NC}%s\n" "$LABEL_KERNEL" "$KERNEL_INFO"
    
    # Uptime
    printf "${GREEN}%-${PAD_WIDTH}s${NC}%s\n" "$LABEL_UPTIME" "$UPTIME_INFO"
    
    # Memory (with color coding based on percentage)
    if [ -n "$MEM_INFO" ]; then
        if [ "$MEM_PERCENT" -ge 80 ]; then
            printf "${GREEN}%-${PAD_WIDTH}s${NC}${RED}%s${NC}\n" "$LABEL_MEMORY" "$MEM_INFO"
        elif [ "$MEM_PERCENT" -ge 60 ]; then
            printf "${GREEN}%-${PAD_WIDTH}s${NC}${YELLOW}%s${NC}\n" "$LABEL_MEMORY" "$MEM_INFO"
        else
            printf "${GREEN}%-${PAD_WIDTH}s${NC}%s\n" "$LABEL_MEMORY" "$MEM_INFO"
        fi
    fi
    
    # Load average (color coded: green < nproc, yellow < 2*nproc, red >= 2*nproc)
    if [ -n "$LOAD_INFO" ]; then
        NPROC=$(nproc 2>/dev/null || echo 1)
        # Compare using awk since load can be a float
        LOAD_STATUS=$(awk -v lavg="$LOAD_1M" -v cores="$NPROC" 'BEGIN {
            if (lavg >= cores * 2) print "red"
            else if (lavg >= cores) print "yellow"
            else print "green"
        }')
        if [ "$LOAD_STATUS" = "red" ]; then
            printf "${GREEN}%-${PAD_WIDTH}s${NC}${RED}%s${NC}\n" "$LABEL_LOAD" "$LOAD_INFO"
        elif [ "$LOAD_STATUS" = "yellow" ]; then
            printf "${GREEN}%-${PAD_WIDTH}s${NC}${YELLOW}%s${NC}\n" "$LABEL_LOAD" "$LOAD_INFO"
        else
            printf "${GREEN}%-${PAD_WIDTH}s${NC}%s\n" "$LABEL_LOAD" "$LOAD_INFO"
        fi
    fi
    
    printf "${CYAN}%s${NC}\n" "$SEPARATOR"
    echo ""
    
    # ZFS status with adaptive display (skip silently if no pools imported)
    if command -v zpool >/dev/null 2>&1 && [ -n "$(zpool list -H -o name 2>/dev/null)" ]; then
        printf "${BLUE}=== ZFS Pool Status ===${NC}\n"
        
        if [ "$TERM_WIDTH" -lt 100 ]; then
            # Narrow display (mobile-friendly vertical format)
            echo "---"
            zpool list -H -o name,health,size,alloc,free,cap,frag,expandsz,checkpoint | while IFS=$(printf '\t') read -r name health size alloc free cap frag expandsz checkpoint; do
                printf "${GREEN}Pool:${NC} %s\n" "$name"
                if [ "$health" = "ONLINE" ]; then
                    printf "  Health:  ${GREEN}%s${NC}\n" "$health"
                else
                    printf "  Health:  ${RED}%s${NC}\n" "$health"
                fi
                printf "  Size:    %s\n" "$size"
                printf "  Used:    %s (%s)\n" "$alloc" "$cap"
                printf "  Free:    %s\n" "$free"
                
                # Show fragmentation if not dash or 0%
                if [ -n "$frag" ] && [ "$frag" != "-" ] && [ "$frag" != "0%" ]; then
                    FRAG_NUM=$(echo "$frag" | sed 's/%//')
                    # Guard against non-numeric values
                    case "$FRAG_NUM" in
                        *[!0-9]*) FRAG_NUM=0 ;;
                    esac
                    if [ "$FRAG_NUM" -gt 50 ]; then
                        printf "  ${RED}Fragmentation: %s${NC}\n" "$frag"
                    elif [ "$FRAG_NUM" -gt 25 ]; then
                        printf "  ${YELLOW}Fragmentation: %s${NC}\n" "$frag"
                    else
                        printf "  Fragmentation: %s\n" "$frag"
                    fi
                fi
                
                # Check for expandable size
                if [ -n "$expandsz" ] && [ "$expandsz" != "-" ]; then
                    printf "  ${YELLOW}Expandable: %s${NC}\n" "$expandsz"
                fi
                
                # Check for checkpoint
                if [ -n "$checkpoint" ] && [ "$checkpoint" != "-" ]; then
                    printf "  ${YELLOW}Checkpoint: %s${NC}\n" "$checkpoint"
                fi
                echo "---"
            done
        else
            # Wide display (desktop) - show only columns with non-empty / non-zero values.
            # Single zpool call feeds awk, which emits the final column list.
            COLS=$(zpool list -H -o frag,expandsz,checkpoint,altroot | awk -F'\t' '
                $1 != "-" && $1 != "0%" { f=1 }
                $2 != "-"               { e=1 }
                $3 != "-"               { c=1 }
                $4 != "-"               { a=1 }
                END {
                    cols = "name,health,size,alloc,free,cap"
                    if (f) cols = cols ",frag"
                    if (e) cols = cols ",expandsz"
                    if (c) cols = cols ",checkpoint"
                    if (a) cols = cols ",altroot"
                    print cols
                }
            ')
            zpool list -o "$COLS"
        fi
        
        echo ""
        POOL_HEALTH=$(zpool status -x)
        case "$POOL_HEALTH" in
            "all pools are healthy")
                printf "${GREEN}Overall Status: %s${NC}\n" "$POOL_HEALTH"
                ;;
            *)
                printf "${RED}Pool Issues:${NC}\n%s\n" "$POOL_HEALTH"
                ;;
        esac
        printf "${BLUE}=======================${NC}\n"
        echo ""
    fi
    
    # Clean up color variables to avoid polluting the shell environment
    unset RED GREEN YELLOW BLUE CYAN WHITE NC
    unset TERM_WIDTH LABEL_OS LABEL_KERNEL LABEL_UPTIME LABEL_MEMORY LABEL_LOAD LABEL_OMV
    unset PAD_WIDTH SHOW_GNU_LINUX HOSTNAME_LINE OS_CONTENT OMV_VERSION
    unset MEM_INFO MEM_PERCENT LOAD_INFO LOAD_1M LOAD_STATUS NPROC
    unset KERNEL_INFO UPTIME_INFO MAX_LEN LINE_LEN SEPARATOR_LEN SEPARATOR
    unset POOL_HEALTH COLS
fi
