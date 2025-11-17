# Implementación de replicación sobre el caso de estudio: MedoraDB.

Para una sencilla demostración de la aplicación de réplicas de bases de datos, se crearán dos instancias de servidores en una misma máquina donde una de ellas cumplirá con las funciones de Publicador-Distribuidor y la otra se encargará de ser Suscriptor.

# Elementos de la replicación:

## Publicador-Distribuidor:

## 

## Suscriptor:

## Artículos:

## Publicación:

## Agentes de replicación:

* ### Agente de instantáneas:

* ### Agente del lector del Log:

* ### Agente de distribución:

# Transacciones con la replicación:

* Inserción de registros en el publicador.

* Visualización de registros en el suscriptor

* Intento de inserción de registros en el suscriptor

* Inserción de registro exitosa en el suscriptor


* Consulta del registro insertado en el publicador

* Inserción de registro en el publicador con la misma PK que ya tiene un registro en el suscriptor

* Error de sincronización

* Eliminación del registro conflictivo en el suscriptor

* Visualización en el suscriptor del registro insertado en el publicador.

