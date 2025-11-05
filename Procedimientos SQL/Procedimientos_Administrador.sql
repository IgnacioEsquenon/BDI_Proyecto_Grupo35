----- Administrador ===================================================================================
--- Procedimiento #01: Crear Usuario
                CREATE OR ALTER PROCEDURE admin_CrearUsuario
                    @nombre VARCHAR(50),
                    @apellido VARCHAR(50),
                    @dni VARCHAR(15),
                    @correo VARCHAR(50),
                    @telefono VARCHAR(20),
                    @contraseña VARCHAR(100),
                    @rol INT,
                    @especialidad INT = NULL, -- puede ser NULL si no es médico
                    @estado BIT = 1
                AS
                BEGIN
                    SET NOCOUNT ON;

                    IF EXISTS (SELECT 1 FROM Usuario WHERE dni = @dni OR email = @correo OR telefono = @telefono)
                    BEGIN
                        RAISERROR('El usuario ya existe con el mismo DNI, email o teléfono.', 16, 1);
                        RETURN;
                    END

                    INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_rol, id_especialidad, estado_usuario)
                    VALUES (@nombre, @apellido, @dni, @correo, @telefono, @contraseña, @rol, @especialidad, @estado);

                    PRINT 'Usuario creado correctamente.';
                END;
--- Procedimiento #02: Listar Usuarios con diferentes filtros
                CREATE OR ALTER PROCEDURE admin_ListarUsuarios
                    @idRol INT = NULL,
                    @idEspecialidad INT = NULL,
                    @busqueda VARCHAR(50) = NULL,
                    @estadoUsuario BIT = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT 
                        u.id_usuario,
                        u.nombre,
                        u.apellido,
                        u.dni,
                        u.email,
                        u.telefono,
                        r.nombre AS nombre_rol,
                        e.nombre AS nombre_especialidad,
                        u.estado_usuario
                    FROM Usuario AS u
                    LEFT JOIN Rol AS r ON u.id_rol = r.id_rol
                    LEFT JOIN Especialidad AS e ON u.id_especialidad = e.id_especialidad
                    WHERE 
                        (@idRol IS NULL OR u.id_rol = @idRol)
                        AND (@idEspecialidad IS NULL OR u.id_especialidad = @idEspecialidad)
                        AND (@estadoUsuario IS NULL OR u.estado_usuario = @estadoUsuario)
                        AND (
                            @busqueda IS NULL OR
                            UPPER(LTRIM(RTRIM(u.nombre))) LIKE '%' + UPPER(@busqueda) + '%' OR
                            UPPER(LTRIM(RTRIM(u.apellido))) LIKE '%' + UPPER(@busqueda) + '%' OR
                            u.dni LIKE '%' + @busqueda + '%'
                        )
                    ORDER BY u.apellido, u.nombre;
                END;
--- Procedimiento #03: Desactivar Usuario
                CREATE OR ALTER PROCEDURE admin_DesactivarUsuario
                    @idUsuario INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @idUsuario)
                    BEGIN
                        RAISERROR('El usuario no existe.', 16, 1);
                        RETURN;
                    END

                    UPDATE Usuario
                    SET estado_usuario = 0
                    WHERE id_usuario = @idUsuario;

                    PRINT 'Usuario desactivado correctamente.';
                END;
--- Procedimiento #04: Procedimiento que muestra indicadores generales de la clínica.
                    -- Incluye la cantidad total de reservas programadas, atendidas, canceladas y ausentes, así como
                    -- el porcentaje de cada tipo y el promedio de reservas atendidas por médico.
                CREATE OR ALTER PROCEDURE admin_EstadisticaClinicaGeneral
                    @FechaInicio DATE,
                    @FechaFin DATE
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- 1) Variables de agregados globales
                    DECLARE @TotalProgramados INT = 0;
                    DECLARE @TotalAtendidos INT = 0;
                    DECLARE @TotalCancelados INT = 0;
                    DECLARE @TotalAusencias INT = 0;
                    DECLARE @TotalMedicos INT = 0;

                    -- 2) CTE que reúne todas las reservas del período analizado
                    WITH ReservasClinica AS (
                        SELECT
                            R.id_reserva,
                            R.id_estado,
                            T.fecha_turno,
                            BH.id_medico
                        FROM Reserva R
                        INNER JOIN Turno T ON R.id_turno = T.id_turno
                        INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                        WHERE T.fecha_turno BETWEEN @FechaInicio AND @FechaFin
                    )
                    -- 3) Asignar agregados
                    SELECT
                        @TotalProgramados = COUNT(*),
                        @TotalAtendidos = SUM(CASE WHEN id_estado = 3 THEN 1 ELSE 0 END),
                        @TotalCancelados = SUM(CASE WHEN id_estado = 2 THEN 1 ELSE 0 END),
                        @TotalAusencias = SUM(CASE WHEN id_estado = 1 AND fecha_turno < CAST(GETDATE() AS DATE)
                                                   THEN 1 ELSE 0 END),
                        @TotalMedicos = COUNT(DISTINCT id_medico)
                    FROM ReservasClinica;

                    -- 4) Devolver resultados
                    SELECT
                        @TotalProgramados AS [Reservas Programadas],
                        @TotalAtendidos  AS [Reservas Atendidas],
                        @TotalCancelados AS [Reservas Canceladas],
                        @TotalAusencias  AS [Reservas con Ausencia],
                        CASE WHEN @TotalProgramados = 0 THEN 0
                             ELSE CAST(@TotalAtendidos * 100.0 / @TotalProgramados AS DECIMAL(6,2))
                        END AS [% Atendidas],
                        CASE WHEN @TotalProgramados = 0 THEN 0
                             ELSE CAST(@TotalCancelados * 100.0 / @TotalProgramados AS DECIMAL(6,2))
                        END AS [% Canceladas],
                        CASE WHEN @TotalProgramados = 0 THEN 0
                             ELSE CAST(@TotalAusencias * 100.0 / @TotalProgramados AS DECIMAL(6,2))
                        END AS [% Ausencias],
                        CASE WHEN @TotalMedicos = 0 THEN 0
                             ELSE CAST(@TotalAtendidos * 1.0 / @TotalMedicos AS DECIMAL(6,2))
                        END AS [Promedio de Reservas Atendidas por Médico];
                END;
                GO

                /* Ejemplo de uso:
                EXEC admin_EstadisticaClinicaGeneral
                    @FechaInicio = '2025-11-01',
                    @FechaFin = '2025-11-30';
                */
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--- Procedimiento #05: Procedimiento que muestra el ranking de especialidades más demandadas
                    -- según la cantidad de reservas realizadas en un rango de fechas. También muestra el motivo
                    -- de consulta más frecuente dentro de cada especialidad.
                CREATE OR ALTER PROCEDURE admin_EstadisticaEspecialidades
                    @FechaInicio DATE,
                    @FechaFin DATE
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- 1) Descripción general:
                    -- Este procedimiento analiza la demanda por especialidad dentro del rango de fechas dado,
                    -- mostrando el total de reservas por especialidad, su porcentaje respecto al total y el
                    -- motivo de consulta más frecuente asociado a cada especialidad.

                    -- 2) CTE principal: reservas con su especialidad y motivo
                    WITH ReservasEspecialidad AS (
                        SELECT
                            E.id_especialidad,
                            E.nombre AS Especialidad,
                            MC.descripcion AS MotivoConsulta,
                            R.id_reserva
                        FROM Reserva R
                        INNER JOIN Turno T ON R.id_turno = T.id_turno
                        INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                        INNER JOIN Usuario M ON BH.id_medico = M.id_usuario
                        INNER JOIN Especialidad E ON M.id_especialidad = E.id_especialidad
                        LEFT JOIN Motivo_Consulta MC ON R.id_motivo_consulta = MC.id_motivo_consulta
                        WHERE T.fecha_turno BETWEEN @FechaInicio AND @FechaFin
                    ),
                    -- 3) Ranking de motivos dentro de cada especialidad
                    MotivosFrecuentes AS (
                        SELECT
                            id_especialidad,
                            MotivoConsulta,
                            ROW_NUMBER() OVER (PARTITION BY id_especialidad ORDER BY COUNT(*) DESC) AS rn
                        FROM ReservasEspecialidad
                        WHERE MotivoConsulta IS NOT NULL
                        GROUP BY id_especialidad, MotivoConsulta
                    )
                    -- 4) Resultado final: resumen por especialidad
                    SELECT
                        RE.Especialidad,
                        COUNT(*) AS [Cantidad de Reservas],
                        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(6,2)) AS [% sobre Total],
                        MF.MotivoConsulta AS [Motivo Más Frecuente]
                    FROM ReservasEspecialidad RE
                    LEFT JOIN MotivosFrecuentes MF
                        ON RE.id_especialidad = MF.id_especialidad AND MF.rn = 1
                    GROUP BY RE.Especialidad, MF.MotivoConsulta
                    ORDER BY [Cantidad de Reservas] DESC;
                END;
                GO

                /* Ejemplo de uso:
                EXEC admin_EstadisticaEspecialidades
                    @FechaInicio = '2025-11-01',
                    @FechaFin = '2025-11-30';
                */
-------------------------------------------------------------------------------------------------------

--Crea un archivo nuevo 
/database/indices_optimizacion.sql

-- ==============================================
-- OPTIMIZACIÓN DE ÍNDICES – SISTEMA MEDORA
-- ==============================================

-- Tabla Usuario
CREATE INDEX IX_Usuario_dni ON Usuario(dni);
CREATE INDEX IX_Usuario_email ON Usuario(email);
CREATE INDEX IX_Usuario_telefono ON Usuario(telefono);
CREATE INDEX IX_Usuario_id_rol ON Usuario(id_rol);
CREATE INDEX IX_Usuario_id_especialidad ON Usuario(id_especialidad);
CREATE INDEX IX_Usuario_estado ON Usuario(estado_usuario);

-- Tabla Turno
CREATE INDEX IX_Turno_fecha ON Turno(fecha_turno);

-- Tabla Reserva
CREATE INDEX IX_Reserva_estado ON Reserva(id_estado);
CREATE INDEX IX_Reserva_turno ON Reserva(id_turno);
CREATE INDEX IX_Reserva_motivo ON Reserva(id_motivo_consulta);

-- Tabla Bloque_Horario
CREATE INDEX IX_BH_medico ON Bloque_Horario(id_medico);

