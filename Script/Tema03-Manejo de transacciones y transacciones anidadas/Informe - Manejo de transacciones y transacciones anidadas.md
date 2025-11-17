# Informe de Manejo de Transacciones y Transacciones Anidadas en SQL Server

_Introducción a las Transacciones en SQL Server_

En SQL Server, una transacción es un conjunto de operaciones que se ejecutan de manera conjunta y deben considerarse como una unidad de trabajo. En términos generales, las transacciones son esenciales para preservar la coherencia y fiabilidad de la base de datos, ya que aseguran que las operaciones realizadas dentro de la transacción se completen en su totalidad o, de lo contrario, se reviertan si ocurre algún error.

Esto significa que una transacción es un mecanismo que permite mantener la base de datos en un estado consistente, incluso frente a errores o fallas durante la ejecución de operaciones.

El Modelo ACID
Para gestionar las transacciones, SQL Server implementa el modelo ACID, que establece cuatro propiedades fundamentales:

* Atomicidad: Asegura que todas las operaciones dentro de la transacción se ejecuten en su totalidad o no se ejecuten en absoluto. Si ocurre un error, todos los cambios realizados por la transacción deben deshacerse, manteniendo la base de datos en un estado estable.

* Consistencia: Garantiza que la base de datos pase de un estado válido a otro estado igualmente válido después de la ejecución de una transacción. Cualquier transacción debe preservar las reglas y restricciones de la base de datos.

* Aislamiento: Establece que las transacciones deben ejecutarse sin interferir entre sí, asegurando que las operaciones dentro de una transacción no afecten o sean afectadas por otras transacciones en curso. Este aspecto es crucial en entornos de alta concurrencia.

* Durabilidad: Asegura que una vez que una transacción se confirma, sus cambios se mantienen permanentemente en la base de datos, incluso frente a fallas de sistema o apagados inesperados.

_Tipos de Transacciones en SQL Server_

* Transacciones Implícitas: Inician automáticamente una nueva transacción cada vez que se ejecuta una instrucción que modifica datos, sin necesidad de comandos explícitos para comenzar la transacción.

* Transacciones Explícitas: Requieren que el usuario comience y termine explícitamente la transacción mediante comandos específicos (BEGIN TRANSACTION, COMMIT TRANSACTION y ROLLBACK TRANSACTION).

_Transacciones Anidadas vs. Puntos de Guardado (SAVEPOINT)_

Si bien SQL Server permite "anidar" transacciones (un BEGIN TRAN dentro de otro BEGIN TRAN), su comportamiento difiere de lo que comúnmente se espera. El anidamiento en SQL Server se maneja con un contador (@@TRANCOUNT). Si se llama a BEGIN TRAN dentro de otra, solo incrementa el contador.

Lo crucial es que un ROLLBACK TRANSACTION en cualquier nivel anidado revierte la transacción completa (la externa).

Para lograr una reversión parcial, que es un objetivo común en lógicas de negocio complejas, la herramienta correcta es SAVE TRANSACTION (o SAVEPOINT).

Un SAVEPOINT marca un punto dentro de una transacción al que se puede revertir parcialmente (ROLLBACK TRANSACTION <nombre_savepoint>) sin cancelar la transacción principal. Esto permite que una operación secundaria (Tarea B) falle y sea revertida, mientras que la operación principal (Tarea A) puede continuar y ser confirmada (COMMIT).


_Conclusiones Generales_

Las pruebas realizadas en los scripts demuestran la implementación práctica y la importancia crítica del modelo ACID en SQL Server.

Las transacciones simples (BEGIN/COMMIT/ROLLBACK) son la herramienta fundamental para garantizar la Atomicidad en operaciones de "todo o nada", previniendo la corrupción de datos.

Los SAVEPOINTs (SAVE TRANSACTION) proveen un mecanismo de control de errores más granular. Permiten que el sistema sea resiliente, manejando fallos en tareas secundarias sin deshacer operaciones críticas que ya se han completado.

El manejo correcto de transacciones no es una característica opcional, sino un requisito indispensable para cualquier base de datos que deba mantener la integridad y consistencia de sus datos.
