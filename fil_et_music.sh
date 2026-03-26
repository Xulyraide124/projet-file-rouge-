#!/bin/bash

# Configues des IP
VM_STOCKAGE="192.168.177.6"
# chois de l'option
echo "Menu : 1 pour Musique / 2 pour Film / N pour quitter"
read choix
# reponce du chois
case $choix in
# si 1 lancement de yt-dlp pour téléchargé la musique
    1)
        echo "Lancement téléchargement Musique..."
        yt-dlp -U
        mkdir -p ~/musique
        cd ~/musique
        read -p "Lien YouTube : " url
        # Télécharge en mp3 direct
        yt-dlp -x --audio-format mp3 "$url"
        # Envoi sur la VM2 et clean local
        scp *.mp3 film@$VM_STOCKAGE:/home/film/musique/ && rm *.mp3 #on fait via scp pas par samba
        echo "Musique envoyée sur le serveur de stockage."
        ;;
#on télécharge le film
    2)
        echo "Lancement téléchargement Film..."
        yt-dlp -U
        # On crée le dossier local demandé
        mkdir -p ~/film
        cd ~/film
        read -p "Lien de la vidéo : " url
        # On prend la meilleure qualité mp4
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" "$url"
        # Envoi vers le dossier films de la VM2
        scp *.mp4 film@$VM_STOCKAGE:/home/film/films/ && rm *.mp4
        echo "Film envoyé sur le serveur de stockage."
        ;;
    N)
        exit
        ;;
    # voici la 4 eme option qui dit  CHOISIE 1 OU 2
 *)
        echo "Choix non valide. tu doit choisir le 1 ou le 2."
        ;;
esac
