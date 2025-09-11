#!/bin/bash

# Verificar argumento.
if [ $# -eq 0 ]; then
    echo "Uso: $0 <comando> [argumentos]"
    exit 1
fi

# Variables 
comando="$@"
nombre_proceso=$(basename "$1")
log_file="/tmp/monitor_${nombre_proceso}_$(date +%Y%m%d_%H%M%S).log" #Los tmp son archivos temporales
data_file="/tmp/monitor_${nombre_proceso}_data.dat"
plot_script="/tmp/plot_${nombre_proceso}.plt"

# Funcion para obtener consumo de CPU y memoria.
obtener_consumo() {
    local pid=$1
    local timestamp=$(date +%s)
    
    # Obtener informacion del proceso.
    local info=$(ps -p $pid -o %cpu,%mem --no-headers 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        local cpu=$(echo $info | awk '{print $1}')
        local mem=$(echo $info | awk '{print $2}')
        echo "$timestamp $cpu $mem" >> "$log_file"
        echo "Tiempo: $(date +%H:%M:%S) | CPU: $cpu% | Mem: $mem%"
    fi
}

# Generar el grafico.
generar_grafico() {
    # Verificar que hay datos para graficar
    if [ ! -s "$log_file" ] || [ $(wc -l < "$log_file") -le 1 ]; then
        echo "No hay suficientes datos para generar el grafico."
        return 1
    fi
    
    awk 'NR==1 {start=$1} {print $1-start " " $2 " " $3}' "$log_file" > "$data_file"

    cat > "$plot_script" << EOF 
set terminal x11 persist size 1200,600 enhanced font 'Verdana,12'
set title "Monitorizacion de $nombre_proceso"
set xlabel "Tiempo (segundos)"
set ylabel "Consumo CPU (%)"
set y2label "Consumo Memoria (%)"
set ytics nomirror
set y2tics
set grid
set y2range [0:*] 

plot "$data_file" using 1:2 with lines linewidth 2 axes x1y1 title "CPU (%)", \
     "$data_file" using 1:3 with lines linewidth 2 axes x1y2 title "Memoria (%)"

set terminal png size 1200,600 enhanced font 'Verdana,12'
set output "/tmp/monitor_${nombre_proceso}_plot.png"
replot
EOF

    # Generar grafico
    if command -v gnuplot >/dev/null 2>&1; then
        gnuplot -persist "$plot_script" 2>/dev/null || \
        echo "No se pudo mostrar ventana interactiva, el grafico se guardo en: /tmp/monitor_${nombre_proceso}_plot.png"
    else
        echo "Gnuplot no está instalado. No se puede generar el grafico."
    fi
}

# Iniciar el proceso.
echo "Ejecutando: $comando"
$comando &
pid=$!

# Esperar a que el proceso se estabilice.
sleep 0.5

# Buscar el PID correcto
real_pid=$(ps --ppid $pid -o pid= | head -1 | tr -d ' ')
if [ -n "$real_pid" ]; then
    pid=$real_pid
fi

echo "Monitoreando proceso $nombre_proceso (PID: $pid)"
echo "Archivo de log: $log_file"
echo "Presiona Ctrl+C para detener el monitoreo"

# Encabezado del log.
echo "# Timestamp CPU(%) Mem(%)" > "$log_file"

# Monitorear hasta que el proceso se termine.
while ps -p $pid >/dev/null 2>&1; do
    obtener_consumo $pid
    sleep 1 
done

echo "Proceso terminado."
generar_grafico

#Datos finales
echo " "
echo "Monitoreo completado:"
echo " "
echo "- Log: $log_file"
echo " "
echo "- Datos: $data_file"
echo " "
echo "- Grafico: /tmp/monitor_${nombre_proceso}_plot.png"
