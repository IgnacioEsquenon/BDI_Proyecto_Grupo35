
----------------------------------------------------------------------
------------- PRUEBA DE TRANSACCIONES --------------------------------
----------------------------------------------------------------------

--PRUEBA 1 - FUNCIONAMIENTO NORMAL DE UNA TRANSACCION ----------------
/* Para esta prueba se buscara en primer lugar mostrar el flujo normal de accion 
de una transacción, donde se muestra el estado inicial de un registro, la 
transaccion propiamente dicha, y luego volver a ver el estado de ese registro*/

---CASO DE PRUEBA --- 
DECLARE @DniPruebaExito VARCHAR(15) = '77777777';
DECLARE @TurnoPruebaExito INT = 1; 

SELECT * FROM Paciente WHERE dni = @DniPruebaExito;
SELECT * FROM Reserva WHERE id_turno = @TurnoPruebaExito;
SELECT * FROM Turno WHERE id_turno = @TurnoPruebaExito;

PRINT '--- PRUEBA DE ÉXITO ---';
GO

-- 1. PREPARAMOS LOS DATOS DE PRUEBA
DECLARE @DniPruebaExito VARCHAR(15) = '77777777';
DECLARE @EmailPruebaExito VARCHAR(50) = 'exito@mail.com';
DECLARE @TurnoPruebaExito INT;
DECLARE @MotivoPruebaExito INT;

-- Buscamos un turno DISPONIBLE (En este caso del Dr. Favaloro (ID 4) )
SELECT TOP 1 @TurnoPruebaExito = T.id_turno
FROM Turno T
JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
WHERE BH.id_medico = 4 AND T.id_estado_turno = 1 AND T.fecha_turno >= GETDATE()
ORDER BY T.fecha_turno, T.hora_inicio;

-- Buscamos un motivo de Cardiología (ID Especialidad 1)
SELECT TOP 1 @MotivoPruebaExito = id_motivo_consulta FROM Motivo_Consulta WHERE id_especialidad = 1;

PRINT 'Se usará el Turno ID: ' + ISNULL(CAST(@TurnoPruebaExito AS VARCHAR), 'N/A');

-- 2. EJECUTAMOS LA TRANSACCIÓN
BEGIN TRANSACTION;
BEGIN TRY
    
    -- 1er Tarea: Insertar en Paciente
    PRINT '1. Insertando en Paciente (DNI 77777777)...';
    INSERT INTO Paciente (nombre, apellido, dni, email, telefono, fecha_nacimiento, id_obra_social)
    VALUES ('Paciente', 'Exito', @DniPruebaExito, @EmailPruebaExito, '555-7777', '1990-01-01', NULL);

    DECLARE @NuevoIdPaciente INT = SCOPE_IDENTITY();
    PRINT 'Nuevo Paciente ID: ' + CAST(@NuevoIdPaciente AS VARCHAR);

    -- 2da Tarea: Insertar en Reserva
    PRINT '2. Insertando en Reserva...';
    INSERT INTO Reserva (id_turno, id_paciente, id_motivo_consulta, id_estado)
    VALUES (@TurnoPruebaExito, @NuevoIdPaciente, @MotivoPruebaExito, 1);
    PRINT 'Reserva creada.';

    -- 3ra Tarea: Actualizar en Turno
    PRINT '3. Actualizando Turno...';
    UPDATE Turno
    SET id_estado_turno = 2 -- Reservado
    WHERE id_turno = @TurnoPruebaExito;
    PRINT 'Turno actualizado.';

    COMMIT TRANSACTION;
    PRINT 'Transacción completada.';

END TRY
BEGIN CATCH
    PRINT '¡ERROR! ' + ERROR_MESSAGE();
    PRINT 'Realizando ROLLBACK...';
    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION;
    PRINT 'Transacción revertida.';
END CATCH
GO

---CASO DE PRUEBA (Post-commit) --- 
DECLARE @DniPruebaExito VARCHAR(15) = '77777777';
DECLARE @TurnoPruebaExito INT = 1; -- Como es el primer turno que se genero, se guado con ID 1

SELECT * FROM Paciente WHERE dni = @DniPruebaExito;
SELECT * FROM Reserva WHERE id_turno = @TurnoPruebaExito;
SELECT * FROM Turno WHERE id_turno = @TurnoPruebaExito;