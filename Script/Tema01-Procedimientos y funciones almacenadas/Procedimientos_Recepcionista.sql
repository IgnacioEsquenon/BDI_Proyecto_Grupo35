
----- Procedimiento #03: Flujo de reservar turno ----------------------------------------------------
    ----  3.1: Búsqueda de médico para reservar un turno
              CREATE OR ALTER PROCEDURE rec_BuscarMedico
                    @IdEspecialidad INT = NULL,
                    @TextoBusquedaNombre VARCHAR(50) = NULL,
                    @MotivoConsulta VARCHAR(50) = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        U.id_usuario AS id_usuario,
                        U.nombre AS Nombre,
                        U.apellido AS Apellido,
                        E.nombre AS Especialidad
                    FROM Usuario U
                    JOIN Rol R ON U.id_rol = R.id_rol
                    JOIN Especialidad E ON U.id_especialidad = E.id_especialidad
                    LEFT JOIN Motivo_Consulta MC ON MC.id_especialidad = U.id_especialidad
                    WHERE
                        U.id_rol = 2 -- Médico
                        AND (@IdEspecialidad IS NULL OR E.id_especialidad = @IdEspecialidad)
                        AND (
                            @TextoBusquedaNombre IS NULL
                            OR UPPER(TRIM(U.nombre)) LIKE '%' + UPPER(TRIM(@TextoBusquedaNombre)) + '%'
                            OR UPPER(TRIM(U.apellido)) LIKE '%' + UPPER(TRIM(@TextoBusquedaNombre)) + '%'
                            OR UPPER(TRIM(@MotivoConsulta)) IS NULL OR UPPER(TRIM(MC.descripcion)) LIKE UPPER(TRIM('%' + @MotivoConsulta + '%'))
                        )
                    ORDER BY U.apellido, U.nombre;
                END;
                GO
                
                /* Ejemplo de primer paso:
                EXEC rec_BuscarMedico @TextoBusquedaNombre = 'Mettini';
                */
    ---- 3.2: Mostrar turnos disponibles para un médico seleccionado con diferentes filtrados opcionales
               CREATE OR ALTER PROCEDURE rec_ObtenerTurnosDisponibles
                    @IdMedico INT,
                    @FechaInicio DATE = NULL,
                    @FechaFin DATE = NULL,
                    @IdDia INT = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        T.id_turno AS id_turno,
                        T.fecha_turno AS [Fecha del Turno],
                        D.nombre AS Día,
                        T.hora_inicio AS [Hora de Inicio],
                        T.hora_fin as [Hora de Fin]
                    FROM Turno T
                    JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                    JOIN Día D ON BH.id_dia = D.id_dia
                    JOIN Estado_Turno ET ON T.id_estado_turno = ET.id_estado_turno
                    WHERE
                        BH.id_medico = @IdMedico
                        AND ET.id_estado_turno = 1 -- solo disponibles
                        AND T.fecha_turno >= CAST(GETDATE() AS DATE)
                        AND BH.fecha_fin >= CAST(GETDATE() AS DATE)
                        AND (@FechaInicio IS NULL OR T.fecha_turno >= @FechaInicio)
                        AND (@FechaFin IS NULL OR T.fecha_turno <= @FechaFin)
                        AND (@IdDia IS NULL OR BH.id_dia = @IdDia)
                    ORDER BY T.fecha_turno, T.hora_inicio;
                END;
                GO
                
                /* Ejemplo de segundo paso:
                DECLARE @IdMedico INT;

                -- Asignamos a una variable el valor del médico que buscamos
                SELECT @IdMedico = U.id_usuario 
                FROM Usuario U 
                WHERE UPPER(U.apellido) LIKE UPPER('mettini');

                -- Pasamos esa variable como parámetro para el segundo paso del flujo
                EXEC rec_ObtenerTurnosDisponibles
                    @IdMedico,
                    @FechaInicio = '2026-11-01',
                    @FechaFin = '2026-11-7', -- Ver turnos de la primer semana de noviembre
                    @IdDia = NULL;
                */

    ---- 3.3: Función que inserta la reserva, cambiando el estado de turno a ocupado
              CREATE OR ALTER PROCEDURE rec_RegistrarReserva
                    @IdTurno INT,
                    @IdPaciente INT,
                    @MotivoConsulta INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- Validar que el turno esté disponible
                    IF NOT EXISTS (SELECT 1 FROM Turno WHERE id_turno = @IdTurno AND id_estado_turno = 1)
                    BEGIN
                        RAISERROR('El turno no está disponible o ya fue reservado.', 16, 1);
                        RETURN;
                    END;

                    -- Insertar la reserva
                    INSERT INTO Reserva (id_turno, id_paciente, id_motivo_consulta, id_estado)
                    VALUES (@IdTurno, @IdPaciente, @MotivoConsulta, 1); -- 1 = Activa

                    -- Actualizar estado del turno
                    UPDATE Turno
                    SET id_estado_turno = 2 -- Reservado
                    WHERE id_turno = @IdTurno;
                END;
                GO

                /*Ejemplo de tercer paso del flujo de reserva:
                -- Seleccionamos el turno con id 33 de los resultados anteriores
                SELECT
                    MC.id_motivo_consulta,
                    MC.descripcion
                FROM Motivo_Consulta MC
                JOIN Usuario U ON MC.id_especialidad = U.id_especialidad
                WHERE UPPER(U.apellido) LIKE UPPER('Mettini'); -- Para ver qué posibles motivos de consulta se le pueden asignar al paciente

                EXEC rec_RegistrarReserva
                    @IdTurno = 7,
                    @IdPaciente = 3,
                    @MotivoConsulta = 2; 
                */
            
----------------------------------------------------------------------------------------------------
----- Procedimiento #04: Listar Reservas de Pacientes con Filtros ----------------------------------
              CREATE OR ALTER PROCEDURE rec_ListarReservasPacientes
                    @Filtro VARCHAR(50) = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT  
                        P.id_paciente AS id_paciente,
                        P.nombre AS Nombre,
                        P.apellido AS Apellido,
                        P.dni AS DNI,
                        T.fecha_turno AS [Fecha del Turno],
                        T.hora_inicio AS [Hora de Inicio],
                        T.hora_fin AS [Hora de Fin],
                        MC.descripcion AS [Motivo de Consulta]
                    FROM Reserva R
                    JOIN Turno T ON R.id_turno = T.id_turno
                    JOIN Paciente P ON R.id_paciente = P.id_paciente
                    JOIN Motivo_Consulta MC ON MC.id_motivo_consulta = R.id_motivo_consulta
                    WHERE 
                        T.fecha_turno >= CAST(GETDATE() AS DATE)
                        AND (
                            @Filtro IS NULL 
                            OR UPPER(P.nombre) + ' ' + UPPER(P.apellido) LIKE '%' + UPPER(@Filtro) + '%'                                                                     --                                                        JUAN LIKE %JUAN% (Esto evalúa true y va a estar en la lista)
                            OR P.dni LIKE '%' + @Filtro + '%'
                        )
                    ORDER BY T.fecha_turno ASC, T.hora_inicio ASC;
                END;
                GO
                
                /* Ejemplo 
                EXEC rec_ListarReservasPacientes;
                */
----------------------------------------------------------------------------------------------------
----- Procedimiento #05: Cancelar una reserva, cambiando su estado de reserva y liberando el turno -
                CREATE OR ALTER PROCEDURE rec_CancelarReserva
                    @IdReserva INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    DECLARE @IdTurno INT;

                    IF NOT EXISTS (SELECT 1 FROM Reserva WHERE id_reserva = @IdReserva AND id_estado = 1)
                    BEGIN
                        RAISERROR('La reserva no existe o ya fue cancelada/atendida.', 16, 1);
                        RETURN;
                    END;

                    -- Obtener el turno asociado a la reserva
                    SELECT @IdTurno = id_turno FROM Reserva WHERE id_reserva = @IdReserva;

                    -- Cambiar el estado de la reserva a "Cancelada" (2)
                    UPDATE Reserva
                    SET id_estado = 2
                    WHERE id_reserva = @IdReserva;

                    -- Cambiar el estado del turno a "Disponible" (1)
                    UPDATE Turno
                    SET id_estado_turno = 1
                    WHERE id_turno = @IdTurno;

                    PRINT 'La reserva fue cancelada correctamente y el turno se liberó.';
                END;
                GO

                /* Ejemplo
                EXEC rec_CancelarReserva
                    @IdReserva = 8;
                */
-------------------------------------------------------------------------------------------------------
--- f6: Función auxuliar para el siguiente procedimiento que calcula y devuelve la edad exacta en años de un paciente, en base a su fecha de nacimiento.
                CREATE OR ALTER FUNCTION fn_CalcularEdad
                (
                    @FechaNacimiento DATE
                )
                RETURNS INT
                AS
                BEGIN
                    DECLARE @Edad INT;
                
                    SET @Edad = DATEDIFF(YEAR, @FechaNacimiento, GETDATE());
                
                    IF (MONTH(@FechaNacimiento) > MONTH(GETDATE()))
                        OR (MONTH(@FechaNacimiento) = MONTH(GETDATE()) 
                            AND DAY(@FechaNacimiento) > DAY(GETDATE()))
                    BEGIN
                        SET @Edad = @Edad - 1;
                    END;
                
                    RETURN @Edad;
                END;
                GO
                    
-------------------------------------------------------------------------------------------------------
--- Procedimiento #06: Procedimiento que muestra estadísticas generales sobre los pacientes que realizaron
                    -- reservas dentro de un rango de fechas determinado. Incluye promedio de edad, distribución etaria
                    -- y porcentaje de pacientes con o sin obra social.
               CREATE OR ALTER PROCEDURE rec_EstadisticaPacientes
                    @FechaInicio DATE,
                    @FechaFin DATE
                AS
                BEGIN
                    SET NOCOUNT ON;
                
                    -- 1) Descripción general:
                    -- Este procedimiento analiza el perfil poblacional de los pacientes que realizaron reservas
                    -- dentro del rango de fechas establecido. Se calcula:
                    --  - Promedio de edad
                    --  - Distribución por rangos de edad (menores, adultos, mayores)
                    --  - Porcentaje de pacientes con y sin obra social.
                
                    -- 2) CTE: obtener pacientes únicos con reserva en el rango.
                    WITH PacientesReserva AS (
                        SELECT DISTINCT
                            P.id_paciente,
                            P.fecha_nacimiento,
                            P.id_obra_social,
                            dbo.fn_CalcularEdad(P.fecha_nacimiento) AS Edad
                        FROM Paciente P
                        INNER JOIN Reserva R ON P.id_paciente = R.id_paciente
                        INNER JOIN Turno T ON R.id_turno = T.id_turno
                        WHERE T.fecha_turno BETWEEN @FechaInicio AND @FechaFin
                    )
                
                    -- 3) Cálculo de agregados principales
                    SELECT
                        ISNULL(CAST(AVG(Edad * 1.0) AS DECIMAL(5,2)), 0.00) AS [Promedio de Edad],
                        
                        ISNULL(SUM(CASE WHEN Edad < 18 THEN 1 ELSE 0 END), 0) AS [Menores (<18)],
                        ISNULL(SUM(CASE WHEN Edad BETWEEN 18 AND 64 THEN 1 ELSE 0 END), 0) AS [Adultos (18-64)],
                        ISNULL(SUM(CASE WHEN Edad >= 65 THEN 1 ELSE 0 END), 0) AS [Mayores (65+)],
                        
                        ISNULL(CAST(SUM(CASE WHEN Edad < 18 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)), 0.00) AS [Porcentaje de Menores],
                        ISNULL(CAST(SUM(CASE WHEN Edad BETWEEN 18 AND 64 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)), 0.00) AS [Porcentaje de Adultos],
                        ISNULL(CAST(SUM(CASE WHEN Edad >= 65 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)), 0.00) AS [Porcentaje de Mayores],
                        
                        ISNULL(SUM(CASE WHEN id_obra_social IS NOT NULL THEN 1 ELSE 0 END), 0) AS [Pacientes con Obra Social],
                        ISNULL(SUM(CASE WHEN id_obra_social IS NULL THEN 1 ELSE 0 END), 0) AS [Pacientes sin Obra Social],
                        
                        ISNULL(CAST(SUM(CASE WHEN id_obra_social IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)), 0.00) AS [Porcentaje Con Obra Social],
                        ISNULL(CAST(SUM(CASE WHEN id_obra_social IS NULL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) AS DECIMAL(5,2)), 0.00) AS [Porcentaje Sin Obra Social]
                
                    FROM PacientesReserva;
                END;
                GO

                /* Ejemplo de uso:
                EXEC rec_EstadisticaPacientes
                    @FechaInicio = '2025-11-01',
                    @FechaFin = '2025-11-30';
                */
-------------------------------------------------------------------------------------------------------
--- Procedimiento #07: Procedimiento que muestra el ranking de las obras sociales más utilizadas
                    -- por los pacientes que realizaron reservas dentro de un rango de fechas, indicando su
                    -- participación porcentual respecto al total de pacientes con obra social.
                CREATE OR ALTER PROCEDURE rec_EstadisticaObrasSociales
                    @FechaInicio DATE,
                    @FechaFin DATE
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- 1) Descripción general:
                    -- Este procedimiento analiza la distribución de los pacientes con obra social
                    -- que realizaron reservas dentro del rango de fechas indicado.
                    -- Devuelve un ranking de obras sociales y su porcentaje sobre el total.

                    -- 2) CTE: obtener pacientes con obra social y reserva en el rango.
                    WITH PacientesObra AS (
                        SELECT DISTINCT
                            P.id_paciente,
                            OS.id_obra_social,
                            OS.nombre AS ObraSocial
                        FROM Paciente P
                        INNER JOIN Reserva R ON P.id_paciente = R.id_paciente
                        INNER JOIN Turno T ON R.id_turno = T.id_turno
                        INNER JOIN Obra_Social OS ON P.id_obra_social = OS.id_obra_social
                        WHERE T.fecha_turno BETWEEN @FechaInicio AND @FechaFin
                    )

                    -- 3) Ranking de obras sociales por cantidad de pacientes
                    SELECT
                        ObraSocial AS [Obra Social],
                        COUNT(*) AS [Cantidad de Pacientes],
                        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(6,2)) AS [Porcentaje sobre Total]
                    FROM PacientesObra
                    GROUP BY ObraSocial
                    ORDER BY [Cantidad de Pacientes] DESC;
                END;
                GO

                /* Ejemplo de uso:
                EXEC rec_EstadisticaObrasSociales
                    @FechaInicio = '2025-11-01',
                    @FechaFin = '2025-11-30';
                */

-------------------------------------------------------------------------------------------------------
