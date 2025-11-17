----- Médico =======================================================================================
----- Procedimiento #01: Crear bloques horarios (con sus respectivos turnos) -----------------------
    --- 1.1: Crear un bloque horario 
                CREATE OR ALTER PROCEDURE med_CrearBloqueHorario
                    @FechaInicio DATE,
                    @FechaFin DATE,
                    @HoraInicio TIME,
                    @HoraFin TIME,
                    @DuracionTurnos INT,
                    @IdMedico INT,
                    @IdDia INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- Validar solapamiento con otros bloques del mismo médico y día
                    IF EXISTS (
                        SELECT 1
                        FROM Bloque_Horario bh
                        WHERE bh.id_medico = @IdMedico
                          AND bh.id_dia = @IdDia -- Si un mismo médico intenta crear el bloque en un mismo día,
                          AND ( -- (Entonces se debe ver si coinciden en rango de fechas. Ej: Se tiene guardado [1/10 - 31/10], y se intenta insertar [15/10 - 15/11] ó [15/09 - 15/10])
                                -- Rango de fechas superpuesto
                                @FechaInicio < bh.fecha_fin -- Y si la fecha de inicio que se intenta insertar es anterior a una fecha de fin de un bloque guardado,
                                AND @FechaFin > bh.fecha_inicio -- Y la fecha de fin que se intenta insertar es posterior a la fecha de inicio de un bloque guardado,
                              ) -- (Si un mismo médico carga un bloque que tenga coincidencia en día y se solapan en fechas, hay que comprobar si también se solapa en horario
                                -- (Ya que podría darse el caso de que quiera cargar en el mismo rango de fechas un bloque en la mañana y otro en la tarde)).
                          AND (
                                -- Rango de horas superpuesto
                                @HoraInicio < bh.hora_fin -- Y la hora de inicio que se intenta insertar es anterior a la hora de fin de un bloque,
                                AND @HoraFin > bh.hora_inicio -- Y la hora de fin que se intenta insertar es posterior a la hora de inicio de un bloque.
                              ) -- (Entonces se tiene que coinciden en horarios. Ej: Se tiene guardado [8:00 - 12:00] y se intenta insertar [9:00 a 11:00]).
                    )           -- Si se cumplen todas las condiciones, existe solapamiento y no debe permitirse insertar el bloque, mostrando el mensaje de error.
                    BEGIN
                        RAISERROR('El médico ya tiene un bloque en ese rango de fechas y horas para ese día.', 16, 1);
                        RETURN;
                    END;

                    -- Si no hay conflicto, insertar el bloque
                    INSERT INTO Bloque_Horario (
                        fecha_inicio,
                        fecha_fin,
                        hora_inicio,
                        hora_fin,
                        duracion_turnos,
                        activo,
                        id_medico,
                        id_dia
                    )
                    VALUES (
                        @FechaInicio,
                        @FechaFin,
                        @HoraInicio,
                        @HoraFin,
                        @DuracionTurnos,
                        1,              -- Activo por defecto
                        @IdMedico,
                        @IdDia
                    );

                    PRINT 'Bloque horario creado correctamente.';
                END;
                GO

                /* Ejemplos:
                EXEC med_CrearBloqueHorario
                    @FechaInicio = '2026-11-01',
                    @FechaFin = '2026-11-30',
                    @HoraInicio = '08:00',
                    @HoraFin = '12:00',
                    @DuracionTurnos = 30,
                    @IdMedico = 2,
                    @IdDia = 1; -- Lunes
                EXEC med_CrearBloqueHorario
                    @FechaInicio = '2026-11-01',
                    @FechaFin = '2026-11-30',
                    @HoraInicio = '08:00',
                    @HoraFin = '12:00',
                    @DuracionTurnos = 30,
                    @IdMedico = 3,
                    @IdDia = 3; -- Miércoles
                EXEC med_CrearBloqueHorario
                    @FechaInicio = '2026-11-01',
                    @FechaFin = '2026-11-30',
                    @HoraInicio = '08:00',
                    @HoraFin = '12:00',
                    @DuracionTurnos = 30,
                    @IdMedico = 4,
                    @IdDia = 5; -- Viernes
                */
    --- f1.2: Función axuliar para el siguiente procedimiento, obtiene y devuelve la próxima fecha que coincida con el día proporcionado como parámetro
                CREATE OR ALTER FUNCTION fn_ProximaFechaDelDia (
                    @FechaInicio DATE,
                    @IdDia INT
                )
                RETURNS DATE
                AS
                BEGIN
                    DECLARE @Fecha DATE = @FechaInicio;
                    DECLARE @ActualDia INT = DATEPART(WEEKDAY, @Fecha);
                    
                    IF @ActualDia = @IdDia
                        RETURN @Fecha;
                    
                    DECLARE @DiasDiferencia INT = @IdDia - @ActualDia;
                    
                    -- Se calcula la diferencia para que llegue el día solicitado.
                    IF @DiasDiferencia < 0
                        -- Si la diferencia es negativa, significa que en esta semana ya pasó ese día,
                        SET @DiasDiferencia = @DiasDiferencia + 7;
                        -- si sumamos 7 a la diferencia negativa, nos devuelve la diferencia positiva que falta para el día solicitado.
                    
                    RETURN DATEADD(DAY, @DiasDiferencia, @Fecha);
                    -- Asegurarnos que días de diferencia sea positiva, nos garantiza que al sumar esa diferencia de días a la fecha actual nos devuelva el próximo día que solicitamos en el futuro.
                END;
                GO
    --- 1.2: Procedimiento que calcula e inserta todos los turnos de un bloque dado.
                CREATE OR ALTER PROCEDURE med_GenerarTurnosPorBloque
                    @IdBloque INT
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SET DATEFIRST 1;
                    
                    DECLARE @FechaInicio DATE,
                            @FechaFin DATE,
                            @HoraInicio TIME,
                            @HoraFin TIME,
                            @DuracionTurnos INT,
                            @IdMedico INT,
                            @IdDia INT;
                    
                    SELECT @FechaInicio = BH.fecha_inicio,
                           @FechaFin = BH.fecha_fin,
                           @HoraInicio = BH.hora_inicio,
                           @HoraFin = BH.hora_fin,
                           @DuracionTurnos = BH.duracion_turnos,
                           @IdMedico = BH.id_medico,
                           @IdDia = BH.id_dia
                    FROM Bloque_Horario BH
                    WHERE BH.id_bloque = @IdBloque;
                    
                    -- A partir de la fecha de inicio del bloque, se calcula la primera fecha que coincida
                    -- exactamente con el día seleccionado en el bloque horario.
                    -- Esto permite comenzar directamente desde la fecha relevante.
                    DECLARE @FechaActual DATE = dbo.fn_ProximaFechaDelDia(@FechaInicio, @IdDia);
                    
                    WHILE @FechaActual <= @FechaFin
                    -- Este bucle itera únicamente por fechas que coinciden con el día seleccionado para el bloque,
                    BEGIN
                    -- avanzando de a una semana completa por cada iteración (7 días exactos).
                        DECLARE @HoraActual TIME = @HoraInicio;
                        -- Se declara una variable para establecer el horario de asignación de inicio de cada turno.
                        
                        WHILE DATEADD(MINUTE, @DuracionTurnos, @HoraActual) <= @HoraFin
                        -- Bucle que itera hasta que la suma entre la duración del turno
                        BEGIN
                        -- y la hora de inicio del turno tenga como resultado la hora de fin del bloque horario.
                            INSERT INTO Turno (fecha_turno, hora_inicio, hora_fin, id_bloque, id_estado_turno)
                            VALUES (
                                @FechaActual,
                                @HoraActual,
                                DATEADD(MINUTE, @DuracionTurnos, @HoraActual), -- La hora de fin es sumar la duración del turno a la hora actual.
                                @IdBloque,
                                1 -- Los turnos se asignan con id_estado_turno = 1 (disponible).
                            );
                            
                            SET @HoraActual = DATEADD(MINUTE, @DuracionTurnos, @HoraActual);
                            -- Se modifica la hora de inicio del siguiente turno, para que el fin de un turno
                        END
                        -- sea automáticamente el inicio del siguiente.
                        
                        -- En lugar de avanzar día por día, se avanza directamente 7 días,
                        -- ya que para volver a coincidir con el mismo día de la semana siempre transcurren exactamente 7 días.
                        SET @FechaActual = DATEADD(DAY, 7, @FechaActual);
                    END;
                END;
                GO
                
    --- 1.3: Trigger que automatiza el proceso anterior, para que se realice cada vez que se inserta un nuevo bloque válido.
                CREATE OR ALTER TRIGGER trg_AutoGenerarTurnos
                ON Bloque_Horario
                AFTER INSERT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    DECLARE @IdBloque INT;

                    SELECT @IdBloque = id_bloque FROM inserted;

                    EXEC med_GenerarTurnosPorBloque @IdBloque;
                END;

                GO
-------------------------------------------------------------------------------------------------------                
----- Procedimiento #02: Listar bloques horarios con diferentes opciones de filtrado ------------------
                CREATE OR ALTER PROCEDURE med_ListarBloquesMedico
                    @IdMedico INT, -- Obligatorio
                    @FechaDesde DATE = NULL,
                    @FechaHasta DATE = NULL,
                    @HoraDesde TIME = NULL,
                    @HoraHasta TIME = NULL,
                    @IdDia INT = NULL -- Opcionales
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        BH.fecha_inicio AS [Fecha de Inicio],
                        BH.fecha_fin AS [Fecha de Fin],
                        BH.hora_inicio AS [Hora de Inicio],
                        BH.hora_fin AS [Hora de Fin],
                        D.nombre AS [Día]
                    FROM Bloque_Horario BH
                    JOIN Día D ON D.id_dia = BH.id_dia
                    WHERE
                        BH.id_medico = @IdMedico
                        AND BH.activo = 1
                        AND (@FechaDesde IS NULL OR BH.fecha_inicio >= @FechaDesde)
                        AND (@FechaHasta IS NULL OR BH.fecha_fin <= @FechaHasta)
                        AND (@HoraDesde IS NULL OR BH.hora_inicio >= @HoraDesde)
                        AND (@HoraHasta IS NULL OR BH.hora_fin <= @HoraHasta)
                        AND (@IdDia IS NULL OR BH.id_dia = @IdDia)
                    ORDER BY
                        BH.fecha_inicio ASC,
                        BH.hora_inicio ASC;
                END;
                GO

                /* Ejemplo
                EXEC med_ListarBloquesMedico
                    @IdMedico = 3,
                    @FechaDesde = NULL,
                    @FechaHasta = NULL,
                    @HoraDesde = '8:00',
                    @HoraHasta = '12:00',
                    @IdDia = NULL;
                */
-------------------------------------------------------------------------------------------------------                
----- Procedimiento #03: Desactivar bloques horarios y sus turnos asociados (menos los reservados) ----
              CREATE OR ALTER PROCEDURE med_EliminarBloqueHorario
                    @IdBloque INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- Validar existencia del bloque
                    IF NOT EXISTS (SELECT 1 FROM Bloque_Horario WHERE id_bloque = @IdBloque AND activo = 1)
                    BEGIN
                        RAISERROR('El bloque no existe o ya está inactivo.', 16, 1);
                        RETURN;
                    END;

                    BEGIN TRY
                        BEGIN TRANSACTION;

                        -- 1. Inactivar turnos disponibles del bloque
                        UPDATE Turno
                        SET id_estado_turno = 3 -- Inactivo
                        WHERE id_bloque = @IdBloque
                          AND id_estado_turno = 1; -- Solo los disponibles

                        -- 2. Marcar el bloque como inactivo
                        UPDATE Bloque_Horario
                        SET activo = 0
                        WHERE id_bloque = @IdBloque;

                        -- 3. Confirmar transacción
                        COMMIT TRANSACTION;

                        PRINT 'Bloque inactivado correctamente. Turnos disponibles pasaron a estado Inactivo.';
                    END TRY
                    BEGIN CATCH
                        ROLLBACK TRANSACTION;
                        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
                        RAISERROR('Error al intentar inactivar el bloque: %s', 16, 1, @ErrorMsg);
                    END CATCH;
                END;
                GO

                /* Ejemplo:
                EXEC med_EliminarBloqueHorario
                    @IdBloque = 2;
                */
-------------------------------------------------------------------------------------------------------                
----- Procedimiento #05: Función que lista las reservas próximas del médico con diferentes filtros ----
                CREATE OR ALTER PROCEDURE med_ListarAgendaMedico
                    @IdMedico INT,                     
                    @FechaDesde DATE = NULL,           
                    @FechaHasta DATE = NULL,           
                    @IdPaciente INT = NULL,            
                    @IdDia INT = NULL,                 
                    @HoraDesde TIME = NULL,            
                    @HoraHasta TIME = NULL            
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        T.fecha_turno AS [Fecha del Turno],
                        T.hora_inicio AS [Hora de Inicio],
                        P.nombre + ' ' + P.apellido AS [Nombre del Paciente],
                        P.dni AS DNI,
                        P.email AS Email,
                        P.telefono AS Teléfono,
                        OS.nombre AS [Obra Social],
                        MC.descripcion AS [Motivo de Consulta]
                    FROM Reserva R
                    INNER JOIN Turno T ON R.id_turno = T.id_turno
                    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                    INNER JOIN Usuario U ON BH.id_medico = U.id_usuario
                    INNER JOIN Paciente P ON R.id_paciente = P.id_paciente
                    INNER JOIN Motivo_Consulta MC ON MC.id_motivo_consulta = R.id_motivo_consulta
                    LEFT JOIN Obra_Social OS ON P.id_obra_social = OS.id_obra_social -- opcional
                    LEFT JOIN Estado_Reserva ER ON R.id_estado = ER.id_estado
                    LEFT JOIN Día D ON BH.id_dia = D.id_dia
                    WHERE
                        BH.id_medico = @IdMedico
                        AND (T.fecha_turno >= CAST(GETDATE() AS DATE)) -- por defecto próximas
                        AND (@FechaDesde IS NULL OR T.fecha_turno >= @FechaDesde)
                        AND (@FechaHasta IS NULL OR T.fecha_turno <= @FechaHasta)
                        AND (@IdPaciente IS NULL OR P.id_paciente = @IdPaciente)
                        AND (@IdDia IS NULL OR BH.id_dia = @IdDia)
                        AND (@HoraDesde IS NULL OR T.hora_inicio >= @HoraDesde)
                        AND (@HoraHasta IS NULL OR T.hora_fin <= @HoraHasta)
                    ORDER BY
                        T.fecha_turno ASC,
                        T.hora_inicio ASC;
                END;
                GO

                /*Ejemplo
                EXEC med_ListarAgendaMedico
                    @IdMedico = 3,                     
                    @FechaDesde = NULL,           
                    @FechaHasta = NULL,           
                    @IdPaciente = NULL,            
                    @IdDia = NULL,                 
                    @HoraDesde = NULL,            
                    @HoraHasta = NULL;
                 */
-------------------------------------------------------------------------------------------------------                
----- Procedimiento #06: Función que permite acceder al historial del paciente ------------------------
                CREATE OR ALTER PROCEDURE med_ObtenerHistorialPaciente
                    @IdPaciente INT,
                    @FechaDesde DATE = NULL,
                    @FechaHasta DATE = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        T.fecha_turno AS [Fecha del Turno],

                        MC.descripcion AS [Motivo de Consulta],

                        U.nombre + ' ' + U.apellido AS [Nombre del Médico],
                        Esp.nombre AS Especialidad,
                        R.diagnostico AS Diagnóstico
                    FROM Reserva R
                    INNER JOIN Turno T ON R.id_turno = T.id_turno
                    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                    INNER JOIN Usuario U ON BH.id_medico = U.id_usuario
                    INNER JOIN Paciente P ON R.id_paciente = P.id_paciente
                    LEFT JOIN Especialidad Esp ON U.id_especialidad = Esp.id_especialidad
                    INNER JOIN Motivo_Consulta MC ON MC.id_motivo_consulta = R.id_motivo_consulta

                    WHERE
                        R.id_paciente = @IdPaciente
                        AND R.id_estado = 3 -- Que esté atendido
                        AND (@FechaDesde IS NULL OR T.fecha_turno >= @FechaDesde)
                        AND (@FechaHasta IS NULL OR T.fecha_turno <= @FechaHasta)

                    ORDER BY
                        T.fecha_turno DESC,
                        T.hora_inicio DESC;
                END;
                GO

                /* Ejemplo
                EXEC med_ObtenerHistorialPaciente
                    @IdPaciente = 1,
                    @FechaDesde = NULL,
                    @FechaHasta = NULL;
                */
-------------------------------------------------------------------------------------------------------
----- Procedimiento #07: Función que permite acceder al historial del médico --------------------------
                CREATE OR ALTER PROCEDURE med_ListarHistorialMedico
                    @IdMedico INT,
                    @FechaDesde DATE = NULL,
                    @FechaHasta DATE = NULL,
                    @IdPaciente INT = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        T.fecha_turno AS [Fecha del Turno],

                        P.nombre + ' ' + P.apellido AS [Nombre del Paciente],
                        P.dni AS DNI,

                        MC.descripcion AS [Motivo de Consulta],
                        R.diagnostico AS Diagnóstico
                    FROM Reserva R
                    INNER JOIN Turno T ON R.id_turno = T.id_turno
                    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                    INNER JOIN Paciente P ON R.id_paciente = P.id_paciente
                    INNER JOIN Motivo_Consulta MC ON MC.id_motivo_consulta = R.id_motivo_consulta
                    WHERE
                        BH.id_medico = @IdMedico
                        AND T.fecha_turno <= CAST(GETDATE() AS DATE)
                        AND R.id_estado = 3 -- Que esté atendido (manualmente por el médico)
                        AND (@FechaDesde IS NULL OR T.fecha_turno >= @FechaDesde)
                        AND (@FechaHasta IS NULL OR T.fecha_turno <= @FechaHasta)
                        AND (@IdPaciente IS NULL OR P.id_paciente = @IdPaciente)
                    ORDER BY
                        T.fecha_turno DESC,
                        T.hora_inicio ASC;
                END;
                GO

                /* Ejemplo
                EXEC med_ListarHistorialMedico
                    @IdMedico = 3,
                    @FechaDesde = NULL,
                    @FechaHasta = NULL,
                    @IdPaciente = NULL;
                */
-------------------------------------------------------------------------------------------------------
----- Procedimiento #08: Función que permite a un médico dar por atendida una reserva, con opción de agregar un diagnótico -
                CREATE OR ALTER PROCEDURE med_FinalizarReserva
                    @IdReserva INT,
                    @Diagnostico NVARCHAR(500)
                AS
                BEGIN
                    SET NOCOUNT ON;

                    IF NOT EXISTS (SELECT 1 FROM Reserva WHERE id_reserva = @IdReserva)
                    BEGIN
                        RAISERROR('La reserva indicada no existe.', 16, 1);
                        RETURN;
                    END;

                    UPDATE Reserva
                    SET 
                        diagnostico = @Diagnostico,
                        id_estado = (SELECT id_estado FROM Estado_Reserva WHERE nombre = 'Atendida')
                    WHERE id_reserva = @IdReserva;

                    PRINT 'Reserva actualizada y marcada como atendida correctamente.';
                END;
                GO

                /* Ejemplo
                EXEC med_FinalizarReserva
                    @IdReserva = 13,
                    @Diagnostico = 'Diag 1';
                */
-------------------------------------------------------------------------------------------------------
--- Procedimiento #09: Procedimiento que muestra el total y porcertanje de reservas programadas, atendidas, canceladas o ausentadas,
                   -- y a su vez el promedio semanal de pacientes atendidos en un rango de fechas dado.
                CREATE OR ALTER PROCEDURE med_EstadisticaActividadMedico
                    @IdMedico INT,
                    @FechaInicio DATE,
                    @FechaFin DATE
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- 1) Variable que calcula la cantidad de semanas dentro del rango de fechas pasado como parámetros.
                    DECLARE @TotalSemanas DECIMAL(5,2) = (DATEDIFF(DAY, @FechaInicio, @FechaFin) + 1) / 7.0; -- Esto es un aproximado, ya que los meses no tienen una cantidad entera de semanas.
                                                                                                             -- Sumo 1 porque por ejemplo, para noviembre me dio 29 de resultado, pero hay un día más que no se cuenta.
                    -- Los parámetros para DECIMAL(p, s), p es la cantidad de dígitos en total, s la cantidad de dígitos después de la coma.
                    -- Ejemplo: 999,99 se podría guardar en DECIMAL(5,2), pero 1132,11 no, ya que su cantidad de dígitos en total (p) es 6 teniendo en cuenta decimales.

                    -- 2) Variables de agregados básicos
                    DECLARE @TotalProgramados INT = 0; -- Turnos con reservas programadas.
                    DECLARE @TotalAtendidos INT = 0;   -- Turnos cuyas reservas hayan sido atendidas.
                    DECLARE @TotalCancelados INT = 0;  -- Turnos cuyas reservas hayan sido canceladas.
                    DECLARE @TotalAusencias INT = 0;   -- Turnos cuyas reservas no fueron atendidas debido a la ausencia del paciente.

                    -- 3) Con la cláusula with se crea una tabla temporal (CTE) para almacenar todos los turnos del médico que hayan tenido una reserva en el mes establecido.
                    WITH TurnosMedico AS (
                        SELECT
                            T.id_turno,
                            T.fecha_turno,
                            R.id_estado AS EstadoReserva
                        FROM Turno T
                        INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque -- Turnos de cada bloque horario específico.
                        INNER JOIN Reserva R ON T.id_turno = R.id_turno            -- Que a su vez existan en reserva.
                        WHERE 
                            BH.id_medico = @IdMedico                               -- Que sean todos los bloques asociados al médico específico.
                            AND T.fecha_turno BETWEEN @FechaInicio AND @FechaFin   -- Y que la fecha coincida con el rango establecido para el análisis.
                    )
                    -- 4) Calcular y asignar agregados usando la CTE luego de definirla con WITH.
                    SELECT -- ** ACLARACIÓN ** La tabla temporal 'TurnosMedico' actúa como un grupo en sí mismo, es por eso que se pueden aplicar funciones de agregación.
                        @TotalProgramados = COUNT(*), -- Total de turnos reservados con el filtrado de la tabla temporal.
                        @TotalAtendidos =  SUM(CASE WHEN EstadoReserva = 3 THEN 1 ELSE 0 END), -- Atendidos (Estado 3)
                        @TotalCancelados = SUM(CASE WHEN EstadoReserva = 2 THEN 1 ELSE 0 END), -- Cancelados (Estado 2)
                        @TotalAusencias =  SUM(CASE WHEN EstadoReserva = 1 AND T.fecha_turno < CAST(GETDATE() AS DATE)
                                                                           THEN 1 ELSE 0 END)  -- Se asume ausencia cuando el médico no finaliza una atención manualmente,
                                                                                               -- por tanto, expiraría la fecha pero mantendría su estado de activo (Estado 1).
                    FROM TurnosMedico T;

                    -- 5) Devolver resultados calculados
                    SELECT
                        @TotalProgramados AS [Reservas Programadas],
                        @TotalAtendidos  AS [Reservas Atendidas],
                        @TotalCancelados AS [Reservas Canceladas],
                        @TotalAusencias  AS Ausencias,
                        CASE 
                            WHEN @TotalProgramados = 0 THEN CAST(0 AS DECIMAL(6,2))
                            ELSE CAST(@TotalAtendidos * 100.0 / @TotalProgramados AS DECIMAL(6,2))
                        END AS [Porcentaje de Asistencia],
                        CASE
                            WHEN @TotalSemanas <= 0 THEN CAST(0 AS DECIMAL(6,2))
                            ELSE CAST(@TotalAtendidos / @TotalSemanas AS DECIMAL(6,2))
                        END AS [Promedio Semanal de Pacientes Atendidos];
                END;
                GO

                /* Ejemplo
                EXEC med_EstadisticaActividadMedico
                    @IdMedico = 3,
                    @FechaInicio = '2025-11-01',
                    @FechaFin = '2025-11-30';
                */
-------------------------------------------------------------------------------------------------------
--- Procedimiento #10: Procedimiento que muestra el ranking de motivos de consulta más frecuentes
                    -- atendidos por un médico en un rango de fechas determinado, incluyendo el porcentaje de participación
                    -- de cada motivo respecto al total de consultas realizadas.
                CREATE OR ALTER PROCEDURE med_EstadisticaMotivosMedico
                    @IdMedico INT,
                    @FechaInicio DATE,
                    @FechaFin DATE
                AS
                BEGIN
                    SET NOCOUNT ON;

                    -- 1) Descripción general:
                    -- Este procedimiento devuelve un listado ordenado de los motivos de consulta más registrados por el médico.
                    -- El cálculo se realiza considerando únicamente las reservas atendidas (id_estado = 3),
                    -- dentro del rango de fechas indicado por los parámetros.

                    -- 2) CTE: se extraen todas las atenciones realizadas por el médico en el rango indicado.
                    WITH ConsultasMedico AS (
                        SELECT
                            MC.id_motivo_consulta,
                            MC.descripcion AS MotivoConsulta,
                            R.id_reserva
                        FROM Reserva R
                        INNER JOIN Turno T ON R.id_turno = T.id_turno
                        INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
                        INNER JOIN Motivo_Consulta MC ON R.id_motivo_consulta = MC.id_motivo_consulta
                        WHERE
                            BH.id_medico = @IdMedico
                            AND R.id_estado = 3                              -- Solo reservas atendidas.
                            AND T.fecha_turno BETWEEN @FechaInicio AND @FechaFin
                    )

                    -- 3) Consulta principal: cálculo del ranking de motivos y su porcentaje relativo.
                    SELECT
                        C.MotivoConsulta AS [Motivo de Consulta],
                        COUNT(*) AS [Cantidad de Atenciones],                                                     -- 3. Se cuenta la cantidad de tuplas de cada grupo definido,
                        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(6,2)) AS [Porcentaje sobre Total] -- 4. Por último, esa cantidad se divide por el total de consultas atendidas, 
                                                                                                                  --    OVER() Sirve para evaluar los siguientes grupos, realizando lo mismo que el paso 3, pero sumando todos esos resultados.
                    FROM ConsultasMedico C                                                                        -- 1. En base a las reservas tomadas de arriba,
                    GROUP BY C.MotivoConsulta                                                                     -- 2. Se agrupan las reservas con mismos motivos de consulta,
                    ORDER BY [Cantidad de Atenciones] DESC;

                END;
                GO

                /* Ejemplo de uso:
                EXEC med_EstadisticaMotivosMedico
                    @IdMedico = 3,
                    @FechaInicio = '2025-11-01',
                    @FechaFin = '2025-11-30';
                */
--=====================================================================================================

