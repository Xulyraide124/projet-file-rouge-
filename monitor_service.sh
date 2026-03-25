#!/bin/bash
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)

# États initiaux RÉELS
LAST_STATUS_JELLYFIN=$(sudo docker inspect -f '{{.State.Status}}' "script-jellyfin-1" 2>/dev/null | tr -d '[:space:]')
LAST_STATUS_NAVIDROM=$(sudo docker inspect -f '{{.State.Status}}' "script-navidrome-1" 2>/dev/null | tr -d '[:space:]')

if [ -z "$LAST_STATUS_JELLYFIN" ]; then LAST_STATUS_JELLYFIN="down"; fi
if [ -z "$LAST_STATUS_NAVIDROM" ]; then LAST_STATUS_NAVIDROM="down"; fi

check_docker_service() {
    local container_name=$1
    local last_status=$2

    local current_status
    current_status=$(sudo docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null | tr -d '[:space:]')

    if [ -z "$current_status" ]; then current_status="down"; fi

    if [ "$current_status" != "$last_status" ]; then
        if [ "$current_status" = "running" ]; then
            EMOJI="✅"; ETAT="est EN LIGNE"; COLOR="65280"
        else
            EMOJI="🚨"; ETAT="est ARRÊTÉ ($current_status)"; COLOR="16711680"
        fi

        PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "$EMOJI Docker : $container_name",
    "description": "Le container **$container_name** $ETAT.",
    "color": $COLOR,
    "footer": { "text": "$(TZ='Europe/Paris' date '+%d/%m/%Y à %H:%M:%S')" }
  }]
}
EOF
)
        curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$SERVICE_UP_OR_NOT" > /dev/null
        echo "$current_status"
    else
        echo "$last_status"
    fi
}

echo "Monitoring Docker lancé pour Jellyfin et Navidrom..."
while true; do
    LAST_STATUS_JELLYFIN=$(check_docker_service "script-jellyfin-1" "$LAST_STATUS_JELLYFIN")
    LAST_STATUS_NAVIDROM=$(check_docker_service "script-navidrome-1" "$LAST_STATUS_NAVIDROM")
    sleep 15
done
