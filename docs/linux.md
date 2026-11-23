Le script génère un rapport contenant :

- L'empreinte SHA256 du fichier.
- Le nombre de requêtes par famille HTTP.
- Le classement des endpoints.
- L'adresse IP suspecte.
- Le temps moyen des réponses 200.

## Partie 5 – Surveillance des processus

- Création du script `scripts/surveille.sh`.
- Lancement du script en arrière-plan avec `nohup`.
- Enregistrement du nombre de lignes de `logs/access.log` toutes les 5 secondes.
- Envoi du signal SIGTERM avec `kill -TERM 1937`.
- Vérification de l'arrêt propre dans `logs/surveillance.log`.