#!/usr/bin/env bash

if [ -z "$ENTORNO_A_USAR" ]; then
    echo "La variable de entorno ENTORNO_A_USAR debe establecerse en uno de los siguientes: static"
    exit 1
fi

entorno_a_usar=$(echo "$ENTORNO_A_USAR" | tr '[:upper:]' '[:lower:]')
case $entorno_a_usar in
static)
  mensaje="Se utilizará el inventario estático."
  ;;
*)
  mensaje="La variable de entorno ENTORNO_A_USAR se estableció en \"$ENTORNO_A_USAR\" pero debe establecerse en uno de los siguientes: static"
  echo -e $mensaje
  exit 1
  ;;
esac

echo -e "${mensaje}"

