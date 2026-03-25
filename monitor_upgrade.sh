#!/bin/bash

# 1. Chargement du .env
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

if [ -z "$UPGRADE" ]; then
    echo "Erreur : La variable UPGRADE n'est pas définie dans le .env" >> "$SCRIPT_DIR/nohup.out"
    exit 1
fi

LOG_FILE="/var/log/apt/history.log"

echo "Surveillance active (silencieuse)..."

while true; do
    # On récupère le bloc de la dernière transaction
    LAST_BLOCK=$(tac $LOG_FILE | sed -n '/End-Date:/,/Start-Date:/p' | head -n 30)

    if echo "$LAST_BLOCK" | grep -q "Commandline: apt.*upgrade"; then

        # Extraction et nettoyage des paquets
        PACKAGES=$(echo "$LAST_BLOCK" | grep "Upgrade:" | sed 's/Upgrade: //')

        if [ ! -z "$PACKAGES" ]; then
            # Formatage propre : un paquet par ligne, max 1500 chars
            CLEAN_LIST=$(echo "$PACKAGES" | sed 's/), /)\n/g' | head -c 1500)

            # Date et Hostname
            NOW=$(date '+%d/%m/%Y à %H:%M:%S')
            HOST=$(hostname)

            # Construction sécurisée du JSON pour éviter l'erreur 50109
            # On utilise printf pour échapper les caractères spéciaux
            PAYLOAD=$(cat <<EOF
{
  "content": "🚀 **MAJ Détectée sur $HOST** le $NOW\n\n**Détails des paquets :**\n\`\`\`\n$CLEAN_LIST\n\`\`\`"
}
EOF
)

            # Envoi silencieux (-s)
            curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$UPGRADE" > /dev/null

            # Pause pour éviter le spam
            sleep 120
        fi
    fi

    sleep 15
done