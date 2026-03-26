# Documentation Technique — Infrastructure Média (JEL / FILM)

**Date :** 2026-03-25  
**Rédigé par :** Ulysse Prevost Lacaze
**Projet :** Serveur de téléchargement et stockage NFS pour films et musique

---

## Table des matières

1. [Architecture générale](#1-architecture-générale)
2. [Configuration VirtualBox](#2-configuration-virtualbox)
3. [Installation des VM Ubuntu Server](#3-installation-des-vm-ubuntu-server)
3. [Configuration SSH](#3-configuration-ssh)
4. [Mise en place du stockage NFS — VM `film`](#4-mise-en-place-du-stockage-nfs--vm-film)
5. [Configuration du client NFS — VM `jel`](#5-configuration-du-client-nfs--vm-jel)
6. [Installation des dépendances de téléchargement — VM `jel`](#6-installation-des-dépendances-de-téléchargement--vm-jel)
7. [Installation de Docker & Docker Compose](#7-installation-de-docker--docker-compose)
8. [Scripts](#8-scripts)
9. [Versions des outils](#9-versions-des-outils)

---

## 1. Architecture générale

| VM | Rôle | IP |
|----|------|----|
| `jel` | Serveur principal (téléchargement, Docker) | 192.168.177.5 |
| `film` | Serveur de stockage (NFS) | 192.168.177.6 |

Les répertoires `/home/film/films` et `/home/film/musique` sur `film` sont exportés via NFS et montés sur `jel`.

---

## 2. Configuration VirtualBox

### 2.1 Ressources matérielles (identiques sur les deux VM)

| Paramètre | Valeur |
|-----------|--------|
| RAM | 4096 Mo (4 Go) |
| CPU | 4 vCPUs |
| EFI | Désactivé |

### 2.2 Stockage

| VM | Fichier disque | Taille | Type |
|----|---------------|--------|------|
| `jel` (Jellyfin) | `PROJET FIL ROUGE VM JELLYFIN.vdi` | 25,00 Gio | Normal |
| `film` (Stockage) | `PROJET FIL ROUGE SOTKAGE DE FILME.vdi` | 25,00 Gio | Normal |

> Contrôleur : **SATA** — Port SATA 0  
> Lecteur optique IDE : Vide

### 2.3 Réseau

Les deux VM sont configurées avec **deux adaptateurs réseau** :

| Adaptateur | Mode | Détail |
|------------|------|--------|
| Adapter 1 | NAT | Accès Internet — Intel PRO/1000 MT Desktop (82540EM) |
| Adapter 2 | Réseau privé hôte | Communication inter-VM — VirtualBox Host-Only Ethernet Adapter #3 |

> L'adaptateur 2 en **réseau privé hôte** permet la communication directe entre `jel` et `film` (nécessaire pour le NFS), sans passer par Internet.

---

## 3. Installation des VM Ubuntu Server

Les deux VM (`jel` et `film`) ont été installées avec **Ubuntu Server**.

Après l'installation, mise à jour des paquets sur **chacune des deux VM** :

```bash
sudo apt update
sudo apt upgrade
```

---

## 3. Configuration SSH

Effectué sur **les deux VM** (`jel` et `film`) :

```bash
# Installation du serveur SSH
sudo apt install openssh-server

# Activation et démarrage du service
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

## 4. Mise en place du stockage NFS — VM `film`

### 4.1 Installation du serveur NFS

```bash
sudo apt-get install nfs-kernel-server

# Activation du service
sudo systemctl enable nfs-server.service
```

### 4.2 Création des répertoires et permissions

```bash
# Permissions sur les dossiers partagés
sudo chmod 755 films
sudo chmod 775 musique
```

### 4.3 Configuration des exports NFS

Fichier `/etc/exports` :

```
/home/film/musique  192.168.177.5(rw,sync,no_subtree_check,no_root_squash)
/home/film/films    192.168.177.5(rw,sync,no_subtree_check,no_root_squash)
```

> **Paramètres NFS :**
> - `rw` — lecture et écriture
> - `sync` — écriture synchrone (plus sûr)
> - `no_subtree_check` — désactive la vérification de sous-arborescence (performances)
> - `no_root_squash` — le root du client conserve ses droits root sur le partage

Après modification du fichier, appliquer les exports :

```bash
sudo exportfs -ra
```

---

## 5. Configuration du client NFS — VM `jel`

### 5.1 Installation du client NFS

```bash
sudo apt-get install nfs-common
```

### 5.2 Création des points de montage

```bash
mkdir ~/films
mkdir ~/musique
mkdir ~/script
```

---

## 6. Installation des dépendances de téléchargement — VM `jel`

### 6.1 Node.js

```bash
sudo apt install nodejs
sudo apt install npm
```

Version installée :

```
v18.19.1
```

### 6.2 FFmpeg

```bash
sudo apt install ffmpeg
```

Version installée :

```
ffmpeg version 6.1.1-3ubuntu5
```

### 6.3 yt-dlp

```bash
sudo apt install yt-dlp

# Mise à jour vers la dernière version
yt-dlp -U
```

---

## 7. Installation de Docker & Docker Compose

### 7.1 Suppression des anciennes versions

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 \
  docker-doc podman-docker containerd runc | cut -f1)
```

### 7.2 Fichier `docker-compose.yml`

> *(Voir fichier `docker-compose.yml` joint au projet)*

### 7.3 Démarrage des services Docker

```bash
sudo docker compose up -d
```

---

## 8. Scripts

Les scripts suivants ont été créés dans `~/script/` sur la VM `jel` :

```bash
touch fil_et_music.sh       # Script de téléchargement
touch monitor_service.sh    # Monitoring des services
touch monitor_upgrade.sh    # Monitoring des mises à jour
touch monitor_vm.sh         # Monitoring des VM
```

| Script | Rôle |
|--------|------|
| `fil_et_music.sh` | Téléchargement de films et musique via yt-dlp |
| `monitor_service.sh` | Surveillance de l'état des services |
| `monitor_vm.sh` | Surveillance des ressources des VM (CPU, RAM, disque) |
| `monitor_upgrade.sh` | Vérification des mises à jour disponibles |

> *(Voir les fichiers scripts joints pour le détail des implémentations)*

---

## 9. Versions des outils

| Outil | Version |
|-------|---------|
| Ubuntu Server | *(à préciser)* |
| Node.js | 18.19.1 |
| FFmpeg | 6.1.1-3ubuntu5 |
| yt-dlp | *(version après `yt-dlp -U`)* |
| Docker Compose | *(à préciser)* |

---
