ansible-hortonworks playbooks
-----------

The following playbooks are being used throughout this project:


## Main playbooks

### preparar_nodos.yml
A simple playbook that applies the [common](roles/common), [database](roles/database), [krb5-client](roles/krb5-client) and [mit-kdc](roles/mit-kdc) roles.

This installs the required OS packages (including [Java](roles/common/tasks/java.yml)), applies the recommended OS settings and prepares the database and / or the local MIT-KDC.

### instalar_ambari.yml
A simple playbook that applies the [ambari-agent](roles/ambari-agent) and [ambari-server](roles/ambari-server) roles.

This adds the Ambari repo, installs the Ambari Agent and Server packages and configures the Ambari Server with the required Java and database options.

The result of this playbook is an Ambari install ready to deploy a cluster.

### configurar_ambari.yml
A simple playbook that applies the [ambari-config](roles/ambari-config) role.

This further configures Ambari with some settings, changes admin password and adds the repository information needed by the build.

### aplicar_blueprint.yml
A simple playbook that applies the [ambari-blueprint](roles/ambari-blueprint) role.

This uploads the Ambari Blueprint and Cluster Creation Template and launches a cluster create request to Ambari. It can also wait for the cluster to be built.

### post_instalacion.yml
A simple playbook that applies the [post_instalacion](roles/post_instalacion) role.

It doesn't do much at the moment - only fixes a file ownership that can only be done after the cluster is built.

### instalar_cluster.yml
A simple playbook that imports all of the previous playbooks, in the required order, so it installs a cluster correctly.


## Auxiliary playbooks

### set_variables.yml
This is a playbook that is imported by all of the main playbooks.

It sets a number of variables that are required by the main playbooks.

These variables are calculated based on the blueprint, be it a dynamic blueprint or a static one.

When using a dynamic blueprint it [checks](set_variables.yml#L102) the [`blueprint_dynamic` variable](group_vars/all#L161).

When using a static blueprint it simply does a [string search](set_variables.yml#L250) on the contents of the blueprint file.

### revisar_blueprint_dinamico.yml
This is a playbook that is imported by the `configurar_ambari` and `aplicar_blueprint` playbooks [only when the blueprint is dynamic](aplicar_blueprint.yml#L5).

It checks the [`blueprint_dynamic` variable](group_vars/all#L161) for the most probable mistakes, invalid components and dependencies in an Ambari blueprint definition.

It does not check all possible issues, if the `blueprint_dynamic` is not correct, errors might still happen when uploading the blueprint to Ambari or when launching the Ambari build.


## Cloud playbooks

The Cloud playbooks can be found under the `playbooks/clouds` folder and are classified into 3 types:

### build_{{ entorno }}
These playbooks are called directly by the `build_cloud.sh` script.

They are responsible with building the basic Cloud infrastructure so that the cluster can be deployed (like the [AWS VPC](entorno/build_aws.yml#L10) or [Azure Resource Group](entorno/build_azure.yml#L10) or [security groups](entorno/build_aws.yml#L48)).

Nothing fancy is happening here, most production usecases would probably replace these with the in-house methodology (like Terraform or AWS CloudFormation).

### build_{{ entorno }}_nodes
These playbooks are called by the `build_{{ entorno }}` playbooks, in a [loop](entorno/build_aws.yml#L69) iterating over the specific [Cloud inventory variables](../inventory/aws/group_vars/all#L26).

They are responsible with building the Cloud nodes as defined in their specific [Cloud inventory variables](../inventory/aws/group_vars/all#L26).

Again, most production usecases would probably replace these with the in-house methodology (like Terraform or AWS CloudFormation).

### add_{{ entorno }}_nodes
These are an important component in the whole concept of this project.

They make the connection between an inventory (Cloud or static) and the Ansible groups that the playbooks are expecting, such as [`hadoop-cluster`](preparar_nodos.yml#L5).

In a static inventory, this is simply [putting all nodes](entorno/agregar_nodos_static.yml#L10) from the `all` group into the `hadoop-cluster` group.

In the Cloud inventories this is more complex, as there can be a large number of non-Hortonworks nodes and groups. The only way to separate the nodes is by using [Tags](entorno/build_aws_nodes.yml#L57), which all Clouds support. Based on these tags, Ansible groups the Cloud nodes and these playbooks simply create the `hadoop-cluster` group [from these tag-based groups](entorno/agregar_nodos_aws.yml#L15).

