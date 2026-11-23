
#!/bin/bash

set -euo pipefail

# Fonction 1 : afficher l'utilisation
usage() {
    echo "Usage : bash scripts/analyse.sh <fichier.log> [--top N]" >&2
}

# Fonction 2 : compter les requêtes par famille HTTP
count_family() {
    local family="$1"
    local chiffre="${family:0:1}"

    awk -v c="$chiffre" '
    $9 ~ ("^" c "[0-9][0-9]$") { n++ }
    END { print n+0 }
    ' "$LOG_FILE"
}

# Fonction 3 : afficher les endpoints les plus utilisés
top_endpoints() {
    awk '{
        endpoint=$7
        sub(/\?page=.*/, "", endpoint)
        print endpoint
    }' "$LOG_FILE" |
    sort |
    uniq -c |
    sort -nr |
    head -n "$TOP_N"
}

# Fonction 4 : trouver l'IP avec le plus de réponses 401
suspicious_ip() {
    awk '$7=="/api/auth/login" && $9==401 {
        count[$1]++
    }
    END {
        for (ip in count)
            print count[ip], ip
    }' "$LOG_FILE" |
    sort -nr |
    head -n 1
}

# Fonction 5 : calculer le temps moyen des réponses 200
average_response() {
    awk '$9==200 {
        duree=$11
        sub(/ms$/, "", duree)
        somme+=duree
        nombre++
    }
    END {
        if (nombre > 0)
            printf "%.1f ms\n", somme/nombre
        else
            print "Aucune requête 200"
    }' "$LOG_FILE"
}

# Vérification des arguments
if [[ $# -ne 1 && $# -ne 3 ]]; then
    usage
    exit 1
fi

LOG_FILE="$1"
TOP_N=3

if [[ $# -eq 3 ]]; then
    if [[ "$2" != "--top" || ! "$3" =~ ^[1-9][0-9]*$ ]]; then
        usage
        exit 1
    fi
    TOP_N="$3"
fi

# Vérification du matricule
if [[ -z "${MATRICULE:-}" ]]; then
    echo "Erreur : la variable MATRICULE n'est pas définie." >&2
    exit 4
fi

# Vérification du fichier
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Erreur : fichier introuvable." >&2
    exit 2
fi

if [[ ! -s "$LOG_FILE" ]]; then
    echo "Erreur : le fichier est vide." >&2
    exit 3
fi

# Création du rapport
DATE_RAPPORT=$(date +%Y%m%d_%H%M)
REPORT="rapports/rapport_${MATRICULE}_${DATE_RAPPORT}.txt"

mkdir -p rapports

{
    echo "======================================"
    echo "       RAPPORT D'ANALYSE DES LOGS"
    echo "======================================"
    echo "Date : $(date)"
    echo "Utilisateur et machine : $(whoami)@$(hostname)"
    echo "Matricule : $MATRICULE"
    echo "Fichier analysé : $LOG_FILE"
    echo

    echo "1. EMPREINTE SHA256"
    sha256sum "$LOG_FILE"
    echo

    echo "2. NOMBRE DE REQUÊTES PAR FAMILLE HTTP"

    for family in 2xx 3xx 4xx 5xx; do
        count=$(count_family "$family")
        echo "$family : $count"
    done

    echo
    echo "3. TOP $TOP_N DES ENDPOINTS"
    top_endpoints

    echo
    echo "4. ADRESSE IP SUSPECTE"
    suspect=$(suspicious_ip)

    if [[ -n "$suspect" ]]; then
        echo "$suspect"
    else
        echo "Aucune adresse IP suspecte trouvée."
    fi

    echo
    echo "5. TEMPS MOYEN DES RÉPONSES 200"
    average_response

    echo
    echo "======================================"
    echo "          FIN DU RAPPORT"
    echo "======================================"

} > "$REPORT"

echo "Rapport créé : $REPORT"
