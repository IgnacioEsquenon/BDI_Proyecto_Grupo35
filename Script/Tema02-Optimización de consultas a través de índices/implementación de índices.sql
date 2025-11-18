USE MedoraDB

/*======================================================================================================*/

SET NOCOUNT ON

-- Creamos los valores que permiten repetir el while 3 millones de veces
DECLARE @i INT = 1
DECLARE @max INT = 3000000

-- Atributos para los campos de la tabla Bloque_Horario
DECLARE @fecha_inicio DATE
DECLARE @fecha_fin DATE
DECLARE @hora_inicio TIME(7)
DECLARE @hora_fin TIME(7)
DECLARE @id_medico INT
DECLARE @id_dia INT

-- Atributos auxiliares para cálculos de tiempo
DECLARE @minutos_inicio_base INT
DECLARE @duracion_total_minutos INT

WHILE @i <= @max
BEGIN
    -- arrancamos el 1 de enero de 2020 en adelante
    -- Usamos CHECKSUM(NEWID()) para aleatoriedad dentro del bucle
    SET @fecha_inicio = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1825, '2020-01-01')

    -- Fecha Fin: Estrictamente mayor a fecha_inicio
    -- Sumamos al menos 1 día (del 1 al 10) a la fecha de inicio
    SET @fecha_fin = DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 10) + 1, @fecha_inicio)


    -- generamos un minuto de inicio aleatorio entre 0 y 1320 (hasta las 22:00 hs)
    SET @minutos_inicio_base = ABS(CHECKSUM(NEWID())) % 1320;
    
    -- establecemos hora_inicio
    SET @hora_inicio = CAST(DATEADD(MINUTE, @minutos_inicio_base, '00:00') AS TIME(7))

    -- seleccion de hora_fin que tiene que ser mayor a 30 min con hora_inicio que es lo que dura cada turno
    -- Sumamos 30 fijos + un aleatorio extra (0 a 90 min)
    SET @duracion_total_minutos = 30 + (ABS(CHECKSUM(NEWID())) % 90)
    
    SET @hora_fin = CAST(DATEADD(MINUTE, @minutos_inicio_base + @duracion_total_minutos, '00:00') AS TIME(7))

    -- seleccion de aleatorios de medico y dia
    -- permite variar entre los id_medico entre 2, 3 y 4
    -- Formula: (Random % 3) da 0,1,2. Al sumar 2 obtenemos 2,3,4.
    SET @id_medico = (ABS(CHECKSUM(NEWID())) % 3) + 2

    --permite variar entre los id_dia entre 1 y 6
    -- Formula: (Random % 6) da 0..5. Al sumar 1 obtenemos 1..6.
    SET @id_dia = (ABS(CHECKSUM(NEWID())) % 6) + 1

    --insertamos los valores
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
        @fecha_inicio, 
        @fecha_fin, 
        @hora_inicio, 
        @hora_fin, 
        30, 
        1, 
        @id_medico, 
        @id_dia
    );

    -- contador de a uno
    SET @i = @i + 1
END;

SET NOCOUNT OFF
/*======================================================================================================*/

--Cantidad de registros en bloque_horario
SELECT 
    *
FROM Bloque_Horario

-- Creamos una copia de esa tabla
SELECT *
INTO Bloque_Horario2
FROM Bloque_Horario


-- Consultamos si nuestra copia tiene indice agrupado
EXEC sp_helpindex 'Bloque_Horario2'

--The object 'Bloque_Horario2' does not have any indexes, or you do not have permissions.

-- Activamos las estadisticas de tiempo de ejecución de cpu y tiempo total
SET STATISTICS TIME ON;

--Realizamos una búsqueda por perídos en la tabla sin índices
SELECT *
FROM Bloque_Horario2
WHERE fecha_inicio between '20210101' AND '20241031'

--tiempos de ejecucion
/*  SQL Server Execution Times:
   CPU time = 1719 ms,  elapsed time = 1201 ms.*/

--Creamos un índice agrupado en la tabla auxiliar sobre la columna fecha_inicio
CREATE CLUSTERED INDEX IX_fecha_inicio
ON Bloque_Horario2 (fecha_inicio)

--Repetimos la consulta anterior en la tabla con indice agrupado
SELECT *
FROM Bloque_Horario2
WHERE fecha_inicio between '20210101' AND '20241031'

/* SQL Server Execution Times:
   CPU time = 797 ms,  elapsed time = 887 ms.*/


-- Eliminamos el índice que creamos
DROP INDEX IX_fecha_inicio
ON Bloque_Horario2;


-- Creamos otro índice sobre la columna fecha incluyento columnas seleccionadas
CREATE CLUSTERED INDEX IX_fecha_inicio
ON Bloque_Horario2 (fecha_inicio, id_bloque, fecha_fin, hora_inicio, hora_fin, duracion_turnos, activo, id_medico, id_dia)

--Repetimos la misma consulta con el indice agrupado sobre la columna fecha_inicio y las columnas seleccionadas
SELECT *
FROM Bloque_Horario2
WHERE fecha_inicio between '20210101' AND '20241031'

/*SQL Server Execution Times:
   CPU time = 750 ms,  elapsed time = 864 ms.*/

