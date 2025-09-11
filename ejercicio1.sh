#!/bin/bash

# Verificar si el usuario que ejecuta el script es root.
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: El usuario debe ser root." >&2
    exit 1
fi

# Archivo de log para errores (solo se crea si somos root)
LOG_FILE="/var/log/ejercicio1_errors.log"

# Verificar el numero de argumentos.
if [ $# -ne 3 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Uso incorrecto. Debe ser: $0 <usuario> <grupo> <ruta_archivo>" >> "$LOG_FILE"
    echo "Formato: sudo $0 <usuario> <grupo> <ruta_archivo>" >&2
    exit 1
fi 

# Asignacion de variables.
usuario="$1"
grupo="$2"
archivo="$3"

# Verificar que la ruta al archivo existe.
if [ ! -e "$archivo" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: El archivo '$archivo' no existe" >> "$LOG_FILE"
    echo "Error: El archivo '$archivo' no existe" >&2
    exit 1
fi

# Si el grupo no existe, se crea.
if getent group "$grupo" > /dev/null 2>&1; then
    echo "El grupo '$grupo' ya existe"
else 
    if addgroup "$grupo" 2>> "$LOG_FILE"; then
        echo "Grupo '$grupo' creado"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: No se pudo crear el grupo '$grupo'" >> "$LOG_FILE"
        echo "Error: No se pudo crear el grupo '$grupo'" >&2
        exit 1
    fi
fi

# Si el usuario no existe, se crea.
if id "$usuario" &> /dev/null; then
    echo "El usuario '$usuario' ya existe"
    # Agreguelo al grupo
    usermod -aG "$grupo" "$usuario" 2>> "$LOG_FILE"
else
    if adduser --disabled-password --gecos " " "$usuario" 2>> "$LOG_FILE"; then
        usermod -aG "$grupo" "$usuario" 2>> "$LOG_FILE"
        echo "Usuario '$usuario' creado"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: No se pudo crear el usuario '$usuario'" >> "$LOG_FILE"
        echo "Error: No se pudo crear el usuario '$usuario'" >&2
        exit 1
    fi
fi

# Modificar la pertenencia del archivo.
if chown "$usuario:$grupo" "$archivo" 2>> "$LOG_FILE"; then
    echo "El archivo se ha cambiado a '$usuario:$grupo'"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: No se pudo cambiar la pertenencia del archivo" >> "$LOG_FILE"
    echo "Error: No se pudo cambiar la pertenencia del archivo" >&2
    exit 1
fi

# Modificar los permisos del archivo.
if chmod 740 "$archivo" 2>> "$LOG_FILE"; then
    echo "Se ha cambiado los permisos del archivo"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: No se pudo cambiar los permisos del archivo" >> "$LOG_FILE"
    echo "Error: No se pudo cambiar los permisos del archivo" >&2
    exit 1
fi

# Mostrar la informacion.
echo "Usuario: $usuario"
echo "Grupo: $grupo"
echo "Archivo: $archivo"
echo "Permisos actuales: $(stat -c "%A" "$archivo")"
echo "Propietario: $(stat -c "%U:%G" "$archivo")"
exit 0
