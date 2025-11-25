-- ================================================================================
-- SCRIPT DE CARGA OPTIMIZADO PARA MedoraDB
-- Volumen reducido (~33% del original) para mejor rendimiento
-- ================================================================================

USE MedoraDB;
GO

-- ================================================================================
-- FASE 1: INSERCIÓN DE PACIENTES (350 registros - reducido de 1000)
-- ================================================================================
PRINT 'Iniciando carga de pacientes...';

DECLARE @i INT = 1;
DECLARE @totalPacientes INT = 350; -- REDUCIDO

DECLARE @nombres TABLE (nombre VARCHAR(50));
INSERT INTO @nombres VALUES 
('Juan'),('María'),('Carlos'),('Ana'),('Luis'),('Laura'),('Pedro'),('Sofia'),('Miguel'),('Carmen'),
('José'),('Isabel'),('Francisco'),('Marta'),('Antonio'),('Rosa'),('Manuel'),('Patricia'),('David'),('Elena'),
('Javier'),('Lucía'),('Fernando'),('Paula'),('Roberto'),('Silvia'),('Alberto'),('Andrea'),('Diego'),('Natalia');

DECLARE @apellidos TABLE (apellido VARCHAR(50));
INSERT INTO @apellidos VALUES 
('García'),('Rodríguez'),('González'),('Fernández'),('López'),('Martínez'),('Sánchez'),('Pérez'),('Gómez'),('Martín'),
('Jiménez'),('Ruiz'),('Hernández'),('Díaz'),('Moreno'),('Muñoz'),('Álvarez'),('Romero'),('Alonso'),('Gutiérrez'),
('Navarro'),('Torres'),('Domínguez'),('Vázquez'),('Ramos'),('Gil'),('Ramírez'),('Serrano'),('Blanco'),('Molina');

WHILE @i <= @totalPacientes
BEGIN
    DECLARE @nombre VARCHAR(50);
    DECLARE @apellido VARCHAR(50);
    DECLARE @dni VARCHAR(15);
    DECLARE @email VARCHAR(50);
    DECLARE @telefono VARCHAR(20);
    DECLARE @fechaNac DATE;
    DECLARE @obraSocial INT;
    
    SELECT TOP 1 @nombre = nombre FROM @nombres ORDER BY NEWID();
    SELECT TOP 1 @apellido = apellido FROM @apellidos ORDER BY NEWID();
    
    SET @dni = CAST(20000000 + @i AS VARCHAR(15));
    SET @email = LOWER(@nombre) + '.' + LOWER(@apellido) + CAST(@i AS VARCHAR(10)) + '@mail.com';
    SET @telefono = '3' + RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000000 AS VARCHAR(10)), 9);
    SET @fechaNac = DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 29220, '2020-01-01');
    
    IF (ABS(CHECKSUM(NEWID())) % 100) < 70
        SET @obraSocial = (ABS(CHECKSUM(NEWID())) % 4) + 1;
    ELSE
        SET @obraSocial = NULL;
    
    BEGIN TRY
        INSERT INTO Paciente (nombre, apellido, dni, email, telefono, fecha_nacimiento, id_obra_social)
        VALUES (@nombre, @apellido, @dni, @email, @telefono, @fechaNac, @obraSocial);
    END TRY
    BEGIN CATCH
        CONTINUE;
    END CATCH
    
    SET @i = @i + 1;
    
    IF @i % 50 = 0
        PRINT 'Pacientes: ' + CAST(@i AS VARCHAR(10)) + '/' + CAST(@totalPacientes AS VARCHAR(10));
END

DECLARE @countPac INT;
SELECT @countPac = COUNT(*) FROM Paciente;
PRINT 'Pacientes completados: ' + CAST(@countPac AS VARCHAR(10));
GO

-- ================================================================================
-- FASE 2: INSERCIÓN DE MÉDICOS (14 médicos - 2 por especialidad)
-- ================================================================================
PRINT 'Iniciando carga de médicos...';

DECLARE @medicos TABLE (nombre VARCHAR(50), apellido VARCHAR(50), especialidad INT);
INSERT INTO @medicos VALUES
-- 2 por especialidad
('Alberto','Ramírez',1),('Beatriz','Morales',1),
('Fernanda','Luna',2),('Gabriel','Ríos',2),
('Liliana','Rojas',3),('Marcos','Castro',3),
('Patricia','Herrera',4),('Quintín','Moreno',4),
('Ulises','Bravo',5),('Valeria','Fuentes',5),
('Yolanda','Reyes',6),('Zacarías','Delgado',6),
('Elisa','Figueroa',7),('Fabián','Guerrero',7);

DECLARE @nombreMed VARCHAR(50), @apellidoMed VARCHAR(50), @especialidadMed INT;
DECLARE @dniMed VARCHAR(15), @emailMed VARCHAR(50), @telefonoMed VARCHAR(20);
DECLARE @contadorMed INT = 100;

DECLARE cur_medicos CURSOR FOR SELECT nombre, apellido, especialidad FROM @medicos;
OPEN cur_medicos;
FETCH NEXT FROM cur_medicos INTO @nombreMed, @apellidoMed, @especialidadMed;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @dniMed = CAST(30000000 + @contadorMed AS VARCHAR(15));
    SET @emailMed = LOWER(@nombreMed) + '.' + LOWER(@apellidoMed) + '@medora.com';
    SET @telefonoMed = '3' + RIGHT('00000000' + CAST(@contadorMed * 123456 AS VARCHAR(10)), 9);
    
    INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
    VALUES (@nombreMed, @apellidoMed, @dniMed, @emailMed, @telefonoMed, 'hash123', @especialidadMed, 2);
    
    SET @contadorMed = @contadorMed + 1;
    FETCH NEXT FROM cur_medicos INTO @nombreMed, @apellidoMed, @especialidadMed;
END

CLOSE cur_medicos;
DEALLOCATE cur_medicos;

DECLARE @countMed INT;
SELECT @countMed = COUNT(*) FROM Usuario WHERE id_rol = 2;
PRINT 'Médicos insertados: ' + CAST(@countMed AS VARCHAR(10));
GO

-- ================================================================================
-- FASE 3A: BLOQUES HORARIOS DE OCTUBRE (4 días por médico promedio)
-- ================================================================================
PRINT 'Creando bloques de OCTUBRE...';

DECLARE @idMedico INT;
DECLARE @diasTrabajo INT;
DECLARE @dia INT;

DECLARE cur_medicos_oct CURSOR FOR SELECT id_usuario FROM Usuario WHERE id_rol = 2;
OPEN cur_medicos_oct;
FETCH NEXT FROM cur_medicos_oct INTO @idMedico;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @diasTrabajo = 3 + (ABS(CHECKSUM(NEWID())) % 3); -- 3-5 días
    
    DECLARE @diasSeleccionados TABLE (id_dia INT);
    DELETE FROM @diasSeleccionados;
    
    WHILE (SELECT COUNT(*) FROM @diasSeleccionados) < @diasTrabajo
    BEGIN
        SET @dia = 1 + (ABS(CHECKSUM(NEWID())) % 6);
        IF NOT EXISTS (SELECT 1 FROM @diasSeleccionados WHERE id_dia = @dia)
            INSERT INTO @diasSeleccionados VALUES (@dia);
    END
    
    DECLARE cur_dias_oct CURSOR FOR SELECT id_dia FROM @diasSeleccionados;
    OPEN cur_dias_oct;
    FETCH NEXT FROM cur_dias_oct INTO @dia;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC med_CrearBloqueHorario @FechaInicio='2025-10-01', @FechaFin='2025-10-31',
                @HoraInicio='08:00', @HoraFin='12:00', @DuracionTurnos=30, @IdMedico=@idMedico, @IdDia=@dia;
            EXEC med_CrearBloqueHorario @FechaInicio='2025-10-01', @FechaFin='2025-10-31',
                @HoraInicio='16:00', @HoraFin='20:00', @DuracionTurnos=30, @IdMedico=@idMedico, @IdDia=@dia;
        END TRY
        BEGIN CATCH
            CONTINUE;
        END CATCH
        FETCH NEXT FROM cur_dias_oct INTO @dia;
    END
    
    CLOSE cur_dias_oct;
    DEALLOCATE cur_dias_oct;
    FETCH NEXT FROM cur_medicos_oct INTO @idMedico;
END

CLOSE cur_medicos_oct;
DEALLOCATE cur_medicos_oct;
PRINT 'Bloques de octubre completados.';
GO

-- ================================================================================
-- FASE 3B: BLOQUES HORARIOS DE NOVIEMBRE
-- ================================================================================
PRINT 'Creando bloques de NOVIEMBRE...';

DECLARE @idMedico INT;
DECLARE @diasTrabajo INT;
DECLARE @dia INT;

DECLARE cur_medicos_nov CURSOR FOR SELECT id_usuario FROM Usuario WHERE id_rol = 2;
OPEN cur_medicos_nov;
FETCH NEXT FROM cur_medicos_nov INTO @idMedico;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @diasTrabajo = 3 + (ABS(CHECKSUM(NEWID())) % 3);
    
    DECLARE @diasSeleccionados TABLE (id_dia INT);
    DELETE FROM @diasSeleccionados;
    
    WHILE (SELECT COUNT(*) FROM @diasSeleccionados) < @diasTrabajo
    BEGIN
        SET @dia = 1 + (ABS(CHECKSUM(NEWID())) % 6);
        IF NOT EXISTS (SELECT 1 FROM @diasSeleccionados WHERE id_dia = @dia)
            INSERT INTO @diasSeleccionados VALUES (@dia);
    END
    
    DECLARE cur_dias_nov CURSOR FOR SELECT id_dia FROM @diasSeleccionados;
    OPEN cur_dias_nov;
    FETCH NEXT FROM cur_dias_nov INTO @dia;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC med_CrearBloqueHorario @FechaInicio='2025-11-11', @FechaFin='2025-11-30',
                @HoraInicio='08:00', @HoraFin='12:00', @DuracionTurnos=30, @IdMedico=@idMedico, @IdDia=@dia;
            EXEC med_CrearBloqueHorario @FechaInicio='2025-11-11', @FechaFin='2025-11-30',
                @HoraInicio='16:00', @HoraFin='20:00', @DuracionTurnos=30, @IdMedico=@idMedico, @IdDia=@dia;
        END TRY
        BEGIN CATCH
            CONTINUE;
        END CATCH
        FETCH NEXT FROM cur_dias_nov INTO @dia;
    END
    
    CLOSE cur_dias_nov;
    DEALLOCATE cur_dias_nov;
    FETCH NEXT FROM cur_medicos_nov INTO @idMedico;
END

CLOSE cur_medicos_nov;
DEALLOCATE cur_medicos_nov;

DECLARE @countBloq INT, @countTurn INT;
SELECT @countBloq = COUNT(*) FROM Bloque_Horario;
SELECT @countTurn = COUNT(*) FROM Turno;
PRINT 'Bloques totales: ' + CAST(@countBloq AS VARCHAR(10)) + ' | Turnos: ' + CAST(@countTurn AS VARCHAR(10));
GO

-- ================================================================================
-- FASE 4A: RESERVAR TURNOS DE OCTUBRE (50% de turnos - REDUCIDO)
-- ================================================================================
PRINT 'Reservando turnos de OCTUBRE...';

DECLARE @idMedicoRes INT;
DECLARE @contador INT;
DECLARE @metaReservas INT;

DECLARE cur_reservas_oct CURSOR FOR SELECT id_usuario FROM Usuario WHERE id_rol = 2;
OPEN cur_reservas_oct;
FETCH NEXT FROM cur_reservas_oct INTO @idMedicoRes;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @turnosDisp INT;
    SELECT @turnosDisp = COUNT(*)
    FROM Turno T
    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
    WHERE BH.id_medico = @idMedicoRes 
      AND T.id_estado_turno = 1
      AND T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31';
    
    SET @metaReservas = CAST(@turnosDisp * 0.5 AS INT); -- REDUCIDO a 50%
    SET @contador = 0;
    
    WHILE @contador < @metaReservas
    BEGIN
        DECLARE @idTurno INT, @idPaciente INT, @idMotivo INT, @especialidadMedico INT;
        
        SELECT @especialidadMedico = id_especialidad FROM Usuario WHERE id_usuario = @idMedicoRes;
        
        SELECT TOP 1 @idTurno = T.id_turno
        FROM Turno T
        INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
        WHERE BH.id_medico = @idMedicoRes 
          AND T.id_estado_turno = 1
          AND T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31'
        ORDER BY NEWID();
        
        IF @idTurno IS NULL BREAK;
        
        SELECT TOP 1 @idPaciente = id_paciente FROM Paciente ORDER BY NEWID();
        SELECT TOP 1 @idMotivo = id_motivo_consulta
        FROM Motivo_Consulta WHERE id_especialidad = @especialidadMedico ORDER BY NEWID();
        
        BEGIN TRY
            EXEC rec_RegistrarReserva @IdTurno=@idTurno, @IdPaciente=@idPaciente, @IdMotivoConsulta=@idMotivo;
            SET @contador = @contador + 1;
        END TRY
        BEGIN CATCH
            CONTINUE;
        END CATCH
    END
    
    FETCH NEXT FROM cur_reservas_oct INTO @idMedicoRes;
END

CLOSE cur_reservas_oct;
DEALLOCATE cur_reservas_oct;

DECLARE @countResOct INT;
SELECT @countResOct = COUNT(*) FROM Reserva R
INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31';
PRINT 'Reservas octubre: ' + CAST(@countResOct AS VARCHAR(10));
GO

-- ================================================================================
-- FASE 4B: RESERVAR TURNOS DE NOVIEMBRE (40% - REDUCIDO)
-- ================================================================================
PRINT 'Reservando turnos de NOVIEMBRE...';

DECLARE @idMedicoRes INT;
DECLARE @contador INT;
DECLARE @metaReservas INT;

DECLARE cur_reservas_nov CURSOR FOR SELECT id_usuario FROM Usuario WHERE id_rol = 2;
OPEN cur_reservas_nov;
FETCH NEXT FROM cur_reservas_nov INTO @idMedicoRes;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @turnosDisp INT;
    SELECT @turnosDisp = COUNT(*)
    FROM Turno T
    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
    WHERE BH.id_medico = @idMedicoRes 
      AND T.id_estado_turno = 1
      AND T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30';
    
    SET @metaReservas = CAST(@turnosDisp * 0.4 AS INT); -- REDUCIDO a 40%
    SET @contador = 0;
    
    WHILE @contador < @metaReservas
    BEGIN
        DECLARE @idTurno INT, @idPaciente INT, @idMotivo INT, @especialidadMedico INT;
        
        SELECT @especialidadMedico = id_especialidad FROM Usuario WHERE id_usuario = @idMedicoRes;
        
        SELECT TOP 1 @idTurno = T.id_turno
        FROM Turno T
        INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
        WHERE BH.id_medico = @idMedicoRes 
          AND T.id_estado_turno = 1
          AND T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30'
        ORDER BY NEWID();
        
        IF @idTurno IS NULL BREAK;
        
        SELECT TOP 1 @idPaciente = id_paciente FROM Paciente ORDER BY NEWID();
        SELECT TOP 1 @idMotivo = id_motivo_consulta
        FROM Motivo_Consulta WHERE id_especialidad = @especialidadMedico ORDER BY NEWID();
        
        BEGIN TRY
            EXEC rec_RegistrarReserva @IdTurno=@idTurno, @IdPaciente=@idPaciente, @IdMotivoConsulta=@idMotivo;
            SET @contador = @contador + 1;
        END TRY
        BEGIN CATCH
            CONTINUE;
        END CATCH
    END
    
    FETCH NEXT FROM cur_reservas_nov INTO @idMedicoRes;
END

CLOSE cur_reservas_nov;
DEALLOCATE cur_reservas_nov;

DECLARE @countResNov INT;
SELECT @countResNov = COUNT(*) FROM Reserva R
INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30';
PRINT 'Reservas noviembre: ' + CAST(@countResNov AS VARCHAR(10));
GO

-- ================================================================================
-- FASE 5: PROCESAR RESERVAS DE OCTUBRE
-- ================================================================================
PRINT 'Procesando reservas de OCTUBRE...';

-- Cancelar ~11%
DECLARE @reservasCancelarOct TABLE (id_reserva INT);
INSERT INTO @reservasCancelarOct
SELECT TOP 11 PERCENT id_reserva
FROM Reserva R INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31' AND R.id_estado = 1
ORDER BY NEWID();

DECLARE @idRes INT;
DECLARE cur_can_oct CURSOR FOR SELECT id_reserva FROM @reservasCancelarOct;
OPEN cur_can_oct;
FETCH NEXT FROM cur_can_oct INTO @idRes;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC rec_CancelarReserva @IdReserva = @idRes;
    FETCH NEXT FROM cur_can_oct INTO @idRes;
END
CLOSE cur_can_oct;
DEALLOCATE cur_can_oct;

-- Ausencias ~7%
DECLARE @reservasAusencias TABLE (id_reserva INT);
INSERT INTO @reservasAusencias
SELECT TOP 7 PERCENT id_reserva
FROM Reserva R INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31'
  AND R.id_estado = 1
ORDER BY NEWID();

-- Atender el resto
DECLARE @reservasAtenderOct TABLE (id_reserva INT, especialidad INT);
INSERT INTO @reservasAtenderOct
SELECT R.id_reserva, U.id_especialidad
FROM Reserva R
INNER JOIN Turno T ON R.id_turno = T.id_turno
INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
INNER JOIN Usuario U ON BH.id_medico = U.id_usuario
WHERE T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31'
  AND R.id_estado = 1
  AND R.id_reserva NOT IN (SELECT id_reserva FROM @reservasAusencias);

DECLARE @idEsp INT;
DECLARE @diagnostico VARCHAR(500);

DECLARE cur_atender_oct CURSOR FOR SELECT id_reserva, especialidad FROM @reservasAtenderOct;
OPEN cur_atender_oct;
FETCH NEXT FROM cur_atender_oct INTO @idRes, @idEsp;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @diagnostico = CASE @idEsp
        WHEN 1 THEN 'Control cardiológico: Presión arterial estable. ECG sin alteraciones.'
        WHEN 2 THEN 'Evaluación pediátrica: Crecimiento adecuado. Vacunación al día.'
        WHEN 3 THEN 'Consulta dermatológica: Lesión benigna tratada. Control en 3 meses.'
        WHEN 4 THEN 'Control ginecológico: Examen sin hallazgos patológicos.'
        WHEN 5 THEN 'Evaluación urológica: Estudios normales. Seguimiento en 6 meses.'
        WHEN 6 THEN 'Consulta traumatológica: Evolución favorable. Continuar fisioterapia.'
        WHEN 7 THEN 'Consulta clínica: Valores de laboratorio normales. Continuar tratamiento.'
        ELSE 'Consulta general realizada correctamente.'
    END;
    
    EXEC med_FinalizarReserva @IdReserva = @idRes, @Diagnostico = @diagnostico;
    FETCH NEXT FROM cur_atender_oct INTO @idRes, @idEsp;
END

CLOSE cur_atender_oct;
DEALLOCATE cur_atender_oct;

DECLARE @countAtOct INT;
SELECT @countAtOct = COUNT(*) FROM Reserva R
INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31' AND R.id_estado = 3;
PRINT 'Atendidas octubre: ' + CAST(@countAtOct AS VARCHAR(10));
GO

-- ================================================================================
-- FASE 6: PROCESAR RESERVAS DE NOVIEMBRE
-- ================================================================================
PRINT 'Procesando reservas de NOVIEMBRE...';

DECLARE @reservasCancelarNov TABLE (id_reserva INT);
INSERT INTO @reservasCancelarNov
SELECT TOP 9 PERCENT id_reserva
FROM Reserva R INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30' AND R.id_estado = 1
ORDER BY NEWID();

DECLARE @idRes INT;
DECLARE cur_can_nov CURSOR FOR SELECT id_reserva FROM @reservasCancelarNov;
OPEN cur_can_nov;
FETCH NEXT FROM cur_can_nov INTO @idRes;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC rec_CancelarReserva @IdReserva = @idRes;
    FETCH NEXT FROM cur_can_nov INTO @idRes;
END
CLOSE cur_can_nov;
DEALLOCATE cur_can_nov;

PRINT 'Procesamiento completado.';
GO

-- ================================================================================
-- RESUMEN FINAL
-- ================================================================================
DECLARE @resPac INT, @resMed INT, @resBloq INT, @resTurn INT;
DECLARE @resTurnDisp INT, @resTurnRes INT, @resTotalRes INT;
DECLARE @resAct INT, @resCan INT, @resAten INT, @resAus INT;
DECLARE @resOct INT, @resNov INT;

SELECT @resPac = COUNT(*) FROM Paciente;
SELECT @resMed = COUNT(*) FROM Usuario WHERE id_rol = 2;
SELECT @resBloq = COUNT(*) FROM Bloque_Horario;
SELECT @resTurn = COUNT(*) FROM Turno;
SELECT @resTurnDisp = COUNT(*) FROM Turno WHERE id_estado_turno = 1;
SELECT @resTurnRes = COUNT(*) FROM Turno WHERE id_estado_turno = 2;
SELECT @resTotalRes = COUNT(*) FROM Reserva;
SELECT @resAct = COUNT(*) FROM Reserva WHERE id_estado = 1;
SELECT @resCan = COUNT(*) FROM Reserva WHERE id_estado = 2;
SELECT @resAten = COUNT(*) FROM Reserva WHERE id_estado = 3;

SELECT @resAus = COUNT(*)
FROM Reserva R INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE R.id_estado = 1 AND T.fecha_turno < '2025-11-08';

SELECT @resOct = COUNT(*) FROM Reserva R 
INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31';

SELECT @resNov = COUNT(*) FROM Reserva R 
INNER JOIN Turno T ON R.id_turno = T.id_turno
WHERE T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30';

PRINT '';
PRINT '================================================================================';
PRINT 'CARGA OPTIMIZADA COMPLETADA';
PRINT '================================================================================';
PRINT 'Pacientes: ' + CAST(@resPac AS VARCHAR(10));
PRINT 'Médicos: ' + CAST(@resMed AS VARCHAR(10));
PRINT 'Bloques: ' + CAST(@resBloq AS VARCHAR(10));
PRINT 'Turnos totales: ' + CAST(@resTurn AS VARCHAR(10));
PRINT 'Turnos disponibles: ' + CAST(@resTurnDisp AS VARCHAR(10));
PRINT 'Turnos reservados: ' + CAST(@resTurnRes AS VARCHAR(10));
PRINT '';
PRINT 'RESERVAS:';
PRINT '  Total: ' + CAST(@resTotalRes AS VARCHAR(10));
PRINT '  Atendidas: ' + CAST(@resAten AS VARCHAR(10));
PRINT '  Canceladas: ' + CAST(@resCan AS VARCHAR(10));
PRINT '  Ausencias: ' + CAST(@resAus AS VARCHAR(10));
PRINT '  Activas futuras: ' + CAST(@resAct - @resAus AS VARCHAR(10));
PRINT '';
PRINT 'OCTUBRE: ' + CAST(@resOct AS VARCHAR(10)) + ' reservas';
PRINT 'NOVIEMBRE: ' + CAST(@resNov AS VARCHAR(10)) + ' reservas';
PRINT '================================================================================';
GO





-- ================================================================================
-- CARGA ESPECIAL: DR. JUAN PÉREZ
-- ================================================================================
PRINT '';
PRINT '================================================================================';
PRINT 'CARGA ESPECIAL: DR. JUAN PÉREZ';
PRINT '================================================================================';

DECLARE @idDrPerez INT;
SELECT @idDrPerez = id_usuario FROM Usuario WHERE dni = '302139412' AND id_rol = 2;

IF @idDrPerez IS NULL
BEGIN
    INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
    VALUES ('Juan', 'Pérez', '302139412', 'med@mail.com', '388213021', 
            '673d190b758967621da243f06c350ce68be4276174dc886560239fea923d4a5a', 7, 2);
    SELECT @idDrPerez = id_usuario FROM Usuario WHERE dni = '302139412';
    PRINT 'Dr. Pérez insertado con ID: ' + CAST(@idDrPerez AS VARCHAR(10));
END
ELSE
    PRINT 'Dr. Pérez encontrado con ID: ' + CAST(@idDrPerez AS VARCHAR(10));

-- Crear bloques (Lunes, Miércoles, Viernes)
PRINT 'Creando bloques horarios Dr. Pérez...';
DECLARE @diasDrPerez TABLE (id_dia INT);
INSERT INTO @diasDrPerez VALUES (1),(3),(5);

DECLARE @diaDrP INT;
DECLARE cur_dias_drp CURSOR LOCAL FAST_FORWARD FOR SELECT id_dia FROM @diasDrPerez;
OPEN cur_dias_drp;
FETCH NEXT FROM cur_dias_drp INTO @diaDrP;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC med_CrearBloqueHorario @FechaInicio='2025-10-01', @FechaFin='2025-10-31',
            @HoraInicio='08:00', @HoraFin='12:00', @DuracionTurnos=30, @IdMedico=@idDrPerez, @IdDia=@diaDrP;
        EXEC med_CrearBloqueHorario @FechaInicio='2025-10-01', @FechaFin='2025-10-31',
            @HoraInicio='16:00', @HoraFin='20:00', @DuracionTurnos=30, @IdMedico=@idDrPerez, @IdDia=@diaDrP;
        EXEC med_CrearBloqueHorario @FechaInicio='2025-11-11', @FechaFin='2025-11-30',
            @HoraInicio='08:00', @HoraFin='12:00', @DuracionTurnos=30, @IdMedico=@idDrPerez, @IdDia=@diaDrP;
        EXEC med_CrearBloqueHorario @FechaInicio='2025-11-11', @FechaFin='2025-11-30',
            @HoraInicio='16:00', @HoraFin='20:00', @DuracionTurnos=30, @IdMedico=@idDrPerez, @IdDia=@diaDrP;
    END TRY
    BEGIN CATCH END CATCH
    FETCH NEXT FROM cur_dias_drp INTO @diaDrP;
END
CLOSE cur_dias_drp;
DEALLOCATE cur_dias_drp;

-- Reservar turnos octubre (50%)
PRINT 'Reservando turnos Dr. Pérez...';
DECLARE @turnosOctDP INT, @metaOctDP INT, @contOctDP INT = 0;
SELECT @turnosOctDP = COUNT(*) FROM Turno T
INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
WHERE BH.id_medico = @idDrPerez AND T.id_estado_turno = 1
  AND T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31';

SET @metaOctDP = CAST(@turnosOctDP * 0.5 AS INT);

WHILE @contOctDP < @metaOctDP
BEGIN
    DECLARE @idTurnoOctDP INT, @idPacOctDP INT, @idMotOctDP INT;
    
    SELECT TOP 1 @idTurnoOctDP = T.id_turno FROM Turno T
    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
    WHERE BH.id_medico = @idDrPerez AND T.id_estado_turno = 1
      AND T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31'
    ORDER BY NEWID();
    
    IF @idTurnoOctDP IS NULL BREAK;
    
    SELECT TOP 1 @idPacOctDP = id_paciente FROM Paciente ORDER BY NEWID();
    SELECT TOP 1 @idMotOctDP = id_motivo_consulta FROM Motivo_Consulta WHERE id_especialidad = 7 ORDER BY NEWID();
    
    BEGIN TRY
        EXEC rec_RegistrarReserva @IdTurno=@idTurnoOctDP, @IdPaciente=@idPacOctDP, @IdMotivoConsulta=@idMotOctDP;
        SET @contOctDP = @contOctDP + 1;
    END TRY
    BEGIN CATCH END CATCH
END

-- Reservar turnos noviembre (40%)
DECLARE @turnosNovDP INT, @metaNovDP INT, @contNovDP INT = 0;
SELECT @turnosNovDP = COUNT(*) FROM Turno T
INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
WHERE BH.id_medico = @idDrPerez AND T.id_estado_turno = 1
  AND T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30';

SET @metaNovDP = CAST(@turnosNovDP * 0.4 AS INT);

WHILE @contNovDP < @metaNovDP
BEGIN
    DECLARE @idTurnoNovDP INT, @idPacNovDP INT, @idMotNovDP INT;
    
    SELECT TOP 1 @idTurnoNovDP = T.id_turno FROM Turno T
    INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
    WHERE BH.id_medico = @idDrPerez AND T.id_estado_turno = 1
      AND T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30'
    ORDER BY NEWID();
    
    IF @idTurnoNovDP IS NULL BREAK;
    
    SELECT TOP 1 @idPacNovDP = id_paciente FROM Paciente ORDER BY NEWID();
    SELECT TOP 1 @idMotNovDP = id_motivo_consulta FROM Motivo_Consulta WHERE id_especialidad = 7 ORDER BY NEWID();
    
    BEGIN TRY
        EXEC rec_RegistrarReserva @IdTurno=@idTurnoNovDP, @IdPaciente=@idPacNovDP, @IdMotivoConsulta=@idMotNovDP;
        SET @contNovDP = @contNovDP + 1;
    END TRY
    BEGIN CATCH END CATCH
END

PRINT 'Reservas Dr. Pérez - Oct: ' + CAST(@contOctDP AS VARCHAR(10)) + ' | Nov: ' + CAST(@contNovDP AS VARCHAR(10));

-- Diagnósticos variados
PRINT 'Procesando diagnósticos Dr. Pérez...';
DECLARE @diagnosticosClinica TABLE (id_motivo INT, diagnostico VARCHAR(500));
INSERT INTO @diagnosticosClinica VALUES
(26,'Paciente con epigastralgia. Diagnóstico: Gastritis aguda. Se indica omeprazol 20mg/día, dieta blanda y control en 15 días.'),
(26,'Dolor en fosa ilíaca derecha descartando apendicitis. Diagnóstico: Constipación crónica. Hidratación y fibra dietética.'),
(26,'Dolor abdominal difuso. Diagnóstico: Síndrome intestino irritable. Manejo con dieta FODMAP y probióticos.'),
(26,'Dolor en hipocondrio derecho. Ecografía: colelitiasis asintomática. Manejo conservador, dieta hipograsa.'),
(26,'Dolor periumbilical. Laboratorio normal. Diagnóstico: Dispepsia funcional. Omeprazol 20mg antes del desayuno.'),
(27,'Cefalea tensional crónica. Examen neurológico normal. Tratamiento: Paracetamol 500mg PRN, técnicas de relajación.'),
(27,'Migraña sin aura. Episodios 2-3 veces/mes. Profilaxis con propranolol 40mg/día. Sumatriptán 50mg para crisis.'),
(27,'Cefalea en racimos. Crisis intensas hemicraneales. Derivación neurología. Oxígeno 100% y sumatriptán subcutáneo.'),
(27,'Cefalea secundaria a HTA mal controlada. TA: 160/95 mmHg. Ajuste antihipertensivos. Control semanal.'),
(27,'Cefalea cervicogénica. Contractura paravertebral. AINES, relajantes musculares y fisioterapia.'),
(28,'Diarrea aguda. Coprocultivo negativo. Diagnóstico: Gastroenteritis viral. Hidratación oral y dieta astringente.'),
(28,'Náuseas y vómitos recurrentes. Endoscopía: esofagitis grado A. IBP doble dosis, proquinéticos.'),
(28,'Distensión abdominal y meteorismo. Diagnóstico: Intolerancia a lactosa. Dieta sin lácteos.'),
(28,'Pirosis y regurgitación. Diagnóstico: ERGE. Pantoprazol 40mg/día, elevación cabecera cama.'),
(28,'Diarrea crónica. Estudios negativos. Diagnóstico: Síndrome postinfeccioso. Loperamida PRN.'),
(29,'Episodios de hipoglucemia en diabético. Ajuste de insulina. Educación sobre reconocimiento de síntomas.'),
(29,'Hipoglucemia reactiva postprandial. Curva de glucosa patológica. Dieta fraccionada, bajo índice glucémico.'),
(29,'Diabético tipo 2 con hipoglucemias nocturnas. Reducción glibenclamida. Cambio a sitagliptina.'),
(29,'Síndrome de hipoglucemia en ayunas. Solicitud péptido C, insulina, cortisol. Derivación endocrinología.'),
(29,'Hipoglucemia por desnutrición. Plan nutricional hipercalórico fraccionado. Suplementos vitamínicos.'),
(30,'HTA grado 1. TA: 145/92 mmHg. Inicio enalapril 10mg/día. MAPA ambulatorio. Modificación estilo de vida.'),
(30,'HTA grado 2 no controlada. TA: 168/105 mmHg. Ajuste enalapril 20mg + hidroclorotiazida 25mg.'),
(30,'Crisis hipertensiva. TA: 180/110 mmHg asintomático. Captopril sublingual. Mejoría a 150/90.'),
(30,'HTA reciente diagnóstico. TA: 152/94. Función renal normal, lípidos elevados. Atorvastatina 20mg.'),
(30,'HTA resistente. TA: 156/98 con triple terapia. Espironolactona 25mg agregado. Descartar HTA secundaria.');

-- Procesar reservas Dr. Pérez octubre
DECLARE @reservasDrPerezOct TABLE (id_reserva INT, id_motivo INT);
INSERT INTO @reservasDrPerezOct
SELECT R.id_reserva, R.id_motivo_consulta
FROM Reserva R
INNER JOIN Turno T ON R.id_turno = T.id_turno
INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
WHERE BH.id_medico = @idDrPerez
  AND T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31'
  AND R.id_estado = 1;

-- Cancelar 10%
DECLARE @resCancelDP TABLE (id_reserva INT);
INSERT INTO @resCancelDP
SELECT TOP 10 PERCENT id_reserva FROM @reservasDrPerezOct ORDER BY NEWID();

DECLARE @idResCan INT;
DECLARE cur_cancel_dp CURSOR LOCAL FAST_FORWARD FOR SELECT id_reserva FROM @resCancelDP;
OPEN cur_cancel_dp;
FETCH NEXT FROM cur_cancel_dp INTO @idResCan;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC rec_CancelarReserva @IdReserva = @idResCan;
    END TRY
    BEGIN CATCH END CATCH
    FETCH NEXT FROM cur_cancel_dp INTO @idResCan;
END
CLOSE cur_cancel_dp;
DEALLOCATE cur_cancel_dp;

-- Ausencias 7%
DECLARE @resAusenciasDP TABLE (id_reserva INT);
INSERT INTO @resAusenciasDP
SELECT TOP 7 PERCENT id_reserva FROM @reservasDrPerezOct 
WHERE id_reserva NOT IN (SELECT id_reserva FROM @resCancelDP)
ORDER BY NEWID();

-- Atender resto con diagnósticos variados
DECLARE @idResAten INT, @idMotAten INT, @diagAten VARCHAR(500);

DECLARE cur_atender_dp CURSOR LOCAL FAST_FORWARD FOR
SELECT id_reserva, id_motivo FROM @reservasDrPerezOct
WHERE id_reserva NOT IN (SELECT id_reserva FROM @resCancelDP)
  AND id_reserva NOT IN (SELECT id_reserva FROM @resAusenciasDP);

OPEN cur_atender_dp;
FETCH NEXT FROM cur_atender_dp INTO @idResAten, @idMotAten;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT TOP 1 @diagAten = diagnostico
    FROM @diagnosticosClinica WHERE id_motivo = @idMotAten ORDER BY NEWID();
    
    IF @diagAten IS NULL
        SET @diagAten = 'Consulta de clínica médica. Evaluación general. Estudios complementarios solicitados.';
    
    BEGIN TRY
        EXEC med_FinalizarReserva @IdReserva = @idResAten, @Diagnostico = @diagAten;
    END TRY
    BEGIN CATCH END CATCH
    
    FETCH NEXT FROM cur_atender_dp INTO @idResAten, @idMotAten;
END

CLOSE cur_atender_dp;
DEALLOCATE cur_atender_dp;

-- Cancelar noviembre 8%
DECLARE @resCancelNovDP TABLE (id_reserva INT);
INSERT INTO @resCancelNovDP
SELECT TOP 8 PERCENT R.id_reserva
FROM Reserva R
INNER JOIN Turno T ON R.id_turno = T.id_turno
INNER JOIN Bloque_Horario BH ON T.id_bloque = BH.id_bloque
WHERE BH.id_medico = @idDrPerez
  AND T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30'
  AND R.id_estado = 1
ORDER BY NEWID();

DECLARE cur_cancel_nov_dp CURSOR LOCAL FAST_FORWARD FOR SELECT id_reserva FROM @resCancelNovDP;
OPEN cur_cancel_nov_dp;
FETCH NEXT FROM cur_cancel_nov_dp INTO @idResCan;
WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC rec_CancelarReserva @IdReserva = @idResCan;
    END TRY
    BEGIN CATCH END CATCH
    FETCH NEXT FROM cur_cancel_nov_dp INTO @idResCan;
END
CLOSE cur_cancel_nov_dp;
DEALLOCATE cur_cancel_nov_dp;

PRINT '  ✓ Dr. Pérez: Datos cargados con diagnósticos variados';
GO

-- ================================================================================
-- RESUMEN FINAL OPTIMIZADO
-- ================================================================================
PRINT '';
PRINT 'Calculando resumen final...';

-- Una única consulta con CTEs para máxima eficiencia
WITH 
ConteosBasicos AS (
    SELECT 
        (SELECT COUNT(*) FROM Paciente) AS TotalPacientes,
        (SELECT COUNT(*) FROM Usuario WHERE id_rol = 2) AS TotalMedicos,
        (SELECT COUNT(*) FROM Bloque_Horario) AS TotalBloques,
        (SELECT COUNT(*) FROM Turno) AS TotalTurnos,
        (SELECT COUNT(*) FROM Turno WHERE id_estado_turno = 1) AS TurnosDisponibles,
        (SELECT COUNT(*) FROM Turno WHERE id_estado_turno = 2) AS TurnosReservados,
        (SELECT COUNT(*) FROM Reserva) AS TotalReservas,
        (SELECT COUNT(*) FROM Reserva WHERE id_estado = 1) AS ReservasActivas,
        (SELECT COUNT(*) FROM Reserva WHERE id_estado = 2) AS ReservasCanceladas,
        (SELECT COUNT(*) FROM Reserva WHERE id_estado = 3) AS ReservasAtendidas
),
ConteosAusencias AS (
    SELECT COUNT(*) AS TotalAusencias
    FROM Reserva R
    INNER JOIN Turno T ON R.id_turno = T.id_turno
    WHERE R.id_estado = 1 AND T.fecha_turno < '2025-11-08'
),
ConteoPorMes AS (
    SELECT 
        SUM(CASE WHEN T.fecha_turno BETWEEN '2025-10-01' AND '2025-10-31' THEN 1 ELSE 0 END) AS ReservasOctubre,
        SUM(CASE WHEN T.fecha_turno BETWEEN '2025-11-11' AND '2025-11-30' THEN 1 ELSE 0 END) AS ReservasNoviembre
    FROM Reserva R
    INNER JOIN Turno T ON R.id_turno = T.id_turno
)
SELECT 
    cb.TotalPacientes, cb.TotalMedicos, cb.TotalBloques, cb.TotalTurnos,
    cb.TurnosDisponibles, cb.TurnosReservados, cb.TotalReservas,
    cb.ReservasActivas, cb.ReservasCanceladas, cb.ReservasAtendidas,
    ca.TotalAusencias, cpm.ReservasOctubre, cpm.ReservasNoviembre
INTO #ResumenFinal
FROM ConteosBasicos cb, ConteosAusencias ca, ConteoPorMes cpm;

-- Imprimir resultados
DECLARE @resPac INT, @resMed INT, @resBloq INT, @resTurn INT;
DECLARE @resTurnDisp INT, @resTurnRes INT, @resTotalRes INT;
DECLARE @resAct INT, @resCan INT, @resAten INT, @resAus INT;
DECLARE @resOct INT, @resNov INT;

SELECT 
    @resPac = TotalPacientes, @resMed = TotalMedicos, @resBloq = TotalBloques,
    @resTurn = TotalTurnos, @resTurnDisp = TurnosDisponibles, @resTurnRes = TurnosReservados,
    @resTotalRes = TotalReservas, @resAct = ReservasActivas, @resCan = ReservasCanceladas,
    @resAten = ReservasAtendidas, @resAus = TotalAusencias,
    @resOct = ReservasOctubre, @resNov = ReservasNoviembre
FROM #ResumenFinal;

DROP TABLE #ResumenFinal;

PRINT '';
PRINT '================================================================================';
PRINT '                    CARGA COMPLETADA EXITOSAMENTE';
PRINT '================================================================================';
PRINT '';
PRINT 'DATOS GENERALES:';
PRINT '  Pacientes: ' + CAST(@resPac AS VARCHAR(10));
PRINT '  Médicos: ' + CAST(@resMed AS VARCHAR(10));
PRINT '  Bloques horarios: ' + CAST(@resBloq AS VARCHAR(10));
PRINT '  Turnos totales: ' + CAST(@resTurn AS VARCHAR(10));
PRINT '  Turnos disponibles: ' + CAST(@resTurnDisp AS VARCHAR(10));
PRINT '  Turnos reservados: ' + CAST(@resTurnRes AS VARCHAR(10));
PRINT '';
PRINT 'RESERVAS TOTALES:';
PRINT '  Total: ' + CAST(@resTotalRes AS VARCHAR(10));
PRINT '  Atendidas: ' + CAST(@resAten AS VARCHAR(10)) + ' (' + 
      CAST(CAST(@resAten * 100.0 / NULLIF(@resTotalRes, 0) AS DECIMAL(5,2)) AS VARCHAR(10)) + '%)';
PRINT '  Canceladas: ' + CAST(@resCan AS VARCHAR(10)) + ' (' + 
      CAST(CAST(@resCan * 100.0 / NULLIF(@resTotalRes, 0) AS DECIMAL(5,2)) AS VARCHAR(10)) + '%)';
PRINT '  Ausencias: ' + CAST(@resAus AS VARCHAR(10)) + ' (' + 
      CAST(CAST(@resAus * 100.0 / NULLIF(@resTotalRes, 0) AS DECIMAL(5,2)) AS VARCHAR(10)) + '%)';
PRINT '  Activas futuras: ' + CAST(@resAct - @resAus AS VARCHAR(10)) + ' (' + 
      CAST(CAST((@resAct - @resAus) * 100.0 / NULLIF(@resTotalRes, 0) AS DECIMAL(5,2)) AS VARCHAR(10)) + '%)';
PRINT '';
PRINT 'DISTRIBUCIÓN POR MES:';
PRINT '  OCTUBRE 2025: ' + CAST(@resOct AS VARCHAR(10)) + ' reservas';
PRINT '  NOVIEMBRE 2025: ' + CAST(@resNov AS VARCHAR(10)) + ' reservas';
PRINT '';
PRINT '================================================================================';
PRINT 'Fecha/Hora finalización: ' + CONVERT(VARCHAR(20), GETDATE(), 120);
PRINT '================================================================================';
PRINT '';
PRINT 'Base de datos lista para pruebas y presentación.';
PRINT 'Datos realistas con cancelaciones, ausencias y diagnósticos variados.';
GO