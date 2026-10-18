# DSXT — DayZ Server XML Tool

DSXT est un outil Bash permettant de gérer des blocs XML personnalisés dans les missions des serveurs DayZ.

[English version](README.md)

## Objectif

Après une mise à jour du jeu ou une modification de configuration, les administrateurs de serveurs DayZ peuvent avoir besoin de restaurer, mettre à jour, comparer ou réorganiser des entrées XML personnalisées. DSXT facilite ces opérations à l'aide de fragments XML préparés à l'avance.

L'outil peut également servir à appliquer une configuration XML spécifique pour un événement temporaire.

DSXT ne détecte **pas** automatiquement les mods installés et ne génère pas leur configuration XML. Les fragments doivent être préparés par l'administrateur.

## Fonctionnalités

- Ajouter ou remplacer des blocs XML personnalisés.
- Supprimer des blocs ciblés ou supprimer des blocs par TAG dans les fichiers XML de mission.
- Comparer les blocs personnalisés avec leurs fragments source.
- Lister et extraire des blocs personnalisés.
- Synchroniser les blocs à partir d'un fichier de référence.
- Valider les fichiers XML de mission.

## Prérequis

- Bash
- `xmllint` pour la validation XML
- Une mission de serveur DayZ contenant les fichiers XML à gérer

### Droits d'exécution

Exécutez DSXT avec le compte Linux propriétaire des fichiers et répertoires du serveur DayZ. Ne l'exécutez pas en tant que `root`, car cela pourrait entraîner des problèmes de propriété ou de permissions sur les fichiers.

## Installation

Placer `dsxt.sh` dans le répertoire contenant les répertoires des serveurs DayZ.

Créer un répertoire `dsxt/` dans chaque répertoire de serveur. Il contient les fragments XML et les fichiers de liste de synchronisation propres à ce serveur.

Exemple d'arborescence :

```text
/home/dayz/servers/
├── dsxt.sh
├── dayz-server-chernarus/
│   └── dsxt/
├── dayz-server-livonia/
│   └── dsxt/
└── dayz-server-sakhal/
    └── dsxt/
```

Rendre le script exécutable :

```bash
chmod +x dsxt.sh
```

Adapter les chemins dans le script si l'arborescence utilisée est différente.

## Préparer les fragments XML

Chaque fragment suit la convention de nommage `TAG_cible.xml`.

- `TAG` identifie la configuration personnalisée.
- `cible.xml` est le nom du fichier XML de mission à modifier.

Exemple de fragment : `CODE-LOCK_types.xml`, placé dans `dayz-server-chernarus/dsxt/` :

```xml
<type name="CodeLock">
    <nominal>10</nominal>
    <lifetime>7200</lifetime>
    <restock>0</restock>
    <min>5</min>
    <quantmin>-1</quantmin>
    <quantmax>-1</quantmax>
    <cost>100</cost>
    <flags count_in_cargo="0" count_in_hoarder="0" count_in_map="1" count_in_player="0" crafted="0" deloot="0"/>
    <category name="tools"/>
    <usage name="Industrial"/>
    <usage name="Farm"/>
</type>
```

Un fragment contient uniquement les entrées XML à insérer. Ne pas inclure de déclaration XML, de racine supplémentaire telle que `<types>`, ni de marqueurs `CUSTOM` de DSXT.

Les entrées doivent être adaptées au fichier XML de mission cible. Les fragments peuvent être organisés par mod ou regroupés selon les besoins.

## Utilisation

```text
Usage: ./dsxt.sh [-e|-E|-c|-l|-V|-x|-f|-h] SERVERLIST [FILELIST|TAG|TAGS|LIST]
       -e suppression ciblée | -E suppression globale par TAG
       -c comparer | -l lister
       -V valider | -x extraire | -f synchroniser | -h aide
       -f et -x : un seul serveur
```

### Exemples de commandes

```bash
./dsxt.sh SERVEURS FICHIERS
./dsxt.sh -e SERVEURS FICHIERS
./dsxt.sh -E SERVEURS TAGS
./dsxt.sh -c SERVEURS FICHIERS
./dsxt.sh -l SERVEURS
./dsxt.sh -V SERVEURS
./dsxt.sh -x SERVEUR TAG
./dsxt.sh -f SERVEUR LISTE
./dsxt.sh -h
```

- `SERVEURS` : liste de répertoires de serveurs séparés par des virgules.
- `FICHIERS` : liste de noms de fragments XML séparés par des virgules.
- `TAG` / `TAGS` : un TAG ou une liste de TAG séparés par des virgules.
- `LISTE` : nom du fichier de synchronisation placé dans le répertoire `dsxt/` du serveur. Son nom et son extension sont libres.

Utiliser `./dsxt.sh -h` pour consulter l'aide complète et les détails des options.

## Synchronisation à partir d'une liste de référence

L'option `-f` utilise un fichier de référence stocké dans le répertoire `dsxt/` du serveur. Son nom et son extension sont libres.

Le fichier contient un nom de fichier source par ligne. Les lignes vides et les lignes commençant par `#` sont ignorées.

Exemple : `normal.conf`

```text
# Configuration de référence
SOCLE_types.xml
CODE-LOCK_types.xml
TDM_cfgspawnabletypes.xml
```

## Plusieurs serveurs

Lorsqu'une commande cible plusieurs serveurs, chaque fichier source demandé doit exister dans le répertoire `dsxt/` de **chacun des serveurs sélectionnés**.

Le contenu de ces fichiers peut différer d'un serveur à l'autre : chaque serveur utilise son propre fragment. Si un fichier source demandé manque sur l'un des serveurs sélectionnés, les vérifications préalables échouent et aucune modification n'est effectuée.

## Projet associé

Consulter le [Guide du serveur DayZ sous Linux](https://github.com/fredleborgne51-hub/dayz-linux-server-guide) pour des informations sur l'installation et l'administration d'un serveur dédié DayZ sous Linux.

## Licence

DSXT est distribué sous licence MIT. Voir le fichier [LICENSE](LICENSE).
