# Implementación de optimización de consultas a través de índices sobre el caso de estudio: MedoraDB

Para esta sencilla demostración lo que vamos a realizar es una inserción de 3 millones de registros en una tabla y sobre una tabla auxiliar copia de ella vamos a implementar las consultar añadiendo los índices y documentando las diferencias en plan de ejecución y los tiempos de respuesta

# Inserción del lote de datos en la tabla Bloque\_Horario
```sql
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
```
# Creación de la tabla auxiliar copia
```sql
SELECT *
INTO Bloque_Horario2
FROM Bloque_Horario
```
# Consulta si existe índice sobre la tabla auxiliar

```sql
EXEC sp_helpindex 'Bloque_Horario2'
```
# Activamos las estadísticas de tiempo de ejecución

```sql
SET STATISTICS TIME ON;
```
# Consulta sobre la tabla sin indices

```sql
SELECT *
FROM Bloque_Horario2
WHERE fecha_inicio between '20210101' AND '20241031'

--tiempos de ejecucion
/*  SQL Server Execution Times:
   CPU time = 1719 ms,  elapsed time = 1201 ms.*/
```

# Creación del índice agrupado sobre la columna fecha\_inicio

```sql
CREATE CLUSTERED INDEX IX_fecha_inicio
ON Bloque_Horario2 (fecha_inicio)
```
# Consulta sobre la tabla con índice agrupado sobre columna fecha\_inicio

```sql
SELECT *
FROM Bloque_Horario2
WHERE fecha_inicio between '20210101' AND '20241031'

/* SQL Server Execution Times:
   CPU time = 797 ms,  elapsed time = 887 ms.*/
```

# Eliminamos el índice 

```sql
DROP INDEX IX_fecha_inicio
ON Bloque_Horario2;
```

# Creamos el índice agrupado sobre la columna fecha\_inicio y las columnas seleccionadas

```sql
CREATE CLUSTERED INDEX IX_fecha_inicio
ON Bloque_Horario2 (fecha_inicio, id_bloque, fecha_fin, hora_inicio, hora_fin, duracion_turnos, activo, id_medico, id_dia)
```

# Repetimos la consulta

```sql
SELECT *
FROM Bloque_Horario2

WHERE fecha_inicio between '20210101' AND '20241031'

/*SQL Server Execution Times:
   CPU time = 750 ms,  elapsed time = 864 ms.*/
```

# Plan de ejecución en la tabla sin indices
<img width="1153" height="469" alt="image" src="https://github.com/user-attachments/assets/732b1a28-64d4-4019-9797-db625959524f" />
Se puede observar que el plan de ejecución consiste en la lectura de la tabla registro por registro y luego decide aplicar paralelismo para obtener los resultados mas rapidos dividiendo la carga de trabajo en distintos hilos.
Con un tiempo de ejecución de 1719 ms, un tiempo total de 1201 ms y un total de 2.300.964 registros obtenidos

# Plan de ejecución en la tabla con índice agrupado sobre la columna fecha inicio
<img width="661" height="296" alt="image" src="https://github.com/user-attachments/assets/ddddd399-c73e-4495-9613-94e23d201132" />
El plan de ejecución cambió ya que se aplicó el indice agrupado sobre la columna que estamos haciendo la consulta. Es decir que el motor solamente tuvo que ir directo al primer índice que cumple con lo solicitado en la consulta reduciendo drásticamente el tiempo de ejecución. 
Con un tiempo de ejecución de 797 ms, un tiempo total de 887 ms y un total de 2.300.964 registros obtenidos.

# Plan de ejecución en la tabla con índice agrupado sobre la columna fecha inicio
<img width="1238" height="364" alt="image" src="https://github.com/user-attachments/assets/d3d3ddd5-fa57-4dba-81e7-b4f36c68bbe0" />
El plan de ejecución no cambió a simple vista, la diferencia es que la consulta no tuvo que leer un indice y luego un registro, solo tuvo que leer índices por lo que disminuyó un poco su tiempo de ejecución.
Con un tiempo de ejecución de 750 ms, un tiempo total de 864 ms y un total de 2.300.964 registros obtenidos

# Conclusiones
A través de este ejercicio pudimos visualizar la potencia de esta técnica de optimización que resulta indispensable para los sistemas modernos que requieren de enormes consultas con millones de registros en distintas bases de datos al bajar drásticamente el tiempo de ejecución moviendo mas de dos millones de registros. Con respecto a la investigación pudimos profundizar en los tipos de indices existentes y los elementos que los componen.





