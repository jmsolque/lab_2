#!/bin/bash

directorio="/home/manu/Downloads" # Escojo este directorio por que es el que mas movimientso tiene en la maquina virtual.
monitoreo="/home/manu/laboratorios/Lab_2/monito.log"

if [ -d $directorio ]; then
	inotifywait -m -e create,modify,delete,move "$directorio" |
		while read -r dir accion archivo; do
			echo "[$(date '+%d/+%m/+$Y %H:%M:%S')] Accion: $accion en el archivo $archivo" >> "$monitoreo"
done
else
	echo "El directorio $directorio" no existe
fi
