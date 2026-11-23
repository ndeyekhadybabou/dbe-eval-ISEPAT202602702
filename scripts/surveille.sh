
#!/bin/bash

trap 'echo "$(date "+%Y-%m-%d %H:%M:%S") - arrêt propre" >> logs/surveillance.log; exit 0' TERM

while true
do
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Nombre de lignes : $(wc -l < logs/access.log)" >> logs/surveillance.log
    sleep 5
done
