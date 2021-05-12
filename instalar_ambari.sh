#!/usr/bin/env bash

source $(dirname "${BASH_SOURCE[0]}")/set_entorno.sh
source $(dirname "${BASH_SOURCE[0]}")/set_inventario.sh

ansible-playbook "playbooks/instalar_ambari.yml" \
                 --inventory="inventory/${inventario_a_usar}" \
                 --extra-vars="entorno=${entorno_a_usar} ansible_sudo_pass=admcuc" \
                 "$@"
