#!/bin/bash

# Generar el archivo JSON de Terraform
if ! terraform show -json > tfstate.json; then
    echo "Error al ejecutar terraform show"
    exit 1
fi

# Leer el archivo JSON una sola vez
json_data=$(cat tfstate.json)

# Extraer direcciones IP
external_pvs=$(echo "$json_data" | jq -r '.values.root_module.resources[] | select(.address=="ibm_pi_instance.test-instance") | .values | .pi_network[] | .external_ip')
#internal1_pvs=$(echo "$json_data" | jq -r '.values.root_module.resources[] | select(.address=="ibm_pi_instance.test-instance") | .values | .pi_network[] |select(.network_name=="power-network-priv") |.ip_address')
#internal2_pvs=$(echo "$json_data" | jq -r '.values.root_module.resources[] | select(.address=="ibm_pi_instance.test-instance") | .values | .pi_network[] |select(.network_name=="power-network") |.ip_address')
#internal_vmweb=$(echo "$json_data" | jq -r '.values.root_module.resources[] | select(.address=="ibm_is_virtual_network_interface.example") | .values | .primary_ip[] | .address')
external_vmweb=$(echo "$json_data" | jq -r '.values.root_module.resources[] | select(.address=="ibm_is_floating_ip.public_ip") | .values | .address')

# Nombres de host a eliminar
hosts_to_remove=("power" "vmweb")

# Eliminar hosts del archivo /etc/hosts
for host in "${hosts_to_remove[@]}"; do
    sed -i "/$host/d" /etc/hosts
done

# Eliminar hosts del archivo /root/.ssh/known_hosts
for host in "${hosts_to_remove[@]}"; do
    ssh-keygen -R "$host"
done

# Crear el archivo de configuración de Ansible
config_file="ansible_hosts.ini"

# Escribir las IPs en el archivo de configuración
{
    echo "[power]"
    echo "power ansible_ssh_private_key_file=path_key"
    echo "[vmweb]"
    echo "vmweb ansible_ssh_private_key_file=path_key"
} > "$config_file"

# Agregar las nuevas entradas al archivo /etc/hosts
{
    echo "$external_pvs power"
    echo "$external_vmweb vmweb"
} >> /etc/hosts

echo "Archivo de configuración Ansible creado: $config_file"
echo "Nuevas entradas agregadas a /etc/hosts."
echo "Power: $external_pvs"
echo "x86: $external_vmweb"
