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

_Pruebas_

Para validar estos conceptos, se realizaron las siguientes pruebas en la base de datos MedoraBD_Proyecto. Las capturas de pantalla de los resultados (Pestañas "Resultados" y "Mensajes" de SSMS) se adjuntan a este informe.

Caso de Prueba 1: Transacción Simple (Atomicidad)
Objetivo: Probar la propiedad de Atomicidad (el principio de "todo o nada") de una transacción explícita.

Escenario: Se define una transacción para "Registrar un Paciente y su Primera Reserva", la cual consiste en tres operaciones que deben tener éxito como una sola unidad:

* INSERT en Paciente (el nuevo paciente).

* INSERT en Reserva (la nueva reserva).

* UPDATE en Turno (marcar el turno como 'Reservado').

Prueba 1.1: Prueba de Éxito (COMMIT)
Acción: Se ejecuta el script de transacción en un escenario ideal, con un DNI de paciente nuevo y un id_turno disponible.

Resultado (Capturas 1, 2, 3):

La pestaña "Mensajes" muestra que las 3 operaciones se ejecutan y finalizan con "COMMIT completado.".

La verificación "Después" demuestra que la nueva fila en Paciente existe, la nueva fila en Reserva existe, y la fila en Turno fue actualizada a id_estado_turno = 2.

Conclusión: La transacción funciona y cumple con la Durabilidad.

Prueba 1.2: Prueba de Fallo Forzado (ROLLBACK Total)
Acción: Se modifica el script para incluir un THROW (error forzado) manual después del primer INSERT (Paciente) pero antes del segundo (Reserva).

Resultado (Capturas 4, 5, 6):

La pestaña "Mensajes" muestra que el INSERT del paciente se ejecuta, pero el THROW detiene la operación y activa el bloque CATCH. Se muestra el mensaje "Realizando ROLLBACK...".

La verificación "Después" demuestra que la base de datos está en el mismo estado que "Antes": el Paciente no fue creado y el Turno sigue Disponible.

Conclusión: Se comprueba la Atomicidad. Aunque una parte de la transacción se ejecutó, el ROLLBACK revirtió todos los cambios, dejando la base de datos consistente.

Prueba 1.3: Prueba de Fallo por Regla de Negocio (ROLLBACK Total)
Acción: Se ejecuta el script de transacción (esta vez sin el THROW forzado) pero se intenta usar un id_turno que ya está ocupado (ej. id_estado_turno = 2).

_Resultado_

Una validación de datos (RAISERROR) dentro del TRY se dispara, notificando que "El turno no está disponible".

El CATCH captura este error y ejecuta un ROLLBACK total.

_Caso de Prueba 2: Atomicidad Parcial (SAVEPOINT)_

Objetivo: Probar una reversión parcial usando SAVE TRANSACTION para manejar operaciones con distintas prioridades.

Escenario: Se simula una "Reprogramación de Reserva", que consta de dos partes:

Tarea A (Crítica): Crear la nueva reserva en el turno futuro (ej. Turno 2).

Tarea B (Secundaria): Cancelar la vieja reserva (ej. Turno 1).

Justificación: La prioridad es asegurar la nueva cita del paciente (Tarea A). Si la cancelación de la cita vieja (Tarea B) falla, no debe deshacerse la nueva reserva.

Prueba 2.1: Fallo de Tarea Secundaria (ROLLBACK Parcial)
Acción: Se ejecuta un script que:

* Inicia la transacción principal (BEGIN TRAN).

* Completa la Tarea A (crea la nueva reserva en el Turno 2).

* Define un SAVE TRANSACTION PuntoCancelacion.

* Intenta la Tarea B, pero se inserta un THROW manual para forzar su fallo.

* Un CATCH interno captura el error y ejecuta ROLLBACK TRANSACTION PuntoCancelacion.

* La transacción principal continúa y ejecuta COMMIT TRANSACTION.

Resultado (Capturas 7, 8, 9):

La pestaña "Mensajes" muestra que el ¡ERROR SECUNDARIO! fue capturado, se ejecutó el Rollback parcial, y (crucialmente) la transacción principal finalizó con "COMMIT completado.".

La verificación "Después" es la prueba clave:

* Reserva Nueva (Turno 2): Muestra 1 fila. (¡La Tarea A SE GUARDÓ!)

* Reserva Vieja (Turno 1): Muestra id_estado = 1. (¡La Tarea B SE REVIRTIÓ!)

_Conclusión_

Basicamente se demuestra el uso exitoso de los SAVEPOINT. El sistema manejó un error en una operación secundaria de forma resiliente, revirtiendo solo esa parte y confirmando el trabajo crítico.

Las transacciones simples (BEGIN/COMMIT/ROLLBACK) son la herramienta fundamental para garantizar la Atomicidad en operaciones de "todo o nada", previniendo la corrupción de datos.

Los SAVEPOINTs (SAVE TRANSACTION) proveen un mecanismo de control de errores más granular. Permiten que el sistema sea resiliente, manejando fallos en tareas secundarias sin deshacer operaciones críticas que ya se han completado.

El manejo correcto de transacciones no es una característica opcional, sino un requisito indispensable para cualquier base de datos que deba mantener la integridad y consistencia de sus datos.
