---- MANEJO DE TRANSACCIONES Y TRANSACCIONES ANIDADAS -------
-- Resumen: Es un mecanismo que agrupa un conjunto de operaciones 
-- dentro de un unico "paquete" de operaciones que se rige por 
-- el principio de "todo o nada" 

-- Si todas las operaciones se realizan satisfactoriamente, 
-- la transaccion se confirma (COMMIT) y se guardan los cambios 
-- Si UNA SOLA operacion falla por cualquier motivo, la transaccion 
-- se revierte (ROLLBACK) y la BD vuelve al estado exacto en el que estaba antes 

--- IMPLEMENTACION ---- 

CREATE OR ALTER PROCEDURE rec_RegistrarReserva
    @IdTurno INT,
    @IdPaciente INT,
    @IdMotivoConsulta INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Inicia el paquete de trabajo
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Validar que el turno sigue disponible (para evitar que dos personas lo reserven a la vez)
        IF NOT EXISTS (SELECT 1 FROM Turno WHERE id_turno = @IdTurno AND id_estado_turno = 1)
        BEGIN
            -- Si ya no está disponible, deshacemos todo y lanzamos un error
            ROLLBACK TRANSACTION;
            RAISERROR('El turno seleccionado ya no está disponible.', 16, 1);
            RETURN;
        END

        -- 2. Crear la cita del paciente en la tabla Reserva
        INSERT INTO Reserva (id_turno, id_paciente, id_motivo_consulta, id_estado)
        VALUES (@IdTurno, @IdPaciente, @IdMotivoConsulta, 1); -- 1 = Activa

        -- 3. Ocupar el espacio de tiempo en la tabla Turno
        UPDATE Turno
        SET id_estado_turno = 2 -- 2 = Reservado
        WHERE id_turno = @IdTurno;

        -- Si llegamos hasta aquí, todo salió bien. Confirmamos los cambios.
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si ocurre CUALQUIER error en el bloque TRY, el programa salta aquí.
        -- Deshacemos todos los cambios.
        ROLLBACK TRANSACTION;
        
        -- Opcional pero recomendado: Volver a lanzar el error para que la aplicación C# se entere
        THROW;
    END CATCH;
END;
GO  

