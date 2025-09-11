#!/bin/bash


# Verificar si el usuario es root.
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: El usuario debe ser root." >&2
    exit 1
fi

# Verificar el numero de argumentos.
if [ $# -ne 3 ]; then
    echo "Uso: $0 <usuario> <grupo> <ruta_archivo>" >&2
    exit 1
fi 

# Asignacion de variables.
usuario="$1"
grupo="$2"
archivo="$3"

# Verificar si el archivo existe.
if [ ! -e "$archivo" ]; then
    echo "Error: El archivo '$archivo' no existe" >&2
    exit 1
fi

# Verificar y crear el grupo.
if getent group "$grupo" > /dev/null 2>&1; then
    echo "El grupo '$grupo' ya existe"
else 
    addgroup "$grupo"
    echo "Grupo '$grupo' creado"
fi

# Verificar y crear el usuario.
if id "$usuario" &> /dev/null; then
    echo "El usuario '$usuario' ya existe"
    usermod -aG "$grupo" "$usuario"
else
    adduser --disabled-password --gecos " " "$usuario"
    usermod -aG "$grupo" "$usuario"
    echo "Usuario '$usuario' creado"
fi

# Cambiar la pertenencia del archivo.
chown "$usuario:$grupo" "$archivo"
echo "El archivo se ha cambiado a '$usuario:$grupo'"

# Cambiar los permisos del archivo.
chmod 740 "$archivo"      #7 = rwx(owner), 4 = r--(group), 0 = ---(others)
echo "Se ha cambiado los permisos del archivo"

# Mostrar la información.
echo "Usuario: $usuario"
echo "Grupo: $grupo"
echo "Archivo: $archivo"
echo "Permisos actuales: $(stat -c "%A" "$archivo")"
echo "Propietario: $(stat -c "%U:%G" "$archivo")"
exit 0


