ansible hortonworks playbooks
-----------

Los siguientes playbooks se están utilizando en este proyecto:


## Principales playbooks

### preparar_nodos.yml
Un playbook simple que aplica el [common](roles/common), [database](roles/database), [krb5-client](roles/krb5-client) y [mit-kdc](roles/mit-kdc) roles.

Esto instala los paquetes de SO requeridos (incluido [Java](roles/common/tasks/java.yml)), aplica la configuración de SO recomendada y prepara la base de datos y / o the local MIT-KDC.

### instalar_ambari.yml
Un playbook simple que aplica el [ambari-agent](roles/ambari-agent) y [ambari-server](roles/ambari-server) roles.

Esto agrega el repositorio de Ambari, instala los paquetes de Servidor y Agente de Ambari y configura el Servidor de Ambari con las opciones de base de datos y Java requeridas.

El resultado de este playbook es una instalación de Ambari lista para implementar un clúster.

### configurar_ambari.yml
Un playbook simple que aplica el [ambari-config](roles/ambari-config) role.

Esto configura Ambari, cambia la contraseña de administrador y agrega la información del repositorio que necesita la creación.

### aplicar_blueprint.yml
Un playbook simple que aplica el [ambari-blueprint](roles/ambari-blueprint) role.

Esto carga la plantilla de creación de clúster y Blueprint de Ambari y lanza una solicitud de creación de clúster a Ambari. También puede esperar a que se cree el clúster.

### post_instalacion.yml
Un playbook simple que aplica el [post_instalacion](roles/post_instalacion) role.

Solo corrige la propiedad de un archivo que solo se puede hacer después de que se crea el clúster.

### instalar_cluster.yml
Un playbook simple que importa todos los playbook anteriores, en el orden requerido, para que instale un clúster correctamente.


## Playbooks auxiliares

### set_variables.yml
Este es un playbook importado por todos los playbook principales.

Establece una serie de variables que son requeridas por los playbook principales.

Estas variables se calculan en función del blueprint, ya sea dinámico o estático.

### revisar_blueprint_dinamico.yml
Este es un playbook importado por el `configurar_ambari` y `aplicar_blueprint` playbooks.

Comprueba el `blueprint_dynamic` [variable](group_vars/all#L161) para los errores más probables, componentes no válidos y dependencias en una definición de Blueprint de Ambari.

No verifica todos los problemas posibles, si el `blueprint_dynamic` no es correcto, aún pueden ocurrir errores al cargar el blueprint en Ambari o al iniciar la creación de Ambari.
