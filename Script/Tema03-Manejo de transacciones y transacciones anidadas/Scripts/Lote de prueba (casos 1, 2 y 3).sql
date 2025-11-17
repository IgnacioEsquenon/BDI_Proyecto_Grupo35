USE MedoraBD;
GO

PRINT '--- 1. Insertando Nuevos Médicos ---';

-- Los nuevos médicos comenzarán desde el ID 4.
INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
VALUES 
('René', 'Favaloro', '10000001', 'rene@mail.com', '11000001', 'med123', 1, 2), -- ID 4 (Cardiología)
('Cecilia', 'Grierson', '10000002', 'cecilia@mail.com', '11000002', 'med123', 4, 2), -- ID 5 (Ginecología)
('Salvador', 'Mazza', '10000003', 'salvador@mail.com', '11000003', 'med123', 7, 2); -- ID 6 (Clínica Médica)
GO

PRINT '--- 2. Insertando Pacientes ---';

INSERT INTO Paciente (nombre, apellido, dni, email, telefono, fecha_nacimiento, id_obra_social)
VALUES
('Lionel', 'Messi', '30000001', 'leo@mail.com', '34100001', '1987-06-24', 1), -- IOSCOR
('Emiliano', 'Martinez', '30000002', 'dibu@mail.com', '34100002', '1992-09-02', 3), -- OSDE
('Julian', 'Alvarez', '30000003', 'araña@mail.com', '34100003', '2000-01-31', 1), -- IOSCOR
('Angel', 'Di Maria', '30000004', 'fideo@mail.com', '34100004', '1988-02-14', NULL), -- Particular
('Rodrigo', 'De Paul', '30000005', 'rodri@mail.com', '34100005', '1994-05-24', 2); -- PAMI
GO

PRINT '--- 3. Insertando Bloques Horarios (Futuros) ---';

-- Dr. Favaloro (ID 4) - Lunes (ID 1)
INSERT INTO Bloque_Horario (fecha_inicio, fecha_fin, hora_inicio, hora_fin, duracion_turnos, id_medico, id_dia)
VALUES ('2025-11-17', '2025-12-31', '09:00', '12:00', 30, 4, 1);

-- Dra. Grierson (ID 5) - Martes (ID 2)
INSERT INTO Bloque_Horario (fecha_inicio, fecha_fin, hora_inicio, hora_fin, duracion_turnos, id_medico, id_dia)
VALUES ('2025-11-17', '2025-12-31', '15:00', '18:00', 20, 5, 2);

-- Dr. Mazza (ID 6) - Miércoles (ID 3)
INSERT INTO Bloque_Horario (fecha_inicio, fecha_fin, hora_inicio, hora_fin, duracion_turnos, id_medico, id_dia)
VALUES ('2025-11-17', '2025-12-31', '08:00', '11:00', 15, 6, 3);
GO
 
PRINT 'Lote de datos insertado satisfactoriamente'
GO