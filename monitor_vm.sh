#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)

# IPs à surveiller
declare -A HOSTS
HOSTS["Serveur JEL"]="192.168.177.5"
HOSTS["Stockage Films"]="192.168.177.6"

# États initiaux RÉELS
declare -A LAST_STATUS
for NAME in "${!HOSTS[@]}"; do
    IP="${HOSTS[$NAME]}"
    if ping -c 1 -W 2 "$IP" &>/dev/null; then
        LAST_STATUS[$NAME]="up"
    else
        LAST_STATUS[$NAME]="down"
    fi
done

check_host() {
    local name=$1
    local ip=$2
    local last_status=$3

    if ping -c 1 -W 2 "$ip" &>/dev/null; then
        current_status="up"
    else
        current_status="down"
    fi

    if [ "$current_status" != "$last_status" ]; then
        if [ "$current_status" = "up" ]; then
            EMOJI="✅"; ETAT="est EN LIGNE"; COLOR="65280"
        else
            EMOJI="🚨"; ETAT="est HORS LIGNE"; COLOR="16711680"
        fi

        PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "$EMOJI VM : $name",
    "description": "La machine **$name** ($ip) $ETAT.",
    "color": $COLOR,
    "footer": { "text": "$(TZ='Europe/Paris' date '+%d/%m/%Y à %H:%M:%S')" }
  }]
}
EOF
)
        curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$UP_OR_DOWN" > /dev/null
        echo "$current_status"
    else
        echo "$last_status"
    fi
}

echo "Monitoring VM lancé pour Serveur JEL et Stockage Films..."
while true; do
    for NAME in "${!HOSTS[@]}"; do
        LAST_STATUS[$NAME]=$(check_host "$NAME" "${HOSTS[$NAME]}" "${LAST_STATUS[$NAME]}")
    done
    sleep 15
done