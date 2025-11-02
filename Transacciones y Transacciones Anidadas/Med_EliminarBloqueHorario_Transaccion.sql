CREATE OR ALTER PROCEDURE med_EliminarBloqueHorario
    @IdBloque INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDACIÓN:
    --    Primero, se asegura de que el bloque que se intenta eliminar realmente exista
    --    y que no esté ya inactivo.
    IF NOT EXISTS (SELECT 1 FROM Bloque_Horario WHERE id_bloque = @IdBloque AND activo = 1)
    BEGIN
        -- Si no existe o ya está inactivo, envía un error claro a la aplicación.
        RAISERROR('El bloque no existe o ya se encuentra inactivo.', 16, 1);
        RETURN;
    END;

    -- 2. MANEJO DE TRANSACCIÓN:
    --    Se inicia un bloque TRY...CATCH y una transacción para asegurar que
    --    todas las operaciones se completen con éxito o, si algo falla, no se haga nada.
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3. ACTUALIZACIÓN DE TURNOS:
        --    Se buscan todos los turnos asociados al bloque que todavía estén 'Disponibles' (ID 1)
        --    y se los pasa al estado 'Inactivo' (ID 3).
        --    No toca los turnos que ya están 'Reservados' (ID 2).
        UPDATE Turno
        SET id_estado_turno = 3 -- Estado 'Inactivo'
        WHERE id_bloque = @IdBloque
          AND id_estado_turno = 1; -- Solo afecta a los 'Disponibles'

        -- 4. ACTUALIZACIÓN DEL BLOQUE:
        --    Se marca el bloque horario como inactivo (eliminación lógica).
        UPDATE Bloque_Horario
        SET activo = 0 -- 0 = inactivo
        WHERE id_bloque = @IdBloque;

        -- 5. CONFIRMACIÓN:
        --    Si ambas actualizaciones se completaron sin errores, se confirman los cambios.
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- 6. REVERSIÓN:
        --    Si ocurrió cualquier error dentro del bloque TRY, se deshacen todos los cambios.
        ROLLBACK TRANSACTION;
        
        -- Vuelve a lanzar el error para que la aplicación C# se entere de que algo salió mal.
        THROW;
    END CATCH;
END;
GO