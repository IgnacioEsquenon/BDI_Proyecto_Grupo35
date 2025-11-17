--- PRUEBA 2 - FORZAR UN FALLO EN LA TRANSACCION -----
/*En esta transaccion se buscara realizar lo mismo que en el 
primer caso, con la diferencia que aqui se forzará un fallo 
intencionalmente para mostrar la una de las propiedades de las
transacciones, el ROLLBACK */

--- CASO DE PRUEBA ---------
DECLARE @DniPruebaFallo VARCHAR(15) = '99999999';
DECLARE @TurnoPruebaFallo INT = 8; 

SELECT * FROM Paciente WHERE dni = @DniPruebaFallo;
SELECT * FROM Reserva WHERE id_turno = @TurnoPruebaFallo;
SELECT * FROM Turno WHERE id_turno = @TurnoPruebaFallo; 

-- TRANSACCION -- 

DECLARE @DniPruebaFallo VARCHAR(15) = '99999999';
DECLARE @EmailPruebaFallo VARCHAR(50) = 'fallo@mail.com';
DECLARE @TurnoPruebaFallo INT;
DECLARE @MotivoPruebaFallo INT;

-- Buscamos un turno DISPONIBLE de la Dra. Grierson (ID 5)
SELECT TOP 1 @TurnoPruebaFallo = T.id_turno
FROM Turno T
JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
WHERE BH.id_medico = 5 AND T.id_estado_turno = 1 AND T.fecha_turno >= GETDATE()
ORDER BY T.fecha_turno, T.hora_inicio;

-- Buscamos un motivo de Ginecología (ID Especialidad 4)
SELECT TOP 1 @MotivoPruebaFallo = id_motivo_consulta FROM Motivo_Consulta WHERE id_especialidad = 4;

IF @TurnoPruebaFallo IS NULL BEGIN
    RAISERROR('No hay turnos disponibles para la prueba.', 16, 1);
    RETURN;
END;

-- 2. VERIFICAMOS EL ESTADO INICIAL
SELECT 'Paciente' AS Tabla, COUNT(*) AS Filas FROM Paciente WHERE dni = @DniPruebaFallo;
SELECT 'Reserva' AS Tabla, COUNT(*) AS Filas FROM Reserva WHERE id_turno = @TurnoPruebaFallo;
SELECT 'Turno' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @TurnoPruebaFallo;


-- 3. EJECUTAMOS LA TRANSACCIÓN 
BEGIN TRANSACTION;
BEGIN TRY
    
    -- 1era Tarea: Insertar en Paciente 
    PRINT '1. Insertando en Paciente (DNI 99999999)...';
    INSERT INTO Paciente (nombre, apellido, dni, email, telefono, fecha_nacimiento, id_obra_social)
    VALUES ('Paciente', 'Fallo', @DniPruebaFallo, @EmailPruebaFallo, '555-9999', '1990-01-01', NULL);
    PRINT 'Paciente insertado.';

    -- ======================================================
    -- ACA SE PROVOCA EL ERROR
    THROW 51000, 'Error forzado!', 1;
    -- ======================================================

    -- 2da Tarea: Insertar en Reserva 
    PRINT '2. Insertando en Reserva...';
    INSERT INTO Reserva (id_turno, id_paciente, id_motivo_consulta, id_estado)
    VALUES (@TurnoPruebaFallo, 99, @MotivoPruebaFallo, 1); 

    -- 3era Tarea: Actualizar en Turno 
    PRINT '3. Actualizando Turno...';
    UPDATE Turno SET id_estado_turno = 2 WHERE id_turno = @TurnoPruebaFallo;

    PRINT 'Éxito. Realizando COMMIT...';
    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    PRINT '¡ERROR! ' + ERROR_MESSAGE();
    PRINT 'Realizando ROLLBACK...';
    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION;
    PRINT 'Transacción revertida.';

END CATCH
GO

--CASO DE PRUEBA (Post-commit)
DECLARE @DniPruebaFallo VARCHAR(15) = '99999999';
DECLARE @TurnoPruebaFallo INT = 8;

SELECT * FROM Paciente WHERE dni = @DniPruebaFallo;
SELECT * FROM Reserva WHERE id_turno = @TurnoPruebaFallo;
SELECT * FROM Turno WHERE id_turno = @TurnoPruebaFallo;