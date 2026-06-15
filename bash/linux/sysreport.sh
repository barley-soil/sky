#!/usr/bin/env bash
# sysreport — colorful system status report
# Usage: sysreport [--save [file]]
set -euo pipefail

B='\033[1m' D='\033[2m' R='\033[0m'
RED='\033[31m' GRN='\033[32m' YLW='\033[33m' CYN='\033[36m'

header() { echo ""; echo -e "${B}${CYN}$1${R}"; echo ""; }

# --save: capture raw terminal output to file (script(1) fakes a TTY so colors are emitted)
if [[ "${1:-}" == "--save" ]]; then
    out="${2:-sysreport-$(date +%Y%m%d-%H%M%S).log}"
    script -qfec "SYSREPORT_INNER=1 $0" "$out" >/dev/null 2>&1
    # Strip script(1) header/footer and carriage returns
    sed -i -e '1{/^Script started/d}' -e '${/^Script done/d}' -e 's/\r//g' "$out"
    echo -e "Saved: ${B}$out${R}"
    echo -e "  ${D}less -R $out${R}  — view in terminal"
    echo -e "  ${D}subl $out${R}      — view in Sublime (auto-renders)"
    exit 0
fi
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { echo "Usage: sysreport [--save [file]]"; exit 0; }

# ── 1. SYSTEM INFO ──────────────────────────────────────────────────────────
header "SYSTEM INFO"
fastfetch --pipe false 2>/dev/null || echo "  (fastfetch not found)"

# ── 2. NETWORK SERVICES ─────────────────────────────────────────────────────
header "NETWORK SERVICES"

classify_addr() {
    case "$1" in
        127.0.0.1|::1|\[::1\])       echo "localhost only" ;;
        192.168.122.*|*virbr*)        echo "libvirt VMs only" ;;
        172.17.*|*docker*)            echo "docker only" ;;
        100.*)                        echo "tailscale only" ;;
        fd7a:*|*tailscale*)           echo "tailscale only" ;;
        0.0.0.0|\*|\[::\]|::|"")     echo "all interfaces" ;;
        fe80:*|ff02:*)               echo "link-local" ;;
        *)                            echo "$1" ;;
    esac
}

# Collect all listeners, deduplicate by port, pick most-exposed bind addr per port
declare -A PORT_PROC=() PORT_ADDR=() PORT_PROTO=()
parse_ss() {
    local proto=$1
    while IFS= read -r line; do
        [[ "$line" =~ ^State ]] && continue
        [[ -z "$line" ]] && continue
        local_addr=$(echo "$line" | awk '{print $4}')
        port="${local_addr##*:}"
        addr="${local_addr%:*}"
        # strip brackets from ipv6
        addr="${addr#\[}" ; addr="${addr%\]}"
        proc=""
        [[ "$line" =~ users:\(\(\"([^\"]+)\" ]] && proc="${BASH_REMATCH[1]}"

        # keep the most-exposed address per port (prefer 0.0.0.0 over 127.0.0.1)
        if [[ -z "${PORT_PROC[$port]:-}" ]]; then
            PORT_PROC[$port]="$proc"
            PORT_ADDR[$port]="$addr"
            PORT_PROTO[$port]="$proto"
        elif [[ "$addr" == "0.0.0.0" || "$addr" == "*" || "$addr" == "::" ]]; then
            PORT_ADDR[$port]="$addr"
            [[ -n "$proc" ]] && PORT_PROC[$port]="$proc"
        fi
    done < <(ss -"${proto}lnp" 2>/dev/null)
}
parse_ss t
parse_ss u

# Sort ports numerically, describe each
for port in $(echo "${!PORT_PROC[@]}" | tr ' ' '\n' | sort -n); do
    proc="${PORT_PROC[$port]}"
    addr="${PORT_ADDR[$port]}"
    proto="${PORT_PROTO[$port]}"
    scope=$(classify_addr "$addr")

    case "$port" in
        22)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}SSH${R}  ${D}[$scope]${R}"
            echo "  Remote shell access. Authenticates via password or public key."
            ;;
        53)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}DNS (dnsmasq)${R}  ${D}[$scope]${R}"
            echo "  DNS resolver for libvirt VMs on virbr0. Not exposed to LAN."
            ;;
        67)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}DHCP (dnsmasq)${R}  ${D}[$scope]${R}"
            echo "  DHCP for libvirt VMs on virbr0. Not exposed to LAN."
            ;;
        111)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}rpcbind${R}  ${D}[$scope]${R}"
            echo "  RPC port mapper. Required by NFS for service port discovery."
            ;;
        137)
            echo -e "  ${B}${YLW}Port $port${R}/udp — ${B}NetBIOS Name (nmbd)${R}  ${D}[$scope]${R}"
            echo "  NetBIOS name resolution. Allows Windows hosts to discover this machine."
            ;;
        138)
            echo -e "  ${B}${YLW}Port $port${R}/udp — ${B}NetBIOS Datagram (nmbd)${R}  ${D}[$scope]${R}"
            echo "  NetBIOS datagram distribution. Used for Windows network browsing."
            ;;
        139)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}NetBIOS Session (smbd)${R}  ${D}[$scope]${R}"
            echo "  Legacy SMB over NetBIOS. Used by pre-Vista Windows clients."
            ;;
        445)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}SMB (smbd)${R}  ${D}[$scope]${R}"
            echo "  SMB file sharing. Primary protocol for Windows network shares."
            ;;
        2049)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}NFS${R}  ${D}[$scope]${R}"
            echo "  Network File System. Exports:"
            grep -v '^#' /etc/exports 2>/dev/null | grep -v '^$' | while read -r line; do
                echo -e "    ${D}$line${R}"
            done
            ;;
        3389)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}RDP (xrdp)${R}  ${D}[$scope]${R}"
            echo "  Remote Desktop Protocol. Requires authentication."
            ;;
        3702)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}WS-Discovery (wsdd)${R}  ${D}[$scope]${R}"
            echo "  WS-Discovery multicast. Advertises this host to Windows Network."
            ;;
        4000)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}NoMachine (nxd)${R}  ${D}[$scope]${R}"
            echo "  NoMachine remote desktop. Requires NX authentication."
            ;;
        5353)
            echo -e "  ${B}${YLW}Port $port${R}/udp — ${B}mDNS${R}  ${D}[$scope]${R}"
            echo "  Multicast DNS (RFC 6762). Resolves .local hostnames on LAN."
            ;;
        5357)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}WS-Discovery HTTP (wsdd)${R}  ${D}[$scope]${R}"
            echo "  WS-Discovery HTTP responder. Serves device metadata to Windows clients."
            ;;
        9090)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}Cockpit${R}  ${D}[$scope]${R}"
            echo "  Web-based system administration console. Requires Linux login."
            ;;
        17500)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}Dropbox LAN Sync${R}  ${D}[$scope]${R}"
            echo "  Dropbox LAN sync discovery. Finds local clients for direct transfer."
            ;;
        17600|17603)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}Dropbox (internal)${R}  ${D}[$scope]${R}"
            echo "  Dropbox desktop client internals."
            ;;
        20048)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}NFS mountd${R}  ${D}[$scope]${R}"
            echo "  NFS mount daemon. Validates /etc/exports and issues file handles."
            ;;
        20543|22687)
            echo -e "  ${B}${YLW}Port $port${R} — ${B}NoMachine (nxserver)${R}  ${D}[$scope]${R}"
            echo "  Internal NoMachine server component."
            ;;
        *)
            [[ -z "$proc" || "$proc" == "rpc.statd" || "$proc" == "rpcbind" ]] && continue
            [[ "$proc" == "tailscaled" || "$proc" == "containerd" ]] && continue
            svc=$(awk -v p="$port" '$2 ~ "^"p"/" {print $1; exit}' /etc/services)
            label="${svc:+$svc ($proc)}"
            label="${label:-$proc}"
            echo -e "  ${B}${YLW}Port $port${R}/$proto — ${B}$label${R}  ${D}[$scope]${R}"
            ;;
    esac
    echo ""
done

if [[ $EUID -ne 0 ]]; then
    echo -e "  ${D}(run with sudo for full process details on all ports)${R}"
    echo ""
fi

# ── 3. GPU ───────────────────────────────────────────────────────────────────
header "GPU STATUS"
nvidia-smi 2>/dev/null || echo "  (nvidia-smi not found)"

# ── 4. THERMALS ──────────────────────────────────────────────────────────────
# Color each +XX.X°C value individually: green <70, yellow 70-84, red >=85
# If dim is set, non-temp text is dimmed (for threshold continuation lines)
colorize_temps() {
    local line="$1" dim="$2"
    local out="" seg="$line"
    while [[ "$seg" =~ (.*)\+([0-9]+)(\.[0-9]+°C)(.*) ]]; do
        local val="${BASH_REMATCH[2]}" trail="${BASH_REMATCH[4]}"
        local tc="$GRN"
        (( val >= 85 )) && tc="$RED" || { (( val >= 70 )) && tc="$YLW"; }
        [[ -n "$dim" ]] && trail="${D}${trail}${R}"
        out="${tc}+${BASH_REMATCH[2]}${BASH_REMATCH[3]}${R}${trail}${out}"
        seg="${BASH_REMATCH[1]}"
    done
    [[ -n "$dim" ]] && seg="${D}${seg}${R}"
    echo -e "  ${seg}${out}"
}

header "THERMALS"
if command -v sensors &>/dev/null; then
    sensors 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z].*-.*- ]]; then echo "  $line"; continue; fi
        if [[ "$line" =~ ^Adapter: ]]; then echo "  $line"; continue; fi
        if [[ "$line" =~ °C ]]; then
            [[ "$line" =~ ^[[:space:]]*(AUXTIN5|PCH_CHIP|PCH_CPU) ]] && continue
            if [[ "$line" =~ ^[[:space:]]*\( ]]; then
                colorize_temps "$line" dim
            else
                colorize_temps "$line" ""
            fi
            continue
        fi
        # Fan RPM lines (skip 0 RPM fans — disconnected/unused)
        if [[ "$line" =~ RPM ]]; then
            [[ "$line" =~ :\ +0\ RPM ]] || echo "  $line"
            continue
        fi
        # Blank separators between chips
        [[ -z "$line" ]] && echo "" && continue
    done
else
    echo "  (lm_sensors not installed)"
fi

# ── 5. STORAGE ───────────────────────────────────────────────────────────────
header "STORAGE"

lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null | while IFS= read -r line; do
    echo "  $line"
done

echo ""
df -h -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null | while IFS= read -r line; do
    if [[ "$line" =~ ([0-9]+)% ]]; then
        pct="${BASH_REMATCH[1]}"
        if (( pct >= 90 )); then   echo -e "  ${RED}$line${R}"
        elif (( pct >= 75 )); then echo -e "  ${YLW}$line${R}"
        else                       echo "  $line"
        fi
    else
        echo "  $line"
    fi
done

# Btrfs
btrfs_out=$(btrfs filesystem show 2>/dev/null) || true
if [[ -n "$btrfs_out" ]]; then
    echo ""
    echo -e "  ${B}Btrfs${R}"
    echo "$btrfs_out" | while IFS= read -r line; do
        if [[ "$line" =~ MISSING ]]; then
            echo -e "  ${RED}$line${R}"
        else
            echo "  $line"
        fi
    done
fi

# SMART health (one-liner per drive)
if command -v smartctl &>/dev/null; then
    echo ""
    echo -e "  ${B}SMART Health${R}"
    for dev in /dev/nvme?n1 /dev/sd?; do
        [[ -b "$dev" ]] || continue
        health=$(smartctl -H "$dev" 2>/dev/null | grep -iE "overall|result" | head -1) || true
        if [[ -n "$health" ]]; then
            if echo "$health" | grep -qi "passed\|ok"; then
                echo -e "  ${GRN}$dev: $health${R}"
            else
                echo -e "  ${RED}$dev: $health${R}"
            fi
        fi
    done
fi

# ── 6. NETWORK / TAILSCALE ──────────────────────────────────────────────────
header "NETWORK"

ip -br -c addr 2>/dev/null | while IFS= read -r line; do
    echo "  $line"
done

if command -v tailscale &>/dev/null; then
    echo ""
    echo -e "  ${B}Tailscale${R}"
    tailscale status 2>/dev/null | while IFS= read -r line; do
        if [[ "$line" =~ offline ]]; then   echo -e "  ${D}$line${R}"
        elif [[ "$line" =~ idle ]]; then    echo -e "  ${YLW}$line${R}"
        else                                echo -e "  ${GRN}$line${R}"
        fi
    done
fi

echo ""
echo -e "${D}  $(date '+%Y-%m-%d %H:%M:%S')${R}"
echo ""
