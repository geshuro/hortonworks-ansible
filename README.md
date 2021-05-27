Guía de instalación de ansible hortonworks
------------------------------

* Estos playbooks de Ansible implementarán un clúster de Hortonworks Data Platform utilizando Ambari Blueprints y un inventario estático.

* El uso del inventario estático implica que los nodos ya están construidos y son accesibles a través de SSH.


---


# Configuración Bastión

Antes de implementar, se debe preparar el nodo bastion, donde se ejecutará Ansible.

Este nodo debe poder conectarse a los nodos del clúster a través de SSH.


## RHEL 7

1. Subscribir el servidor bastion

   ```
   subscription-manager register --username {usuario} --password {usuario_clave} --auto-attach
   subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
   subscription-manager repos --enable rhel-7-server-optional-rpms
   ```
   
2. Instalar los paquetes requeridos

   ```
   sudo yum update -y
   sudo yum -y install python3
   sudo yum -y install gcc gcc-c++ python-virtualenv python-pip python-devel libffi-devel openssl-devel libyaml-devel sshpass git vim-enhanced
   ```


3. Crear entorno virtual de Python

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate
   ```


4. Instalar los paquetes de Python necesarios dentro de virtualenv

   ```
   pip3 install setuptools --upgrade
   pip3 install pip --upgrade 
   pip3 install ansible==2.9.6
   ```


5. (Opcional) Generate the SSH private key

   El nodo Bastión deberá iniciar sesión a través de SSH en los nodos del clúster.

   Esto se puede hacer usando un nombre de usuario y una contraseña o con claves SSH.

   Para el método de claves SSH, la clave privada SSH debe colocar o generar en el Bastión, normalmente en .ssh, por ejemplo: `~/.ssh/id_rsa`. 

   Para generar una nueva clave, ejecute lo siguiente:

   ```
   ssh-keygen -q -t rsa -f ~/.ssh/id_rsa
   ```


# <a name="static_inventory"></a>Establecer el inventario estático

Modifique el archivo en `~/inventory/static` para configurar el inventario estático.

El inventario estático coloca los nodos en diferentes grupos como se describe en la [Documentacion Ansible](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#hosts-and-groups).

Cada grupo define un rol de nodo específico, por ejemplo, master, slave, edge, pero los nombres de los grupos deben ser los mismos que los grupos de host.


Se debe configurar las siguientes variables para cada nodo:

| Variable                      | Descripción                                                                                                 |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------- |
| ansible_host                  | El nombre DNS o IP del host a conectarse.                                                               |
| ansible_user                  | El usuario de Linux con permisos de sudo que Ansible usará para conectarse al host (no tiene que ser root) |                         |
| ansible_ssh_pass              | (Opcional) La contraseña SSH que se utilizará cuando se conecte al host (esta es la contraseña del `ansible_user`). Se debe configurar esto o `ansible_ssh_private_key_file`. |
| ansible_ssh_private_key_file  | (Opcional) Ruta local de la clave privada SSH que se utilizará para iniciar sesión en el host. Se debe configurar esto o `ansible_ssh_pass`. |
| rack                          | (Opcional) Información de rack para el host. Por defecto es `/default-rack`. |


# Test del inventario

Listar el inventario:

```
ansible -i inventory/static all --list-hosts
```

Confirmar el acceso a los hosts del inventario:

```
ansible -i inventory/static all -m setup
```


# Establecer las variables del clúster

## archivo de configuración del clúster

Modificar el archivo en `~/playbooks/group_vars/all` para establecer la configuración del clúster.

| Variable                   | Descripción                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| cluster_name               | El nombre del clúster.                                                                                    |
| ambari_version             | La versión de Ambari, en el formato completo de 4 números, por ejemplo: `2.7.1.0`.                                     |
| hdp_version                | La versión HDP, en el formato completo de 4 números, por ejemplo: `3.0.1.0`.                                        |
| repo_base_url              | La URL base de los repositorios. Cambiar esto a la URL del servidor web local si usa un repositorio local. |

### configuración general

| Variable                   | Descripción                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| external_dns               | Esto controla el tipo de DNS que se utilizará. En caso "yes", utilizará cualquier DNS que esté configurado actualmente. Si "no" completará el archivo "/etc/hosts" con todos los nodos del clúster. |
| disable_firewall           | Esta variable controla el servicio de firewall local (iptables, firewalld, ufw) |
| timezone                   | Esta variable establece el timezone en los nodos. |


### configuración java

| Variable                   | Descripción                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| java                       | Se puede configurar en `embedded` (predeterminado: descargado por Ambari),` openjdk` u `oraclejdk`. Si se selecciona `oraclejdk`, entonces el paquete` .x64.tar.gz` debe descargarse previamente de [Oracle]. |
| oraclejdk_options          | Estas opciones solo son relevantes si `java` está configurado como` oraclejdk`. |
| `.base_folder`             | Esto indica la carpeta donde se debe desempaquetar el paquete de Java. El valor predeterminado de `/usr/java` también es utilizado por Oracle JDK rpm. |
| `.tarball_location`        | La ubicación del archivo tarball. Esta puede ser la ubicación en los sistemas remotos o en el bastión Ansible, dependiendo de la variable `remote_files`. |
| `.jce_location`            | La ubicación del archivo zip del paquete JCE. Esta puede ser la ubicación en los sistemas remotos o en el bastión Ansible, dependiendo de la variable `remote_files`. |
| `.remote_files`            | Si esta variable se establece en "yes", los archivos tarball y JCE ya deben estar presentes en el sistema remoto. Si se establece en "no", Ansible copiará los archivos (desde el bastión Ansible a los sistemas remotos). |

### configuración de ruta (opcional)

Puede anular la configuración de la ruta configurando esas variables.
Hay más variables disponibles en `playbooks/roles/ambari-blueprint/defaults/main.yml`

| Variable                   | Descripción                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| base_log_dir               | Configure la ruta del log base. |
| base_metrics_dir           | Configure la ruta de métricas base. |
| base_tmp_dir               | Configure la ruta base tmp. |
| hadoop_base_dir            | Configure la ruta de datos de la base de hadoop. |
| kafka_base_dir             | Configure la ruta de datos base de kafka. |

### configuración base de datos

| Variable                                 | Descripción                                                                                                |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| database                                 | El tipo de base de datos que se debe utilizar. Una elección entre `embedded` (Ambari predeterminado),` postgres`, `mysql` o` mariadb`. |
| database_options                         | Estas opciones solo son relevantes para la base de datos no `embedded`. |
| `.external_hostname`                     | El nombre de host/IP del servidor de la base de datos. Si se deja vacío `''`, los playbooks instalarán el servidor de la base de datos en el nodo Ambari y prepararán todo con la configuración definida. |
| `.add_repo`                              | Si se establece en `yes`, Ansible agregará un archivo de repositorio que apunta al repositorio donde se encuentran los paquetes de la base de datos (de forma predeterminada, la URL del repositorio es pública). Establezca esto en `no` para deshabilitar este comportamiento y usar repositorios que ya están disponibles para el sistema operativo. |
| `.ambari_db_name`, `.ambari_db_username`, `.ambari_db_password` | El nombre de la base de datos que Ambari debe usar y el nombre de usuario y contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el playbook de Ansible creará la base de datos y el usuario. |
| `.hive_db_name`, `.hive_db_username`, `.hive_db_password`       | El nombre de la base de datos que debe usar Hive y el nombre de usuario y la contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el playbook de Ansible creará la base de datos y el usuario. |
| `.oozie_db_name`, `.oozie_db_username`, `.oozie_db_password`    | El nombre de la base de datos que debe usar Oozie y el nombre de usuario y contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el libro de jugadas de Ansible creará la base de datos y el usuario. |
| `.druid_db_name`, `.druid_db_username`, `.druid_db_password`    | El nombre de la base de datos que debe usar Druid y el nombre de usuario y contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el libro de jugadas de Ansible creará la base de datos y el usuario. |
| `.superset_db_name`, `.superset_db_username`, `.superset_db_password`          | El nombre de la base de datos que debe usar Superset y el nombre de usuario y contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el libro de jugadas de Ansible creará la base de datos y el usuario. |
| `.rangeradmin_db_name`, `.rangeradmin_db_username`, `.rangeradmin_db_password` | El nombre de la base de datos que Ranger Admin debe usar y el nombre de usuario y contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el libro de jugadas de Ansible creará la base de datos y el usuario. |
| `.rangerkms_db_name`, `.rangerkms_db_username`, `.rangerkms_db_password`       | El nombre de la base de datos que debe usar Ranger KMS y el nombre de usuario y contraseña para conectarse a ella. Si se define `database_options.external_hostname`, estos valores se usarán para conectarse a la base de datos; de lo contrario, el libro de jugadas de Ansible creará la base de datos y el usuario. |

### configuración ranger

| Variable                       | Descripción                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ranger_options                 | Estas opciones solo son relevantes si `RANGER_ADMIN` es un componente de la pila dinámica de Blueprint.           |
| `.enable_plugins`              | Si se establece en `yes`, se habilitarán los complementos para todos los servicios disponibles. Con `no`, el Ranger se instalaría pero no funcionaría. |
| ranger_security_options        | Opciones relacionadas con la seguridad para Ranger (como contraseñas).                                                 |
| `.ranger_admin_password`       | La contraseña para los usuarios administradores de Ranger (tanto admin como amb_ranger_admin).                                 |
| `.ranger_keyadmin_password`    | La contraseña del usuario del administrador de claves de Ranger. |
| `.kms_master_key_password`     | La contraseña utilizada para cifrar la Master Key.                                                           |

### configuración de seguridad

| Variable                       | Descripción                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ambari_admin_password          | La contraseña de Ambari del usuario `ambari_admin_user` configurada previamente. Si el nombre de usuario es `admin` y esta contraseña es diferente a la predeterminada` admin`, la función `ambari-config` cambiará la contraseña predeterminada por la que se establece aquí. |
| default_password               | Una contraseña predeterminada para todas las contraseñas requeridas que no se especifican en el blueprint. |
| atlas_security_options`.admin_password`  | La contraseña para la usuario administrador de Atlas.                                        |
| knox_security_options`.master_secret`    | El Knox Master Secret. |
| superset_security_options      | Opciones relacionadas con la seguridad para Superset (como contraseñas).                              |
| `.secret_key`                  | El valor de la propiedad `SECRET_KEY` (que se utiliza para cifrar las contraseñas de los usuarios).               |
| `.admin_password`              | La contraseña para la usuario administrador de Superset.                                               |
| logsearch_security_options`.admin_password`  | La contraseña del usuario administrador de Log Search.                              |
| accumulo_security_options      | Opciones relacionadas con la seguridad para Accumulo (como contraseñas).                              |
| `.root_password`               | Contraseña para el usuario root de Accumulo. Esta contraseña se utilizará para inicializar Accumulo y crear el usuario de seguimiento.       |
| `.instance_secret`             | Un secreto exclusivo de una instancia determinada que todos los procesos del servidor de Accumulo deben conocer para comunicarse entre sí. |
| `.trace_user`                  | Usuario que utiliza el proceso de seguimiento para escribir datos de seguimiento en Accumulo.                    |
| `.trace_password`              | Contraseña para el usuario de seguimiento.                                                           |

### configuración ambari

| Variable                       | Descripción                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ambari_admin_user              | El nombre de usuario del administrador de Ambari, normalmente `admin`. Este usuario y la contraseña a continuación se utilizan para iniciar sesión en Ambari para solicitudes de API. |
| ambari_admin_default_password  | La contraseña predeterminada para el usuario `admin` de Ambari. |
| config_recommendation_strategy | Campo de configuración que especifica la estrategia de aplicar recomendaciones de configuración a un clúster. Elija entre `NEVER_APPLY`,` ONLY_STACK_DEFAULTS_APPLY`, `ALWAYS_APPLY`,` ALWAYS_APPLY_DONT_OVERRIDE_CUSTOM_VALUES`. |
| smartsense`.id`, `.account_name`, `.customer_email` | Detalles de la suscripción a Hortonworks. |
| wait / wait_timeout            | Establezca esto en `true` si desea que el playbook espere a que el clúster se crea correctamente después de aplicar el blueprint. La configuración del tiempo de espera controla cuánto tiempo (en segundos) debe esperar la creación del clúster. |
| accept_gpl                     | Configure en `yes` para permitir que Ambari Server descargue e instale paquetes con licencia GPL. |
| cluster_template_file          | La ruta al archivo de plantilla de creación de clústeres que se utilizará para construir el clúster. |

### configuración blueprint

| Variable                       | Descripción                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| blueprint_name                 | El nombre del blueprint tal como se almacenará en Ambari.                                                  |
| blueprint_file                 | La ruta al archivo de blueprint que se cargará en Ambari. |
| blueprint_dynamic              | Configuración para la plantilla de blueprint dinámico: solo se utiliza si `blueprint_file` está configurado como` blueprint_dynamic.j2` |


# Instalar el cluster

Ejecute el script que instalará el clúster usando Blueprints teniendo en cuenta los requisitos previos necesarios.

Asegúrese de establecer la variable de entorno `ENTORNO_A_USAR` en `static`.

```
export ENTORNO_A_USAR=static
bash instalar_cluster.sh
```

Es posible que deba cargar las variables de entorno si se trata de una nueva sesión:

```
source ~/ansible/bin/activate
```


Esta secuencia de comandos aplicará todos los playbooks necesarios en una ejecución, pero también puede aplicar los playbooks individuales ejecutando los siguientes scripts:

- Preparar los nodos: `preparar_nodos.sh`
- Instalar Ambari: `instalar_ambari.sh`
- Configurar Ambari: `configurar_ambari.sh`
- Aplicar Blueprint: `aplicar_blueprint.sh`
- Post Instalación: `post_instalacion.sh`
