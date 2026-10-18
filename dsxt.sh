#!/bin/bash

# ============================================================
# dsxt V3.06
# Gestion des blocs XML CUSTOM pour serveurs DayZ
#
# Interface :
#   ./dsxt.sh SERVEURS FICHIERS
#   ./dsxt.sh -e SERVEURS FICHIERS
#   ./dsxt.sh -E SERVEURS TAGS
#   ./dsxt.sh -c SERVEURS FICHIERS
#   ./dsxt.sh -l SERVEURS
#   ./dsxt.sh -V SERVEURS
#   ./dsxt.sh -x SERVEUR TAG
#   ./dsxt.sh -f SERVEUR LISTE
#   ./dsxt.sh -h
# ============================================================

SCRIPT_NAME="${0##*/}"
BCMD="./"

BASE="/home/dayz/servers"

VERSION="V3.06"
HEADER="= DayZ Server XML Tool ${VERSION} =============================="
FOOTER="=============================================== FLB/OpenIA ="

# ------------------------------------------------------------
# 1 Couleurs ANSI
# ------------------------------------------------------------

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[93m'
CYAN='\033[36m'
MAGENTA='\033[35m'
BOLD='\033[1m'
RESET='\033[0m'

# ------------------------------------------------------------
# 2 Répertoire DSXT du serveur
# ------------------------------------------------------------

get_dsxt_dir() {

    local server="$1"

    DSXT_DIR="$BASE/$server/dsxt"

    if [[ ! -d "$DSXT_DIR" ]]; then

        if ! mkdir -p "$DSXT_DIR"; then

            echo -e "${RED}[ERROR]${RESET} Impossible de créer : $DSXT_DIR"
            return 1

        fi

    fi

    return 0
}

# ------------------------------------------------------------
# 3 Vérification du répertoire DSXT
# ------------------------------------------------------------

check_dsxt_dir() {

    local server="$1"

    DSXT_DIR="$BASE/$server/dsxt"

    if [[ ! -d "$DSXT_DIR" ]]; then

        echo -e "${RED}[ERROR]${RESET} Répertoire DSXT absent : $DSXT_DIR"
        return 1

    fi

    return 0
}

# ------------------------------------------------------------
# 4 Vérification xmllint
# ------------------------------------------------------------

if ! command -v xmllint >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${RESET} xmllint n'est pas installé."
    echo
    echo "Sous Debian/Ubuntu :"
    echo "  sudo apt update"
    echo "  sudo apt install libxml2-utils"
    exit 1
fi

# ------------------------------------------------------------
# 5 Aide
# ------------------------------------------------------------

usage_short() {
    {
    [[ -n "$1" ]] && echo -e "${RED}[ERROR]${RESET} $1"
    local dir server file first maxlen=0 width
    local -a servers=()

    echo "Usage : $SCRIPT_NAME [-e|-E|-c|-l|-V|-x|-f|-h] SERVEURLIST [FILELIST|TAG|TAGS|LISTE]"
    echo "        -e suppression ciblée | -E suppression globale par TAG"
    echo "        -c comparer | -l lister"
    echo "        -V valider  | -x extraire | -f synchroniser | -h aide"
    echo "        -f et -x : un seul serveur"
    echo
    echo "Serveurs et fichiers disponibles :"

    for dir in "$BASE"/dayz-server-*; do
        [[ -d "$dir" ]] || continue
        server="${dir##*/}"
        servers+=("$server")
        (( ${#server} > maxlen )) && maxlen=${#server}
    done

    width=$((maxlen + 2))


    for server in "${servers[@]}"; do
        printf '  %b%s%b\n' "$CYAN" "$server" "$RESET"

        first=1
        for file in "$BASE/$server/dsxt"/*; do
            [[ -f "$file" ]] || continue
            printf '    %b%s%b\n' "$MAGENTA" "${file##*/}" "$RESET"
            first=0
        done

        if [[ "$first" -eq 1 ]]; then
            printf '    (aucun fichier)\n'
        fi
        printf '\n'
    done
    } | more
}

usage() {

    echo "$SCRIPT_NAME $VERSION"
    echo
    echo "Usage :"
    echo " $BCMD$SCRIPT_NAME SERVEURS FICHIERS"
    echo "      Ajoute ou remplace les blocs CUSTOM."
    echo
    echo " $BCMD$SCRIPT_NAME -e SERVEURS FICHIERS"
    echo "      Supprime les blocs CUSTOM."
    echo
    echo " $BCMD$SCRIPT_NAME -E SERVEURS TAGS"
    echo "      Supprime les blocs CUSTOM portant les TAG demandés."
    echo "      Recherche dans tous les fichiers XML des missions."
    echo "      Affiche les suppressions prévues et demande confirmation."
    echo "      Un TAG absent est ignoré."
    echo
    echo " $BCMD$SCRIPT_NAME -c SERVEURS FICHIERS"
    echo "      Compare les blocs CUSTOM installés avec les sources."
    echo
    echo " $BCMD$SCRIPT_NAME -l SERVEURS"
    echo "      Liste les blocs CUSTOM présents dans les missions."
    echo
    echo " $BCMD$SCRIPT_NAME -V SERVEURS"
    echo "      Valide tous les fichiers XML des missions avec xmllint."
    echo
    echo " $BCMD$SCRIPT_NAME -x SERVEUR TAG"
    echo "      Extrait les blocs d'un TAG vers le répertoire dsxt du serveur."
    echo
    echo " $BCMD$SCRIPT_NAME -f SERVEUR LISTE"
    echo "      Synchronise les blocs CUSTOM selon une liste de référence."
    echo "      Ajoute, remplace ou supprime les blocs nécessaires."
    echo "      Affiche les changements et demande confirmation avant application."
    echo "      Si tout est conforme, aucune confirmation n'est demandée."
    echo
    echo " $BCMD$SCRIPT_NAME -h"
    echo "      Affiche cette aide."
    echo
    echo "SERVEURS :"
    echo "  Liste séparée par des virgules (sauf pour -f et -x qui n'acceptent qu'un seul serveur)."
    echo "  Exemple : dayz-server-chernarus,dayz-server-livonia"
    echo
    echo "FICHIERS :"
    echo "  Liste séparée par des virgules."
    echo "  Chaque source suit le format TAG_fichier.xml."
    echo "  Chaque fichier doit exister dans le répertoire dsxt/ de chaque serveur sélectionné."
    echo "  Le contenu des fragments peut différer d'un serveur à l'autre."
    echo "    Exemples :"
    echo "      TDM_types.xml,TDM_cfgspawnabletypes.xml,TRADER_types.xml"
    echo
    echo "TAGS :"
    echo "  Liste séparée par des virgules."
    echo "  Exemple : CODE-LOCK,TDM,TRADERS"
    echo
    echo "LISTE DE SYNCHRONISATION (-f) :"
    echo "  Le fichier de liste doit se trouver dans le répertoire dsxt du serveur."
    echo "  Son nom et son extension sont libres."
    echo "  Il contient un nom de fichier source par ligne."
    echo "  Les lignes vides et les lignes commençant par # sont ignorées."
    echo
    echo "  Exemple de fichier normal.conf :"
    echo "    # Configuration de référence"
    echo "    SOCLE_types.xml"
    echo "    CODE-LOCK_types.xml"
    echo "    TDM_cfgspawnabletypes.xml"
    echo
    echo "  Exemple d'utilisation :"
    echo "    $SCRIPT_NAME -f dayz-server-chernarus normal.conf"
    echo
    echo "PRÉREQUIS ET ORGANISATION :"
    echo "  - xmllint doit être installé."
    echo "  - Chaque instance doit posséder son propre répertoire dsxt."
    echo "  - Les fichiers sources XML doivent se trouver dans ce répertoire."
    echo "  - Les listes utilisées avec -f doivent également s'y trouver."
    echo "  - Les sources contiennent uniquement le fragment XML personnalisé,"
    echo "    sans déclaration XML, élément racine ni marqueurs CUSTOM."
    echo
}

# ------------------------------------------------------------
# 6 Analyse des arguments
# ------------------------------------------------------------

MODE="add"

case "$1" in

    -h|--help)

        if [[ $# -ne 1 ]]; then
            echo -e "${RED}[ERROR]${RESET} -h n'accepte aucun argument supplémentaire."
            echo
            usage
            exit 1
        fi

        usage | more
        exit 0
        ;;

    -l)
        MODE="list"
        shift
        ;;

    -e)
        MODE="erase"
        shift
        ;;

    -E)
        MODE="erase_tags"
        shift
        ;;

    -c)
        MODE="compare"
        shift
        ;;

    -V)
        MODE="validate"
        shift
        ;;

    -x)
        MODE="extract"
        shift
        ;;

    -f)
        MODE="file"
        shift
        ;;

    -*)
        usage_short "Option inconnue : $1"
        exit 1
        ;;

esac

# ------------------------------------------------------------
# 7 Vérification du nombre d'arguments
# ------------------------------------------------------------

if [[ "$MODE" == "list" || "$MODE" == "validate" ]]; then

    if [[ $# -ne 1 ]]; then

        if [[ "$MODE" == "list" ]]; then
            usage_short "-l attend exactement un argument : SERVEURS"
        else
            usage_short "-V attend exactement un argument : SERVEURS"
        fi

         exit 1
    fi

    SERVERS="$1"

elif [[ "$MODE" == "extract" ]]; then

    if [[ $# -ne 2 ]]; then
        usage_short "-x attend exactement deux arguments : SERVEUR TAG"
        exit 1
    fi

    SERVERS="$1"
    TAG="$2"

elif [[ "$MODE" == "file" ]]; then

    if [[ $# -ne 2 ]]; then
        usage_short "-f attend deux arguments : SERVEUR LISTE.conf"
        exit 1
    fi

    SERVERS="$1"
    CONFIG_FILE="$2"

else

    if [[ $# -ne 2 ]]; then
        usage_short "Cette opération attend exactement deux arguments : SERVEURS FICHIERS"
        exit 1
    fi

    SERVERS="$1"
    FILES="$2"

fi

# ------------------------------------------------------------
# 8 Validation du nom de source
#
# Format :
#   TAG_fichier.xml
#
# Un seul underscore structurel.
# ------------------------------------------------------------

validate_filename() {

    local file="$1"
    local name

    name="$(basename "$file")"

    if [[ "$name" != *.xml ]]; then
        echo -e "${RED}[ERROR]${RESET} Fichier source invalide : $name"
        echo "        Extension .xml obligatoire."
        return 1
    fi

    if [[ "$name" != *_* ]]; then
        echo -e "${RED}[ERROR]${RESET} Nom de source invalide : $name"
        echo "        Format attendu : TAG_fichier.xml"
        return 1
    fi

    if [[ "$name" == *_*_* ]]; then
        echo -e "${RED}[ERROR]${RESET} Nom de source invalide : $name"
        echo "        Un seul underscore est autorisé : TAG_fichier.xml"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# 9 Extraction TAG / fichier cible
# ------------------------------------------------------------

parse_source_name() {

    local source="$1"
    local name

    name="$(basename "$source")"

    TAG="${name%%_*}"
    TARGET="${name#*_}"

    if [[ -z "$TAG" || -z "$TARGET" ]]; then
        echo -e "${RED}[ERROR]${RESET} Impossible d'analyser le nom : $name"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# 10 Recherche de la mission
# ------------------------------------------------------------

get_mission() {

    local server="$1"
    local cfg="$BASE/$server/serverDZ.cfg"

    if [[ ! -f "$cfg" ]]; then
        echo -e "${RED}[ERROR]${RESET} serverDZ.cfg introuvable : $cfg"
        return 1
    fi

    MISSION="$(
        sed -nE \
            's/^[[:space:]]*template[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' \
            "$cfg" |
        head -n 1
    )"

    if [[ -z "$MISSION" ]]; then
        echo -e "${RED}[ERROR]${RESET} Impossible de trouver template dans : $cfg"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# 11 Recherche du fichier XML cible
# ------------------------------------------------------------

find_destination() {

    local server="$1"
    local mission="$2"
    local target="$3"

    local mission_dir="$BASE/$server/mpmissions/$mission"
    local count

    if [[ ! -d "$mission_dir" ]]; then
        echo -e "${RED}[ERROR]${RESET} Mission introuvable : $mission_dir"
        return 1
    fi

    mapfile -d '' RESULTS < <(
        find "$mission_dir" \
            -type f \
            -name "$target" \
            -print0
    )

    count="${#RESULTS[@]}"

    if [[ "$count" -eq 0 ]]; then
        echo -e "${RED}[ERROR]${RESET} Fichier cible introuvable : $target"
        echo "        Mission : $mission_dir"
        return 1
    fi

    if [[ "$count" -gt 1 ]]; then
        echo -e "${RED}[ERROR]${RESET} Plusieurs fichiers cibles trouvés : $target"

        printf '        %s\n' "${RESULTS[@]}"

        return 1
    fi

    DESTINATION="${RESULTS[0]}"

    return 0
}

# ------------------------------------------------------------
# 12 Validation du fragment XML source
# ------------------------------------------------------------

validate_fragment() {

    local source="$1"
    local temp

    temp="$(mktemp)"

    {
        echo '<restore_dayz_xml>'
        cat "$source"
        echo '</restore_dayz_xml>'
    } > "$temp"

    if ! xmllint --noout "$temp" >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${RESET} Fragment XML invalide : $source"
        rm -f "$temp"
        return 1
    fi

    rm -f "$temp"

    return 0
}

# ------------------------------------------------------------
# 13 Validation globale de tous les XML d'une mission
# ------------------------------------------------------------

validate_all_xml() {

    local server="$1"
    local mission="$2"

    local mission_dir="$BASE/$server/mpmissions/$mission"
    local file
    local relative
    local count=0
    local invalid=0
    local error

    if [[ ! -d "$mission_dir" ]]; then
        echo -e "${RED}[ERROR]${RESET} Mission introuvable : $mission_dir"
        return 1
    fi

    echo
    echo "$HEADER"
    echo
    echo "Serveur : $server"
    echo "Mission : $mission"
    echo

    while IFS= read -r -d '' file; do

        count=$((count + 1))

        relative="${file#"$mission_dir"/}"

        if xmllint --noout "$file" >/dev/null 2>&1; then

            echo -e "${GREEN}[OK]${RESET}    $relative"

        else

            error="$(xmllint --noout "$file" 2>&1)"

            echo -e "${RED}[ERROR]${RESET} $relative"

            invalid=$((invalid + 1))

            VALIDATION_ERRORS+=("$server|$relative|$error")

        fi

    done < <(
        find "$mission_dir" \
            -type f \
            -name "*.xml" \
            -print0
    )

    if [[ "$count" -eq 0 ]]; then

        echo -e "${RED}[ERROR]${RESET} Aucun fichier XML trouvé dans la mission."
        return 1

    fi

    if [[ "$invalid" -gt 0 ]]; then

        echo
        echo -e "${RED}[ERROR]${RESET} $invalid fichier(s) XML invalide(s) dans ce serveur."
        return 1

    fi

    return 0
}

# ------------------------------------------------------------
# 14 Suppression d'un bloc CUSTOM
# ------------------------------------------------------------

remove_custom_block() {

    local file="$1"
    local tag="$2"

    local start_marker="<!-- ${tag} CUSTOM START -->"
    local end_marker="<!-- ${tag} CUSTOM END -->"

    local temp

    BLOCK_FOUND=0

    if ! grep -Fq "$start_marker" "$file"; then
        return 0
    fi

    BLOCK_FOUND=1

    if ! grep -Fq "$end_marker" "$file"; then
        echo -e "${RED}[ERROR]${RESET} Marqueur de fin absent pour le bloc ${tag}."
        return 1
    fi

    temp="$(mktemp)"

    awk \
        -v start="$start_marker" \
        -v end="$end_marker" '

        $0 == start {
            inside=1
            next
        }

        $0 == end {
            inside=0
            next
        }

        !inside {
            print
        }

    ' "$file" > "$temp"

    if [[ $? -ne 0 ]]; then
        rm -f "$temp"
        echo -e "${RED}[ERROR]${RESET} Erreur lors de la suppression du bloc ${tag}."
        return 1
    fi

    mv "$temp" "$file"

    return 0
}

# ------------------------------------------------------------
# 15 Insertion du bloc CUSTOM
# ------------------------------------------------------------

insert_custom_block() {

    local file="$1"
    local source="$2"

    local root
    local temp

    root="$(
        sed -nE \
            's/^[[:space:]]*<([[:alnum:]_-]+)([[:space:]>]).*/\1/p' \
            "$file" |
        head -n 1
    )"

    if [[ -z "$root" ]]; then
        echo -e "${RED}[ERROR]${RESET} Racine XML introuvable dans : $file"
        return 1
    fi

    temp="$(mktemp)"

    awk \
        -v root="$root" \
        -v source="$source" \
        -v tag="$TAG" '

        BEGIN {
            inserted=0
        }

        !inserted &&
        $0 ~ "^[[:space:]]*<" root "([[:space:]>])" {

            print
            print "<!-- " tag " CUSTOM START -->"

            while ((getline line < source) > 0) {
                print line
            }

            close(source)

            print "<!-- " tag " CUSTOM END -->"

            inserted=1
            next
        }

        {
            print
        }

    ' "$file" > "$temp"

    if [[ $? -ne 0 ]]; then
        rm -f "$temp"
        echo -e "${RED}[ERROR]${RESET} Erreur lors de l'insertion du bloc ${TAG}."
        return 1
    fi

    if ! grep -Fq "<!-- ${TAG} CUSTOM START -->" "$temp"; then
        rm -f "$temp"
        echo -e "${RED}[ERROR]${RESET} Impossible d'insérer le bloc ${TAG}."
        return 1
    fi

    mv "$temp" "$file"

    return 0
}

# ------------------------------------------------------------
# 16 Validation XML final
# ------------------------------------------------------------

validate_xml() {

    local file="$1"

    if ! xmllint --noout "$file" >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${RESET} XML final invalide : $file"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# 17 Comparaison du bloc CUSTOM
# ------------------------------------------------------------

compare_custom_block() {

    local file="$1"
    local source="$2"
    local tag="$3"

    local start_marker="<!-- ${tag} CUSTOM START -->"
    local end_marker="<!-- ${tag} CUSTOM END -->"

    local temp

    if ! grep -Fq "$start_marker" "$file"; then
        echo -e "${YELLOW}[INFO]${RESET} Bloc ${BOLD}${tag}${RESET} absent du fichier."
        return 1
    fi

    if ! grep -Fq "$end_marker" "$file"; then
        echo -e "${RED}[ERROR]${RESET} Marqueur de fin absent pour le bloc ${tag}."
        return 1
    fi

    temp="$(mktemp)"

    awk \
        -v start="$start_marker" \
        -v end="$end_marker" '

        $0 == start {
            inside=1
            next
        }

        $0 == end {
            inside=0
            exit
        }

        inside {
            print
        }

    ' "$file" > "$temp"

    if cmp -s "$temp" "$source"; then

        rm -f "$temp"

        echo -e "${GREEN}[OK]${RESET} Bloc ${BOLD}${tag}${RESET} conforme à la source."

        return 0
    fi

    echo -e "${RED}[ERROR]${RESET} Bloc ${BOLD}${tag}${RESET} différent de la source."
    echo

    diff -u "$source" "$temp" || true

    rm -f "$temp"

    return 1
}

# ------------------------------------------------------------
# 18 Traitement d'un fichier
# ------------------------------------------------------------

process_file() {

    local server="$1"
    local source_name="$2"

    local source
    local backup

    if ! check_dsxt_dir "$server"; then
        return 1
    fi

    source="$DSXT_DIR/$source_name"

    echo
    echo "Serveur : $server"
    echo "Source  : $source_name"
    echo "TAG     : $TAG"
    echo "Cible   : $TARGET"
    echo "Mission : $MISSION"
    echo "Fichier : $DESTINATION"

    # --------------------------------------------------------
    # 18-1 Comparaison
    # --------------------------------------------------------

    if [[ "$MODE" == "compare" ]]; then

        echo "Action  : comparaison du bloc $TAG"

        if compare_custom_block "$DESTINATION" "$source" "$TAG"; then
            return 0
        fi

        return 1
    fi

    # --------------------------------------------------------
    # 18-2 Validation source
    # --------------------------------------------------------

    if ! validate_fragment "$source"; then
        return 1
    fi

    # --------------------------------------------------------
    # 18-3 Sauvegarde
    # --------------------------------------------------------

    backup="${DESTINATION}.restore_dayz_xml.bak"

    if ! cp -p "$DESTINATION" "$backup"; then
        echo -e "${RED}[ERROR]${RESET} Impossible de créer la sauvegarde."
        return 1
    fi

    # --------------------------------------------------------
    # 18-4 Suppression du bloc existant
    # --------------------------------------------------------

    if ! remove_custom_block "$DESTINATION" "$TAG"; then

        cp -p "$backup" "$DESTINATION"
        rm -f "$backup"

        return 1
    fi

    # --------------------------------------------------------
    # 18-5 Suppression
    # --------------------------------------------------------

    if [[ "$MODE" == "erase" ]]; then

        if [[ "$BLOCK_FOUND" -eq 0 ]]; then

            echo -e "${YELLOW}[INFO]${RESET} Bloc ${BOLD}${TAG}${RESET} absent : ${YELLOW}aucune modification effectuée${RESET}."

            cp -p "$backup" "$DESTINATION"
            rm -f "$backup"

            return 0
        fi

        if ! validate_xml "$DESTINATION"; then

            cp -p "$backup" "$DESTINATION"
            rm -f "$backup"

            return 1
        fi

        rm -f "$backup"

        echo -e "${GREEN}[OK]${RESET} Bloc ${BOLD}${TAG}${RESET} supprimé."

        return 0
    fi

    # --------------------------------------------------------
    # 18-6 Ajout / remplacement
    # --------------------------------------------------------

    if [[ "$BLOCK_FOUND" -eq 1 ]]; then

        echo -e "${YELLOW}[INFO]${RESET} Bloc ${BOLD}${TAG}${RESET} existant : ${YELLOW}remplacement${RESET}."

    else

        echo -e "${YELLOW}[INFO]${RESET} Bloc ${BOLD}${TAG}${RESET} absent : ${YELLOW}ajout du bloc ${TAG}${RESET}."

    fi

    if ! insert_custom_block "$DESTINATION" "$source"; then

        cp -p "$backup" "$DESTINATION"
        rm -f "$backup"

        return 1
    fi

    # --------------------------------------------------------
    # 18-7 Validation XML
    # --------------------------------------------------------

    if ! validate_xml "$DESTINATION"; then

        echo -e "${YELLOW}[INFO]${RESET} Restauration de la sauvegarde."

        cp -p "$backup" "$DESTINATION"
        rm -f "$backup"

        return 1
    fi

    rm -f "$backup"

    if [[ "$BLOCK_FOUND" -eq 1 ]]; then

        echo -e "${GREEN}[OK]${RESET} Bloc ${BOLD}${TAG}${RESET} remplacé."

    else

        echo -e "${GREEN}[OK]${RESET} Bloc ${BOLD}${TAG}${RESET} ajouté."

    fi

    return 0
}

# ------------------------------------------------------------
# 19 Extract CUSTOM blocks
# ------------------------------------------------------------

extract_custom_blocks() {

    local server="$1"
    local mission="$2"
    local tag="$3"

    local mission_dir="$BASE/$server/mpmissions/$mission"
    local file
    local target
    local output
    local start_count
    local end_count
    local count=0

    local start_marker="<!-- ${tag} CUSTOM START -->"
    local end_marker="<!-- ${tag} CUSTOM END -->"

    local -a matches=()

    if [[ ! -d "$mission_dir" ]]; then
        echo -e "${RED}[ERROR]${RESET} Mission introuvable : $mission_dir"
        return 1
    fi

    # --------------------------------------------------------
    # 19-1 Analyse complète de la mission
    # --------------------------------------------------------

    while IFS= read -r -d '' file; do

        start_count=$(awk -v marker="$start_marker" '
            {
                line=$0
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line == marker)
                    count++
            }
            END {
                print count + 0
            }
        ' "$file")

        end_count=$(awk -v marker="$end_marker" '
            {
                line=$0
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line == marker)
                    count++
            }
            END {
                print count + 0
            }
        ' "$file")

        # Aucun bloc dans ce fichier
        if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
            continue
        fi

        # Bloc absent ou présent plusieurs fois
        if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then

            echo -e "${RED}[ERROR]${RESET} Bloc $tag invalide dans : $file"
            echo "        START : $start_count"
            echo "        END   : $end_count"

            return 1
        fi

        matches+=("$file")
        count=$((count + 1))

    done < <(
        find "$mission_dir" \
            -type f \
            -name "*.xml" \
            -print0
    )

    # --------------------------------------------------------
    # 19-2 Aucun bloc trouvé
    # --------------------------------------------------------

    if [[ "$count" -eq 0 ]]; then

        echo -e "${RED}[ERROR]${RESET} Aucun bloc CUSTOM trouvé pour : $tag"

        return 1
    fi

    # --------------------------------------------------------
    # 19-3 Création du répertoire DSXT
    # --------------------------------------------------------

    if ! get_dsxt_dir "$server"; then
        return 1
    fi

    # --------------------------------------------------------
    # 19-4 Extraction
    # --------------------------------------------------------

    for file in "${matches[@]}"; do

        target="$(basename "$file")"
        output="$DSXT_DIR/${tag}_${target}"

        awk \
            -v start="$start_marker" \
            -v end="$end_marker" '
            {
                line=$0
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            }

            line == start {
                inside=1
                next
            }

            line == end {
                inside=0
                next
            }

            inside {
                print
            }
            ' "$file" > "$output"

        echo -e "${GREEN}[OK]${RESET} $target -> $output"

    done

    return 0
}

# ------------------------------------------------------------
# 20 Listing des blocs CUSTOM
# ------------------------------------------------------------

list_custom_blocks() {

    local server="$1"

    local mission
    local mission_dir
    local file
    local tag

    local found=0

    if ! get_mission "$server"; then
        return 1
    fi

    mission_dir="$BASE/$server/mpmissions/$MISSION"

    if [[ ! -d "$mission_dir" ]]; then
        echo -e "${RED}[ERROR]${RESET} Mission introuvable : $mission_dir"
        return 1
    fi

    echo
    echo "$HEADER"
    echo
    echo "Serveur : $server"
    echo "Mission : $MISSION"
    echo

    while IFS= read -r -d '' file; do

        while IFS= read -r tag; do

            [[ -z "$tag" ]] && continue

            echo -e "${YELLOW}[CUSTOM]${RESET} ${BOLD}${tag}${RESET}"
            echo "         Fichier : $file"

            found=1

        done < <(
            sed -nE \
                's/^[[:space:]]*<!--[[:space:]]*([^[:space:]]+)[[:space:]]+CUSTOM[[:space:]]+START[[:space:]]*-->[[:space:]]*$/\1/p' \
                "$file"
        )

    done < <(
        find "$mission_dir" \
            -type f \
            -name "*.xml" \
            -print0
    )

    if [[ "$found" -eq 0 ]]; then
        echo -e "${YELLOW}[INFO]${RESET} Aucun bloc CUSTOM trouvé."
    fi

    return 0
}

    
    # ------------------------------------------------------------
    # 20-1 Recensement et contrôle des blocs CUSTOM
    # ------------------------------------------------------------

    scan_custom_blocks() {

        local mission_dir="$1"
        local file
        local scan_output
        local record
        local tag
        local starts
        local ends
        local start_line
        local end_line
        local line_number
        local details

        SCAN_ERROR=0
        declare -gA CUSTOM_BLOCKS=()
        CUSTOM_BLOCKS=()

        if [[ ! -d "$mission_dir" ]]; then
            echo -e "${RED}[ERROR]${RESET} Mission introuvable : $mission_dir"
            return 1
        fi

        while IFS= read -r -d '' file; do

            if ! scan_output="$(awk '

                /<!--[[:space:]]*.*CUSTOM[[:space:]]+(START|END)/ {

                    marker = $0

                    if (marker !~ /^[[:space:]]*<!--[[:space:]]*[^[:space:]]+[[:space:]]+CUSTOM[[:space:]]+(START|END)[[:space:]]*-->[[:space:]]*$/) {
                        printf "INVALID\t%d\t%s\n", NR, $0
                        next
                    }

                    sub(/^[[:space:]]*<!--[[:space:]]*/, "", marker)
                    split(marker, fields, /[[:space:]]+/)

                    tag = fields[1]
                    kind = fields[3]

                    if (!(tag in seen)) {
                        seen[tag] = 1
                        order[++count] = tag
                    }

                    if (kind == "START") {
                        starts[tag]++
                        start_line[tag] = NR

                    if (active != "") {
                        printf "STRUCTURE\t%d\tDébut imbriqué : %s (bloc ouvert : %s)\n", NR, tag, active
                    }

                    active = tag

                    }

                    if (kind == "END") {
                        ends[tag]++
                        end_line[tag] = NR

                    if (active != tag) {
                        printf "STRUCTURE\t%d\tFin inattendue : %s (bloc ouvert : %s)\n", NR, tag, active
                    }

                    else {
                        active = ""
                        }
                    }
                }

                END {
                    if (active != "") {
                        printf "UNCLOSED\t%s\n", active
                    }

                    for (i = 1; i <= count; i++) {
                        tag = order[i]
                        printf "BLOCK\t%s\t%d\t%d\t%d\t%d\n", \
                            tag, starts[tag] + 0, ends[tag] + 0, \
                            start_line[tag] + 0, end_line[tag] + 0
                    }
                }

            ' "$file")"; then
                echo -e "${RED}[ERROR]${RESET} Échec de l'analyse : $file"
                SCAN_ERROR=1
                continue
            fi

            while IFS=$'\t' read -r record tag starts ends start_line end_line; do

                case "$record" in

                    INVALID)
                        line_number="$tag"
                        details="$starts"
                        echo -e "${RED}[ERROR]${RESET} Marqueur CUSTOM invalide."
                        echo "        Fichier : $file"
                        echo "        Ligne   : $line_number"
                        echo "        Contenu : $details"
                        SCAN_ERROR=1
                        ;;

                    STRUCTURE)
                        line_number="$tag"
                        details="$starts"
                        echo -e "${RED}[ERROR]${RESET} Structure CUSTOM incohérente."
                        echo "        Fichier : $file"
                        echo "        Ligne   : $line_number"
                        echo "        Détail  : $details"
                        SCAN_ERROR=1
                        ;;

                    UNCLOSED)
                        echo -e "${RED}[ERROR]${RESET} Bloc CUSTOM non refermé : $tag"
                        echo "        Fichier : $file"
                        SCAN_ERROR=1
                        ;;

                    BLOCK)
                        tag="$tag"

                        if [[ "$starts" -ne 1 || "$ends" -ne 1 || "$end_line" -le "$start_line" ]]; then
                            echo -e "${RED}[ERROR]${RESET} Doublon ou paire de marqueurs incohérente : $tag"
                            echo "        Fichier : $file"
                            echo "        START=$starts END=$ends"
                            SCAN_ERROR=1
                        else
                            CUSTOM_BLOCKS["$file|$tag"]=1
                        fi
                        ;;

                esac

            done <<< "$scan_output"

        done < <(find "$mission_dir" -type f -name "*.xml" -print0)

        return "$SCAN_ERROR"
    }

    # ------------------------------------------------------------
    # 20-2 Synchronisation des blocs CUSTOM selon une liste
    # ------------------------------------------------------------

    sync_custom_blocks() {

        local server="$SERVERS"
        local mission
        local mission_dir
        local source_name source target tag destination
        local key file base stage tmpdir
        local action answer rc
        local i index
        local errors=0
        local changes=0
        local committed=0

        local -a PLAN_ACTION=()
        local -a PLAN_FILE=()
        local -a PLAN_TAG=()
        local -a PLAN_SOURCE=()
        local -a ORIGINALS=()
        local -a STAGES=()
        local -a BACKUPS=()

        local -A EXPECTED=()
        local -A STALE=()
        local -A STAGE_BY_FILE=()

        # --------------------------------------------------------
        # 20-2-1 Contrôles généraux
        # --------------------------------------------------------

        if [[ "$server" == *,* ]]; then
            echo -e "${RED}[ERROR]${RESET} -f accepte un seul serveur."
            return 1
        fi

        if ! get_mission "$server"; then
            return 1
        fi

        mission_dir="$BASE/$server/mpmissions/$MISSION"

        if [[ ! -d "$mission_dir" ]]; then
            echo -e "${RED}[ERROR]${RESET} Mission introuvable : $mission_dir"
            return 1
        fi

        if ! check_dsxt_dir "$server"; then
            return 1
        fi

        # Contrôle structurel de tous les marqueurs de la mission.
        if ! scan_custom_blocks "$mission_dir"; then
            echo -e "${RED}[ERROR]${RESET} Structure CUSTOM invalide. Aucune modification."
            return 1
        fi

        # --------------------------------------------------------
        # 20-2-2 Vérification des sources et destinations
        # --------------------------------------------------------

        for source_name in "${FILE_LIST[@]}"; do

            if ! validate_filename "$source_name"; then
                errors=1
                continue
            fi

            if ! parse_source_name "$source_name"; then
                errors=1
                continue
            fi

            tag="$TAG"
            target="$TARGET"
            source="$DSXT_DIR/$source_name"
            key="$tag|$target"

            if [[ -n "${EXPECTED[$key]+present}" ]]; then
                echo -e "${RED}[ERROR]${RESET} Entrée en double : $source_name"
                errors=1
                continue
            fi

            EXPECTED["$key"]=1

            if [[ ! -f "$source" ]]; then
                echo -e "${RED}[ERROR]${RESET} Source introuvable : $source"
                errors=1
                continue
            fi

            if ! validate_fragment "$source"; then
                errors=1
                continue
            fi

            if ! find_destination "$server" "$MISSION" "$target"; then
                errors=1
                continue
            fi

            destination="$DESTINATION"

            if ! xmllint --noout "$destination" >/dev/null 2>&1; then
                echo -e "${RED}[ERROR]${RESET} XML destination invalide : $destination"
                errors=1
                continue
            fi

            # Un bloc existant portant le même TAG dans un autre XML
            # sera traité comme obsolète lors de l'inventaire ci-dessous.
            if [[ -n "${CUSTOM_BLOCKS["$destination|$tag"]+present}" ]]; then

                if compare_custom_block "$destination" "$source" "$tag" >/dev/null 2>&1; then
                    action="CONFORME"
                else
                    action="REMPLACEMENT"
                    changes=$((changes + 1))
                fi

            else
                action="AJOUT"
                changes=$((changes + 1))
            fi

            PLAN_ACTION+=("$action")
            PLAN_FILE+=("$destination")
            PLAN_TAG+=("$tag")
            PLAN_SOURCE+=("$source")

        done

        if [[ "$errors" -ne 0 ]]; then
            echo -e "${RED}[ERROR]${RESET} Contrôles échoués. Aucune modification."
            return 1
        fi

        # --------------------------------------------------------
        # 20-2-3 Repérage des blocs obsolètes
        # --------------------------------------------------------

        for key in "${!CUSTOM_BLOCKS[@]}"; do

            file="${key%|*}"
            tag="${key##*|}"
            base="$(basename "$file")"

            if [[ -z "${EXPECTED["$tag|$base"]+present}" ]]; then
                STALE["$file|$tag"]=1
            fi

        done

        for key in "${!STALE[@]}"; do

            file="${key%|*}"
            tag="${key##*|}"

            PLAN_ACTION+=("SUPPRESSION")
            PLAN_FILE+=("$file")
            PLAN_TAG+=("$tag")
            PLAN_SOURCE+=("")
            changes=$((changes + 1))

        done

        # --------------------------------------------------------
        # 20-2-4 Présentation du plan
        # --------------------------------------------------------

        echo
        echo "$HEADER"
        echo "Synchronisation : $server"
        echo "Liste : $CONFIG_PATH"
        echo

        for ((i=0; i<${#PLAN_ACTION[@]}; i++)); do
            case "${PLAN_ACTION[$i]}" in
                AJOUT|REMPLACEMENT)
                    printf "${YELLOW}%-14s${RESET} %-24s %s\n" \
                        "${PLAN_ACTION[$i]}" \
                        "${PLAN_TAG[$i]}" \
                        "${PLAN_FILE[$i]}"
                    ;;
                SUPPRESSION)
                    printf "${RED}%-14s${RESET} %-24s %s\n" \
                        "${PLAN_ACTION[$i]}" \
                        "${PLAN_TAG[$i]}" \
                        "${PLAN_FILE[$i]}"
                    ;;
                CONFORME)
                    printf "${GREEN}%-14s${RESET} %-24s %s\n" \
                        "${PLAN_ACTION[$i]}" \
                        "${PLAN_TAG[$i]}" \
                        "${PLAN_FILE[$i]}"
                    ;;
            esac
        done

        echo
        echo "$FOOTER"
        echo

        if [[ "$changes" -eq 0 ]]; then
            echo -e "${GREEN}[OK]${RESET} Tous les blocs sont conformes. Aucune écriture."
            return 0
        fi

        echo "$changes modification(s) prévue(s)."
        read -r -p "Confirmer l'application ? (O/N) : " answer

        if [[ "${answer^^}" != "O" ]]; then
            echo -e "${YELLOW}[INFO]${RESET} Opération annulée. Aucun XML modifié."
            return 2
        fi

        # --------------------------------------------------------
        # 20-2-5 Préparation des copies de travail
        # --------------------------------------------------------

        tmpdir="$(mktemp -d)" || {
            echo -e "${RED}[ERROR]${RESET} Impossible de créer le répertoire temporaire."
            return 1
        }

        for ((i=0; i<${#PLAN_ACTION[@]}; i++)); do

            file="${PLAN_FILE[$i]}"

            if [[ -n "${STAGE_BY_FILE[$file]+present}" ]]; then
                continue
            fi

            index="${#ORIGINALS[@]}"
            stage="$tmpdir/stage_$index.xml"

            if ! cp -p -- "$file" "$stage"; then
                echo -e "${RED}[ERROR]${RESET} Copie impossible : $file"
                rm -rf -- "$tmpdir"
                return 1
            fi

            ORIGINALS+=("$file")
            STAGES+=("$stage")
            BACKUPS+=("$tmpdir/backup_$index.xml")
            STAGE_BY_FILE["$file"]="$stage"

        done

        # --------------------------------------------------------
        # 20-2-6 Application sur les copies uniquement
        # --------------------------------------------------------

        for ((i=0; i<${#PLAN_ACTION[@]}; i++)); do

            action="${PLAN_ACTION[$i]}"
            file="${PLAN_FILE[$i]}"
            tag="${PLAN_TAG[$i]}"
            source="${PLAN_SOURCE[$i]}"
            stage="${STAGE_BY_FILE[$file]}"

            TAG="$tag"

            case "$action" in

                CONFORME)
                    continue
                    ;;

                AJOUT)
                    if ! insert_custom_block "$stage" "$source"; then
                        errors=1
                        break
                    fi
                    ;;

                REMPLACEMENT)
                    if ! remove_custom_block "$stage" "$tag"; then
                        errors=1
                        break
                    fi

                    if ! insert_custom_block "$stage" "$source"; then
                        errors=1
                        break
                    fi
                    ;;

                SUPPRESSION)
                    if ! remove_custom_block "$stage" "$tag"; then
                        errors=1
                        break
                    fi
                    ;;

            esac

        done

            if [[ "$errors" -eq 0 ]]; then
                for stage in "${STAGES[@]}"; do
                    if ! validate_xml "$stage"; then
                        errors=1
                        break
                    fi
                done
            fi

            if [[ "$errors" -ne 0 ]]; then
                echo -e "${RED}[ERROR]${RESET} Échec sur les copies de travail. Originaux inchangés."
                rm -rf -- "$tmpdir"
                return 1
            fi

            for ((i=0; i<${#ORIGINALS[@]}; i++)); do
                if ! cp -p -- "${ORIGINALS[$i]}" "${BACKUPS[$i]}"; then
                    echo -e "${RED}[ERROR]${RESET} Sauvegarde impossible : ${ORIGINALS[$i]}"
                    rm -rf -- "$tmpdir"
                    return 1
                fi
            done

            for ((i=0; i<${#ORIGINALS[@]}; i++)); do
                if ! cat -- "${STAGES[$i]}" > "${ORIGINALS[$i]}"; then
                    echo -e "${RED}[ERROR]${RESET} Écriture échouée : ${ORIGINALS[$i]}"
                    errors=1
                    break
                fi
                committed=$((i + 1))
            done

            if [[ "$errors" -eq 0 ]]; then
                for file in "${ORIGINALS[@]}"; do
                    if ! validate_xml "$file"; then
                        errors=1
                        break
                    fi
                done
            fi

            if [[ "$errors" -ne 0 ]]; then
                echo -e "${RED}[ERROR]${RESET} Échec de l'installation. Restauration des originaux."
                for ((i=0; i<committed; i++)); do
                    if ! cat -- "${BACKUPS[$i]}" > "${ORIGINALS[$i]}"; then
                        echo -e "${RED}[CRITICAL]${RESET} Restauration manuelle nécessaire : ${ORIGINALS[$i]}"
                    fi
                done
                rm -rf -- "$tmpdir"
                return 1
            fi

            rm -rf -- "$tmpdir"
            echo
            echo -e "${GREEN}[OK]${RESET} Synchronisation terminée."
            return 0
        }
# ------------------------------------------------------------
# Suppression globale des blocs CUSTOM par TAG (-E)
# ------------------------------------------------------------

erase_custom_tags() {

    local server mission mission_dir key file tag answer
    local tmpdir stage index i errors=0 committed=0

    local -a REQUESTED_TAGS=()
    local -a PLAN_FILE=()
    local -a PLAN_TAG=()
    local -a ORIGINALS=()
    local -a STAGES=()
    local -a BACKUPS=()

    local -A WANTED_TAGS=()
    local -A STAGE_BY_FILE=()
    local -A SEEN=()

    # --------------------------------------------------------
    # Analyse des TAG demandés
    # --------------------------------------------------------

    if [[ -z "$TAGS" || "$TAGS" == ,* || "$TAGS" == *, || "$TAGS" == *,,* ]]; then
        echo -e "${RED}[ERROR]${RESET} Liste de TAG invalide."
        return 1
    fi

    IFS=',' read -ra REQUESTED_TAGS <<< "$TAGS"

    for tag in "${REQUESTED_TAGS[@]}"; do

        tag="$(echo "$tag" | xargs)"

        if [[ -z "$tag" || "$tag" == *[[:space:]]* || "$tag" == */* ]]; then
            echo -e "${RED}[ERROR]${RESET} TAG invalide : $tag"
            return 1
        fi

        WANTED_TAGS["$tag"]=1

    done

    # --------------------------------------------------------
    # Recensement des blocs sur tous les serveurs
    # --------------------------------------------------------

    IFS=',' read -ra SERVER_LIST <<< "$SERVERS"

    for server in "${SERVER_LIST[@]}"; do

        server="$(echo "$server" | xargs)"

        if [[ -z "$server" || ! -d "$BASE/$server" ]]; then
            echo -e "${RED}[ERROR]${RESET} Serveur introuvable : $BASE/$server"
            return 1
        fi

        if ! get_mission "$server"; then
            return 1
        fi

        mission_dir="$BASE/$server/mpmissions/$MISSION"

        if ! scan_custom_blocks "$mission_dir"; then
            echo -e "${RED}[ERROR]${RESET} Structure CUSTOM invalide. Aucune modification."
            return 1
        fi

        for key in "${!CUSTOM_BLOCKS[@]}"; do

            file="${key%|*}"
            tag="${key##*|}"

            [[ -n "${WANTED_TAGS[$tag]+present}" ]] || continue

            # Une seule entrée par couple fichier/TAG.
            if [[ -n "${SEEN["$file|$tag"]+present}" ]]; then
                continue
            fi

            SEEN["$file|$tag"]=1
            PLAN_FILE+=("$file")
            PLAN_TAG+=("$tag")

        done

    done

    # --------------------------------------------------------
    # Aucun bloc correspondant : opération sans effet
    # --------------------------------------------------------

    if [[ "${#PLAN_FILE[@]}" -eq 0 ]]; then
        echo -e "${YELLOW}[INFO]${RESET} Aucun bloc correspondant aux TAG demandés. NOP."
        return 0
    fi

    # --------------------------------------------------------
    # Présentation du plan et confirmation
    # --------------------------------------------------------

    echo
    echo "$HEADER"
    echo "Suppression globale par TAG (-E)"
    echo "Serveurs : $SERVERS"
    echo "TAG      : $TAGS"
    echo

    for ((i=0; i<${#PLAN_FILE[@]}; i++)); do
        printf "${RED}SUPPRESSION${RESET} %-24s %s\n" \
            "${PLAN_TAG[$i]}" "${PLAN_FILE[$i]}"
    done

    echo
    echo "$FOOTER"
    echo
    echo "${#PLAN_FILE[@]} bloc(s) à supprimer."

    read -r -p "Confirmer la suppression ? (O/N) : " answer

    if [[ "${answer^^}" != "O" ]]; then
        echo -e "${YELLOW}[INFO]${RESET} Opération annulée. Aucun XML modifié."
        return 2
    fi

    # --------------------------------------------------------
    # Préparation des copies de travail
    # --------------------------------------------------------

    tmpdir="$(mktemp -d)" || {
        echo -e "${RED}[ERROR]${RESET} Impossible de créer le répertoire temporaire."
        return 1
    }

    for ((i=0; i<${#PLAN_FILE[@]}; i++)); do

        file="${PLAN_FILE[$i]}"

        [[ -n "${STAGE_BY_FILE[$file]+present}" ]] && continue

        index="${#ORIGINALS[@]}"
        stage="$tmpdir/stage_$index.xml"

        if ! cp -p -- "$file" "$stage"; then
            echo -e "${RED}[ERROR]${RESET} Copie impossible : $file"
            rm -rf -- "$tmpdir"
            return 1
        fi

        ORIGINALS+=("$file")
        STAGES+=("$stage")
        BACKUPS+=("$tmpdir/backup_$index.xml")
        STAGE_BY_FILE["$file"]="$stage"

    done

    # --------------------------------------------------------
    # Suppression sur les copies uniquement
    # --------------------------------------------------------

    for ((i=0; i<${#PLAN_FILE[@]}; i++)); do

        file="${PLAN_FILE[$i]}"
        tag="${PLAN_TAG[$i]}"
        stage="${STAGE_BY_FILE[$file]}"

        if ! remove_custom_block "$stage" "$tag"; then
            errors=1
            break
        fi

    done

    # --------------------------------------------------------
    # Validation des copies
    # --------------------------------------------------------

    if [[ "$errors" -eq 0 ]]; then
        for stage in "${STAGES[@]}"; do
            if ! validate_xml "$stage"; then
                errors=1
                break
            fi
        done
    fi

    if [[ "$errors" -ne 0 ]]; then
        echo -e "${RED}[ERROR]${RESET} Échec sur les copies. Originaux inchangés."
        rm -rf -- "$tmpdir"
        return 1
    fi

    # --------------------------------------------------------
    # Sauvegarde des originaux
    # --------------------------------------------------------

    for ((i=0; i<${#ORIGINALS[@]}; i++)); do
        if ! cp -p -- "${ORIGINALS[$i]}" "${BACKUPS[$i]}"; then
            echo -e "${RED}[ERROR]${RESET} Sauvegarde impossible : ${ORIGINALS[$i]}"
            rm -rf -- "$tmpdir"
            return 1
        fi
    done

    # --------------------------------------------------------
    # Installation des copies validées
    # --------------------------------------------------------

    for ((i=0; i<${#ORIGINALS[@]}; i++)); do

        committed=$((i + 1))

        if ! cat -- "${STAGES[$i]}" > "${ORIGINALS[$i]}"; then
            errors=1
            break
        fi

    done

    if [[ "$errors" -eq 0 ]]; then
        for file in "${ORIGINALS[@]}"; do
            if ! validate_xml "$file"; then
                errors=1
                break
            fi
        done
    fi

    # --------------------------------------------------------
    # Restauration en cas d'échec
    # --------------------------------------------------------

    if [[ "$errors" -ne 0 ]]; then

        echo -e "${RED}[ERROR]${RESET} Échec de l'installation. Restauration des originaux."

        for ((i=0; i<committed; i++)); do
            if ! cat -- "${BACKUPS[$i]}" > "${ORIGINALS[$i]}"; then
                echo -e "${RED}[CRITICAL]${RESET} Restauration manuelle nécessaire : ${ORIGINALS[$i]}"
            fi
        done

        rm -rf -- "$tmpdir"
        return 1
    fi

    rm -rf -- "$tmpdir"

    echo
    echo -e "${GREEN}[OK]${RESET} Suppression globale terminée."
    return 0
}

# ------------------------------------------------------------
# 21 MODE LIST
# ------------------------------------------------------------

if [[ "$MODE" == "list" ]]; then

    GLOBAL_ERROR=0

    IFS=',' read -ra SERVER_LIST <<< "$SERVERS"

    for server in "${SERVER_LIST[@]}"; do

        if ! list_custom_blocks "$server"; then
            GLOBAL_ERROR=1
        fi

    done

    echo
    echo "$FOOTER"
    echo

    if [[ "$GLOBAL_ERROR" -eq 0 ]]; then

        echo -e "${GREEN}[OK]${RESET} Listing terminé."
        exit 0

    else

        usage_short "Le listing s'est terminé avec des erreurs."
        exit 1

    fi

fi

# ------------------------------------------------------------
# 22 MODE VALIDATE
# ------------------------------------------------------------

if [[ "$MODE" == "validate" ]]; then

    GLOBAL_ERROR=0
    VALIDATION_ERRORS=()

    IFS=',' read -ra SERVER_LIST <<< "$SERVERS"

    for server in "${SERVER_LIST[@]}"; do

        server="$(echo "$server" | xargs)"

        if [[ ! -d "$BASE/$server" ]]; then

            echo -e "${RED}[ERROR]${RESET} Serveur introuvable : $BASE/$server"

            GLOBAL_ERROR=1
            continue
        fi

        if ! get_mission "$server"; then

            GLOBAL_ERROR=1
            continue
        fi

        if ! validate_all_xml "$server" "$MISSION"; then

            GLOBAL_ERROR=1

        fi

    done

    echo
    echo "$FOOTER"
    echo

    if [[ "${#VALIDATION_ERRORS[@]}" -gt 0 ]]; then

        echo -e "${RED}[ERROR]${RESET} ${#VALIDATION_ERRORS[@]} fichier(s) XML invalide(s)."
        echo
        echo "Récapitulatif :"

        current_server=""

        for error in "${VALIDATION_ERRORS[@]}"; do

            server="${error%%|*}"
            data="${error#*|}"

            relative="${data%%|*}"
            message="${data#*|}"

            if [[ "$server" != "$current_server" ]]; then

                echo
                echo "  $server"
                current_server="$server"

            fi

            echo "    $relative"
            echo "$message" | sed 's/^/      /'

        done

        echo

    elif [[ "$GLOBAL_ERROR" -eq 0 ]]; then

        echo -e "${GREEN}[OK]${RESET} Validation XML terminée : tous les fichiers sont valides."
        echo
    fi

    if [[ "$GLOBAL_ERROR" -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi

fi

# ------------------------------------------------------------
# 23 MODE EXTRACT
# ------------------------------------------------------------

if [[ "$MODE" == "extract" ]]; then

    server="$SERVERS"

    if [[ ! -d "$BASE/$server" ]]; then
        echo -e "${RED}[ERROR]${RESET} Serveur introuvable : $BASE/$server"
        exit 1
    fi

    if ! get_mission "$server"; then
        exit 1
    fi

    echo
    echo "Serveur : $server"
    echo "Mission : $MISSION"
    echo "TAG     : $TAG"
    echo

    if ! extract_custom_blocks "$server" "$MISSION" "$TAG"; then
        exit 1
    fi

    echo
    echo "$FOOTER"
    echo

    exit 0

fi

# ------------------------------------------------------------
# MODE ERASE TAGS
# ------------------------------------------------------------

if [[ "$MODE" == "erase_tags" ]]; then

    if [[ $# -ne 2 ]]; then
        usage_short "-E attend exactement deux arguments : SERVEURS TAGS"
        exit 1
    fi

    SERVERS="$1"
    TAGS="$2"

    erase_custom_tags
    exit $?

fi

# ------------------------------------------------------------
# 24 Vérification et traitement des opérations
# ------------------------------------------------------------

    # ------------------------------------------------------------
    # 24-1 Chargement et vérification des sources
    # ------------------------------------------------------------

    if [[ "$MODE" == "file" ]]; then

        if [[ -z "$CONFIG_FILE" || "$CONFIG_FILE" == */* ]]; then
            echo -e "${RED}[ERROR]${RESET} Le nom de liste doit désigner un fichier dans le répertoire dsxt du serveur : $CONFIG_FILE"
            exit 1
        fi

        if ! check_dsxt_dir "$SERVERS"; then
            exit 1
        fi

        CONFIG_PATH="$DSXT_DIR/$CONFIG_FILE"

        if [[ ! -f "$CONFIG_PATH" ]]; then
            echo -e "${RED}[ERROR]${RESET} Liste introuvable : $CONFIG_PATH"
            exit 1
        fi

        FILE_LIST=()

        while IFS= read -r source_name || [[ -n "$source_name" ]]; do

            source_name="${source_name%$'\r'}"
            source_name="$(echo "$source_name" | xargs)"

            [[ -z "$source_name" ]] && continue
            [[ "$source_name" == \#* ]] && continue

            FILE_LIST+=("$source_name")

        done < "$CONFIG_PATH"

        if [[ "${#FILE_LIST[@]}" -eq 0 ]]; then
            echo -e "${RED}[ERROR]${RESET} La liste ne contient aucune source : $CONFIG_PATH"
            exit 1
        fi

    else

        IFS=',' read -ra FILE_LIST <<< "$FILES"

    fi

    for source_name in "${FILE_LIST[@]}"; do

        source_name="$(echo "$source_name" | xargs)"

        if ! validate_filename "$source_name"; then
            exit 1
        fi

        if ! parse_source_name "$source_name"; then
            exit 1
        fi

    done

    if [[ "$MODE" == "file" ]]; then
        sync_custom_blocks
        exit $?
    fi

    # ------------------------------------------------------------
    # 24-2 Vérifications préalables
    # ------------------------------------------------------------

    GLOBAL_ERROR=0
    IFS=',' read -ra SERVER_LIST <<< "$SERVERS"

    for server in "${SERVER_LIST[@]}"; do

        server="$(echo "$server" | xargs)"

        if [[ ! -d "$BASE/$server" ]]; then
            echo -e "${RED}[ERROR]${RESET} Serveur introuvable : $BASE/$server"
            GLOBAL_ERROR=1
            continue
        fi

        if ! get_mission "$server"; then
            GLOBAL_ERROR=1
            continue
        fi

        if ! check_dsxt_dir "$server"; then
            GLOBAL_ERROR=1
            continue
        fi

        for source_name in "${FILE_LIST[@]}"; do

            source_name="$(echo "$source_name" | xargs)"

            if [[ ! -f "$DSXT_DIR/$source_name" ]]; then
                echo -e "${RED}[ERROR]${RESET} Source introuvable : $DSXT_DIR/$source_name"
                GLOBAL_ERROR=1
                continue
            fi

            if ! parse_source_name "$source_name"; then
                GLOBAL_ERROR=1
                continue
            fi

            if ! find_destination "$server" "$MISSION" "$TARGET"; then
                GLOBAL_ERROR=1
                continue
            fi

            if [[ "$MODE" != "compare" ]]; then
                if ! validate_fragment "$DSXT_DIR/$source_name"; then
                    GLOBAL_ERROR=1
                fi
            fi

        done

    done

    if [[ "$GLOBAL_ERROR" -ne 0 ]]; then
        echo
        echo -e "${RED}[ERROR]${RESET} Vérifications préalables échouées."
        echo "Aucune modification n'a été effectuée."
        exit 1
    fi

    # ------------------------------------------------------------
    # 24-3 Récapitulatif avant traitement
    # ------------------------------------------------------------

    case "$MODE" in
        add)     OPERATION="Ajout / remplacement des blocs CUSTOM" ;;
        erase)   OPERATION="Suppression des blocs CUSTOM" ;;
        compare) OPERATION="Comparaison des blocs CUSTOM" ;;
    esac

    echo
    echo "$HEADER"
    echo
    echo "Opération : $OPERATION"
    echo "Serveurs  : $SERVERS"
    echo "Sources   :"

    for source_name in "${FILE_LIST[@]}"; do
        source_name="$(echo "$source_name" | xargs)"
        echo "  - $source_name"
    done

    echo
    echo "Vérifications préalables réussies."
    echo "Début du traitement."
    echo

    # ------------------------------------------------------------
    # 24-4 Traitement des serveurs et des sources
    # ------------------------------------------------------------

    GLOBAL_ERROR=0

    for server in "${SERVER_LIST[@]}"; do

        server="$(echo "$server" | xargs)"

        if ! get_mission "$server"; then
            GLOBAL_ERROR=1
            continue
        fi

        if ! check_dsxt_dir "$server"; then
            GLOBAL_ERROR=1
            continue
        fi

        for source_name in "${FILE_LIST[@]}"; do

            source_name="$(echo "$source_name" | xargs)"

            if ! parse_source_name "$source_name"; then
                GLOBAL_ERROR=1
                continue
            fi

            if ! find_destination "$server" "$MISSION" "$TARGET"; then
                GLOBAL_ERROR=1
                continue
            fi

            if ! process_file "$server" "$source_name"; then
                GLOBAL_ERROR=1
            fi

        done

    done

    # ------------------------------------------------------------
    # 25 Résultat final
    # ------------------------------------------------------------

    echo
    echo "$FOOTER"
    echo

    case "$MODE" in

         add)

            if [[ "$GLOBAL_ERROR" -eq 0 ]]; then

                echo -e "${GREEN}[OK]${RESET} Toutes les opérations sont terminées."
                exit 0

            else

                echo -e "${RED}[ERROR]${RESET} Certaines opérations ont échoué."
                exit 1

            fi
            ;;

        erase)

            if [[ "$GLOBAL_ERROR" -eq 0 ]]; then

                echo -e "${GREEN}[OK]${RESET} Suppression terminée."
                exit 0

            else

                echo -e "${RED}[ERROR]${RESET} La suppression s'est terminée avec des erreurs."
                exit 1

            fi
            ;;

        compare)

            if [[ "$GLOBAL_ERROR" -eq 0 ]]; then

                echo -e "${GREEN}[OK]${RESET} Toutes les comparaisons sont terminées."
                exit 0

            else

                echo -e "${RED}[ERROR]${RESET} Certaines comparaisons ont échoué."
                exit 1

            fi
            ;;

    esac
