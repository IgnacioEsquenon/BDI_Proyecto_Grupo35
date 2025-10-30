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
    --- 1.2: Procedimiento que calcula e inserta todos los turnos de un bloque dado.
                CREATE OR ALTER PROCEDURE med_GenerarTurnosPorBloque
                    @IdBloque INT
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SET DATEFIRST 1;

                    DECLARE 
                        @FechaInicio DATE,
                        @FechaFin DATE,
                        @HoraInicio TIME,
                        @HoraFin TIME,
                        @DuracionTurnos INT,
                        @IdMedico INT,
                        @IdDia INT;

                    SELECT 
                        @FechaInicio = BH.fecha_inicio,
                        @FechaFin = BH.fecha_fin,
                        @HoraInicio = BH.hora_inicio,
                        @HoraFin = BH.hora_fin,
                        @DuracionTurnos = BH.duracion_turnos,
                        @IdMedico = BH.id_medico,
                        @IdDia = BH.id_dia
                    FROM Bloque_Horario BH
                    WHERE BH.id_bloque = @IdBloque;

                    DECLARE @FechaActual DATE = @FechaInicio;

                    WHILE @FechaActual <= @FechaFin -- Este bucle itera de día en día, comenzando por @FechaInicio 
                    BEGIN                           -- y continuando mientras la fecha actual sea anterior o igual a la fecha de fin del bloque @FechaFin.
                        IF DATEPART(WEEKDAY, @FechaActual) = @IdDia -- Al avanzar entre día en día dentro del rango, compara si esa fecha es el día que fue seleccionado en el bloque.
                        BEGIN
                            DECLARE @HoraActual TIME = @HoraInicio; -- Se declara una variable para establecer el horario de asignación de inicio de cada turno.

                            WHILE DATEADD(MINUTE, @DuracionTurnos, @HoraActual) <= @HoraFin -- Bucle que itera hasta que la suma entre la duración de turno
                            BEGIN                                                           --  y la hora de inicio del turno tenga como resultado la hora de fin.
                                INSERT INTO Turno (fecha_turno, hora_inicio, hora_fin, id_bloque, id_estado_turno)
                                VALUES (
                                    @FechaActual,
                                    @HoraActual,
                                    DATEADD(MINUTE, @DuracionTurnos, @HoraActual), -- La hora de fin es sumar la duración del turno a la hora actual de inicio de turno.
                                    @IdBloque,
                                    1 -- Los turnos se asignan con estado_turno = 1 (disponible)
                                );
                                SET @HoraActual = DATEADD(MINUTE, @DuracionTurnos, @HoraActual); -- Se modifica la hora actual de inicio de turno para que el fin de un turno sea el inicio de otro.
                            END
                        END
                        SET @FechaActual = DATEADD(DAY, 1, @FechaActual); -- Se modifica la fecha que recorre el bucle, que aumenta de 1 en 1
                    END                                                   -- (Se puede optimzar para que se modifique de a 7, ya que pasan 7 días para que vuelva a coincidir un mismo día
                END;                                                      --                      (importante saber que funcionaría solo luego de que la condición inicial sea verdadera)).
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