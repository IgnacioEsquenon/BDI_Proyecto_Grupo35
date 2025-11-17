# Replicación de Bases de Datos

# Conceptos generales

La replicación de bases de datos es un proceso que consiste en crear copias de la misma, entre dos o más instancias de servidores El objetivo que busca este proceso es garantizar la consistencia, disponibilidad y redundancia de los datos. Este mecanismo implica la copia y el mantenimiento de objetos de la base de datos, como tablas y procedimientos almacenados (definidas por el programador, quien decide cuáles son copiados) en múltiples nodos o ubicaciones. Los objetivos principales de la replicación incluyen la mejora de la tolerancia a fallos y la alta disponibilidad, permitiendo que las aplicaciones sigan funcionando incluso si un servidor falla, el aumento del rendimiento al distribuir la carga de consultas de lectura entre varios servidores y la posibilidad de acercar los datos a los usuarios geográficamente para reducir los tiempos de ejecución.  
Existen varios tipos de replicación, clasificados en general según la direccionalidad y el momento de la sincronización. La replicación transaccional mueve los datos de un nodo principal (maestro) a uno o varios nodos secundarios (esclavos), siendo el maestro el único que acepta escrituras. La replicación multi-maestro permite que las escrituras se realicen en diferentes nodos, lo que implica un mayor nivel de complejidad por la sincronización paralela. En cuanto al momento de la sincronización, la replicación puede ser síncrona, donde la transacción no se considera completa hasta que se ha confirmado en todos los nodos replicados, garantizando la consistencia inmediata pero pudiendo afectar el rendimiento, o asíncrona, donde la transacción se confirma localmente y luego los cambios se propagan a otros nodos con un pequeño retraso, priorizando el rendimiento sobre la consistencia estricta e inmediata de los datos.

# Ventajas y desventajas de la replicación transaccional

Las principales ventajas de la replicación transaccional son: 

* Baja Latencia: Las transacciones realizadas en el publicador se actualizan en tiempo real sobre los suscriptores gracias al registro de transacciones.  
* Consistencia: Garantiza que las transacciones que se realizan en el publicador se ejecuten de igual manera sobre el suscriptor manteniendo la consistencia de los datos.  
* Distribución de transacciones: Permite que las consultas de lectura se ejecuten sobre los suscriptores liberando así al publicador que se encarga de las operaciones de escritura.   
* Protección contra pérdida de información: En el caso de que ocurriese algún problema con el publicador, los datos y la estructura de la base de datos se encontraría resguardada en la réplica.

Las desventajas que presenta la replicación transaccional son:

* Flujo de datos unidireccional: Los datos sólo pueden ser actualizados en el publicador no así en los suscriptores.  
* Dependencia de la red: Este tipo de replicación requiere una conexión constante y fiable por la constante utilización de esta para mover las transacciones.  
* No maneja conflictos de forma nativa: Si ocurre un conflicto de datos, la replicación se detiene y requiere información manual para solucionarlo.

# Elementos de la replicación transaccional, maestro-esclavo.

## Publicador:

El publicador es la instancia del servidor dueña de la base de datos original que contiene todos los objetos que serán replicados. 

## Distribuidor:

El distribuidor es la instancia de servidor que actúa como intermediario entre los nodos maestro y esclavos. Su tarea es recibir las transacciones del publicador y propagarlas por las bases de datos réplica. Generalmente la misma instancia publicadora es la encargada de ser la instancia distribuidora, aunque puede ocurrir lo contrario.

## Suscriptor:

Es la instancia del servidor que recibe y almacena las réplicas de la base de datos. El lugar donde se aplican las transacciones y modificaciones realizadas por el publicador. El tipo de suscriptor puede ser por inserción o extracción. La suscripción por inserción consiste en que el distribuidor replica activamente sobre el suscriptor y la suscripción por extracción consiste en que el suscriptor solicita cada cierto tiempo los cambios del distribuidor.

## Artículos:

Los artículos son las unidades mínimas que son replicadas, es decir los objetos de las bases de datos, pueden ser tablas y procedimientos almacenados.

## Publicación: 

Es el conjunto de artículos que se agrupan y son replicados como una unidad.

## Agentes de replicación:

Son los procedimientos encargados de llevar a cabo la replicación de la base de datos. Los agentes principales son.

* **Agente de instantáneas**: Es el proceso que toma el conjunto de datos inicial y la información de sincronización en la base de datos del distribuidor.  
* **Agente de Lector del Log:** Se ejecuta en la base de datos del distribuidor y se encarga de monitorear y registrar las transacciones que son para replicación.  
* **Agente de Distribución**: Envía las transacciones desde la base de datos del distribuidor a los suscriptores en el mismo orden que ocurrieron en el publicador.

