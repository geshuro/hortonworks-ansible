#!/usr/bin/env bash

if [ -z "$INVENTARIO_A_USAR" ]; then
    echo -e "\e[94m[INFO]\e[0m - Variable de entorno INVENTARIO_A_USAR no establecida, por defecto es 'inventory/${entorno_a_usar}'"
    inventario_a_usar="${entorno_a_usar}"
else
    echo -e "\e[94m[INFO]\e[0m - Variable de entorno INVENTARIO_A_USAR establecida en '$ {INVENTARIO_A_USAR}'"
    inventario_a_usar="${INVENTARIO_A_USAR}"
fi


