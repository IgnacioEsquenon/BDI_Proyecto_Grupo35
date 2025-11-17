--- PUEBA 4 - TRANSACCION ANIDADA ----------
/*Para probar el funcionamiento del las transacciones anidadas
 implementaremos 2 transacciones (operaciones), una critica 
 (si o si se debe hacer) y una opcional, para ver el funcionamiento 
 de los SAVEPOINTS */

-- 1. DATOS DE PRUEBA 
DECLARE @IdPacienteQueReprograma INT = 1; -- Paciente ID 1 (Messi)
DECLARE @IdReservaVieja INT = 1;          -- Reserva ID 1 (la de Messi)
DECLARE @IdTurnoViejo INT = 1;            -- Turno ID 1 (el de la Reserva 1)

DECLARE @IdTurnoNuevo INT = 2;            -- El Turno ID 2 (el siguiente turno libre)
DECLARE @IdMotivoConsulta INT = 1;        -- Motivo de cardiología 

-- 2. VERIFICAR ESTADO INICIAL 
PRINT '--- ESTADO INICIAL (ANTES) ---';
SELECT 'Reserva Nueva (Turno 2)' AS Tabla, COUNT(*) AS Filas FROM Reserva WHERE id_turno = @IdTurnoNuevo;
SELECT 'Reserva Vieja (Turno 1)' AS Tabla, id_estado FROM Reserva WHERE id_reserva = @IdReservaVieja;
SELECT 'Turno Nuevo (ID 2)' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @IdTurnoNuevo;
SELECT 'Turno Viejo (ID 1)' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @IdTurnoViejo;
GO -- 

DECLARE @IdPacienteQueReprograma INT = 1; -- Paciente ID 1 (Messi)
DECLARE @IdReservaVieja INT = 1;          -- Reserva ID 1 (la de Messi)
DECLARE @IdTurnoViejo INT = 1;            -- Turno ID 1 (el de la Reserva 1)

DECLARE @IdTurnoNuevo INT = 2;            -- El Turno ID 2 (el siguiente turno libre)
DECLARE @IdMotivoConsulta INT = 1;     
-- 3. EJECUTAR LA TRANSACCIÓN (CON SAVEPOINT)
PRINT '--- EJECUTANDO REPROGRAMACIÓN... ---';

BEGIN TRANSACTION; -- Transacción Principal
BEGIN TRY
    
    -- A. OPERACIÓN PRINCIPAL (Crítica): Crear la nueva reserva
    PRINT '1. Creando nueva reserva en Turno 2...';
    INSERT INTO Reserva (id_turno, id_paciente, id_motivo_consulta, id_estado)
    VALUES (@IdTurnoNuevo, @IdPacienteQueReprograma, @IdMotivoConsulta, 1);
    
    UPDATE Turno SET id_estado_turno = 2 WHERE id_turno = @IdTurnoNuevo;
    PRINT 'Nueva reserva asegurada (aún no commiteada).';

    -- B. Establecemos el SAVEPOINT
    SAVE TRANSACTION PuntoCancelacion;
    PRINT 'Savepoint "PuntoCancelacion" creado.';
    

    -- C. OPERACIÓN SECUNDARIA (No Crítica): Cancelar la vieja reserva
    BEGIN TRY
        PRINT '2. Intentando cancelar vieja reserva (ID 1)...';
        
        -- =======================================================
        -- Aqui se dispara el error
        PRINT '...Simulando un error en la cancelación...';
        THROW 51000, 'Error manual simulado en Tarea B', 1;
        -- =======================================================
        
        -- Este código nunca se ejecuta
        UPDATE Reserva SET id_estado = 2 WHERE id_reserva = @IdReservaVieja;
        UPDATE Turno SET id_estado_turno = 1 WHERE id_turno = @IdTurnoViejo;

    END TRY
    BEGIN CATCH -- CATCH INTERNO (para la Tarea B)
        PRINT '¡ERROR SECUNDARIO! ' + ERROR_MESSAGE();
        PRINT '...Revirtiendo SOLO la cancelación...';
        ROLLBACK TRANSACTION PuntoCancelacion;
        PRINT 'Rollback parcial completado. La NUEVA reserva sigue en pie.';
        PRINT '--- ADVERTENCIA: La reserva vieja (ID 1) no pudo ser cancelada. Revisar. ---';
    END CATCH

    -- D. COMMIT DE LA TRANSACCIÓN PRINCIPAL
    PRINT '3. Realizando COMMIT de la nueva reserva...';
    COMMIT TRANSACTION;
    PRINT 'COMMIT completado.';

END TRY
BEGIN CATCH -- CATCH EXTERNO (si falla la Tarea A)
    -- Si la Tarea A falla (ej. si el Paciente 1 no existiera), todo se revierte
    PRINT '¡ERROR CRÍTICO! ' + ERROR_MESSAGE();
    PRINT '...Revirtiendo TODA la transacción...';
    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION;
END CATCH
GO


-- 4. VERIFICAR ESTADO FINAL 
PRINT '--- ESTADO FINAL (POST-COMMIT) ---';
DECLARE @IdTurnoNuevo INT = 2;
DECLARE @IdReservaVieja INT = 1;
DECLARE @IdTurnoViejo INT = 1;
SELECT 'Reserva Nueva (Turno 2)' AS Tabla, COUNT(*) AS Filas FROM Reserva WHERE id_turno = @IdTurnoNuevo;
SELECT 'Reserva Vieja (Turno 1)' AS Tabla, id_estado FROM Reserva WHERE id_reserva = @IdReservaVieja;
SELECT 'Turno Nuevo (ID 2)' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @IdTurnoNuevo;
SELECT 'Turno Viejo (ID 1)' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @IdTurnoViejo;
GO