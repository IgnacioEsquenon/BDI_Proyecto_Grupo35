---- PRUEBA 3 - REGLA DE NEGOCIO ---- 
/* Para este caso, lo que se busca es mostrar una vez mas las 
situaciones donde se aplica el ROLLBACK. Aqui no se forzará 
un error sino que se buscará mostrar el cumplimiento de una de
las reglas de negocio, ¿Que ocurre si un turno ya esta ocupado? */


-- 1. DATOS DE PRUEBA
DECLARE @p_Nombre VARCHAR(50) = 'Paciente';
DECLARE @p_Apellido VARCHAR(50) = 'Regla';
DECLARE @p_Dni VARCHAR(15) = '55555555'; -- Un paciente NUEVO
DECLARE @p_Email VARCHAR(50) = 'regla@mail.com';
DECLARE @p_Telefono VARCHAR(20) = '555-5555';
DECLARE @p_FechaNacimiento DATE = '1990-01-01';
DECLARE @p_IdObraSocial INT = NULL;

DECLARE @r_IdTurno INT = 1; -- <-- El Turno ID 1, que reservamos con la prueba 1
DECLARE @r_IdMotivoConsulta INT = 1;


-- 2. ESTADO INICIAL 
-- Este paciente NO existe
SELECT 'Paciente' AS Tabla, COUNT(*) AS Filas FROM Paciente WHERE dni = @p_Dni;
-- PERO este turno SÍ existe y está RESERVADO (estado 2)
SELECT 'Turno' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @r_IdTurno;

-- TRANSACCION --
BEGIN TRANSACTION;
BEGIN TRY

    -- Validaciones
    IF EXISTS (SELECT 1 FROM Paciente WHERE dni = @p_Dni) BEGIN
        RAISERROR('El DNI del paciente ya existe.', 16, 1);
    END;
    IF NOT EXISTS (SELECT 1 FROM Turno WHERE id_turno = @r_IdTurno AND id_estado_turno = 1) BEGIN
        -- Esta es la regla que forzará el error
        RAISERROR('El turno no está disponible.', 16, 1); 
    END;

    -- 1era Tarea: Insertar en Paciente
    PRINT '1. Insertando en Paciente...'
    INSERT INTO Paciente (nombre, apellido, dni, email, telefono, fecha_nacimiento, id_obra_social)
    VALUES (@p_Nombre, @p_Apellido, @p_Dni, @p_Email, @p_Telefono, @p_FechaNacimiento, @p_IdObraSocial);
    
    DECLARE @NuevoIdPaciente INT = SCOPE_IDENTITY();

    -- 2da Tarea: Insertar en Reserva
    PRINT '2. Insertando en Reserva...';
    INSERT INTO Reserva (id_turno, id_paciente, id_motivo_consulta, id_estado)
    VALUES (@r_IdTurno, @NuevoIdPaciente, @r_IdMotivoConsulta, 1);

    -- 3ra Tarea: Actualizar en Turno
    PRINT '3. Actualizando Turno...';
    UPDATE Turno SET id_estado_turno = 2 WHERE id_turno = @r_IdTurno;

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


-- 4. VERIFICAR ESTADO FINAL (Captura 3: Resultados)
PRINT '--- ESTADO FINAL (POST-ROLLBACK) ---';
-- Este paciente NO debe haberse creado
SELECT 'Paciente' AS Tabla, COUNT(*) AS Filas FROM Paciente WHERE dni = @p_Dni;
-- El turno debe seguir igual (estado 2)
SELECT 'Turno' AS Tabla, id_estado_turno FROM Turno WHERE id_turno = @r_IdTurno;
GO