
## Funciones y Procedimientos Almacenados

Las funciones y procedimientos almacenados son bloques de código SQL que residen directamente en la base de datos. Ambos permiten encapsular lógica de negocio y ejecutarse repetidamente, pero difieren en su propósito, restricciones y forma de interactuar con el motor SQL.

### **Concepto General**

Estos objetos suelen incluir lógica de control de flujo como `IF / ELSE`, ciclos `WHILE`, manejo de variables y parámetros. Su función principal es centralizar reglas, cálculos y operaciones complejas para mantener consistencia y reducir duplicación de código en la aplicación.

---

### **Procedimientos Almacenados**

Los procedimientos almacenados están diseñados para **realizar acciones** dentro de la base de datos. Son altamente flexibles y permiten múltiples operaciones encadenadas.

#### **Características principales**

* Pueden ejecutar instrucciones `INSERT`, `UPDATE`, `DELETE` y `SELECT`.
* Admiten **parámetros de entrada, salida o ambos**.
* No están obligados a devolver un valor, aunque pueden devolver conjuntos de resultados mediante `SELECT`.
* En el contexto de nuestro proyecto son ideales para procesos complejos como:

  * registrar una reserva,
  * crear bloques horarios en conjunto con sus turnos,
  * generar estadísticas.

---

### **Funciones Almacenadas**

Las funciones almacenadas están diseñadas para **calcular y devolver un único valor**. Por esa razón, pueden ser utilizadas dentro de cláusulas SQL como cualquier expresión.

#### **Características principales**

* **Siempre devuelven un único valor** (numérico, cadena, fecha, etc.).
* No pueden ejecutar acciones que modifiquen datos (`INSERT`, `UPDATE`, `DELETE`).
* Pueden ser llamadas directamente en:

  * `SELECT`
  * `WHERE`
  * `ORDER BY`
  * `JOIN`
* Son ideales para cálculos auxiliares, como:

  * obtener la edad de un paciente,
  * calcular porcentajes,
  * obtener la próxima fecha de un día específico,
  * generar valores derivados.

---

## Rol: Médico

### 1. Función: fn_ProximaFechaDelDia

Esta función se encarga de calcular, a partir de una fecha inicial, la próxima fecha que coincida con un día específico de la semana. Es fundamental para optimizar la generación de turnos, evitando recorrer día por día cuando no es necesario.

#### Explicación Técnica
* Recibe una fecha inicial y un identificador de día (1=Lunes … 7=Domingo).
* Calcula el día de la semana correspondiente a dicha fecha.
* Si ya coincide con el día solicitado, retorna la misma fecha.
* Si no coincide, calcula cuántos días faltan hasta llegar al día deseado.
* El ajuste incluye sumarle 7 días cuando el cálculo resulte negativo, asegurando siempre un valor válido y futuro.

Esta función se utiliza directamente dentro del procedimiento med_GenerarTurnosPorBloque para optimizar el salto entre fechas.

```sql
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
```

---

### 2. Procedimiento: med_GenerarTurnosPorBloque

Este procedimiento es responsable de generar todos los turnos correspondientes a un bloque horario determinado. Aprovecha la función fn_ProximaFechaDelDia para trabajar de manera eficiente.

#### Objetivo
Crear turnos automáticamente para un médico en un rango de fechas y horario predefinido, respetando:
* Día específico de atención.
* Inicio y fin del bloque.
* Duración de cada turno.

#### Explicación:
1. **Lectura del bloque horario**: Obtiene parámetros como fecha de inicio, fin, duración de turnos, médico asignado y día de atención.
2. **Cálculo de la primera fecha válida**: Utiliza fn_ProximaFechaDelDia para ubicar el primer día del bloque que coincida con el día configurado.
3. **Iteración semanal**: En lugar de recorrer día por día, avanza de 7 en 7, puesto que cada semana el mismo día vuelve a presentarse.
4. **Generación de turnos dentro del horario**:
   * Se inicializa la hora actual en la hora de inicio.
   * Se generan turnos sumando la duración especificada hasta alcanzar la hora de fin.

```sql
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
```

## Rol: Recepcionista

### 1. Función: `fn_CalcularEdad`

Esta función calcula la edad exacta de un paciente considerando no solo el año, sino también si aún no cumplió años en el año actual.

#### Explicación técnica

* Se calcula una edad preliminar restando el año de nacimiento del año actual.
* Luego se verifica si el mes y día de nacimiento aún no fueron alcanzados en el año corriente.
* Si ese es el caso, se descuenta un año, obteniendo la edad correcta.

Esta función es utilizada principalmente en procedimientos que requieren análisis demográfico, como `rec_EstadisticaPacientes`.
```sql
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

```
---

### 2. Procedimiento: `rec_EstadisticaPacientes`

Este procedimiento permite analizar el perfil poblacional de los pacientes que realizaron reservas dentro de un rango de fechas.

#### Objetivo

Brindar indicadores demográficos clave para la recepción o gestión administrativa, tales como:

* Promedio de edad.
* Distribución en rangos etarios.
* Porcentaje de pacientes con y sin obra social.

#### Explicación paso a paso

1. **Recolección de pacientes únicos**:

   * Se utiliza una CTE (`PacientesReserva`) para obtener solo pacientes que poseen al menos una reserva en el rango de fechas.
   * Calcula la edad utilizando `fn_CalcularEdad`.
   * Incluye obra social para su posterior análisis.

2. **Cálculos agregados**:

   * Promedio de edad utilizando `AVG()`.
   * Cantidad de pacientes por franja etaria: menores, adultos, mayores.
   * Porcentajes sobre el total de pacientes encontrados.
   * Cantidad y porcentaje de pacientes con y sin obra social.

3. **Retorno de resultados en un único SELECT** perfectamente estructurado para su uso dentro del sistema.
```sql
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
```
---
## Rol: Administrador

### 1. Función: `fn_Porcentaje`

Esta función permite calcular porcentajes de manera uniforme y reutilizable en todos los procedimientos administrativos. Se utiliza especialmente en los informes que requieren mostrar proporciones relativas respecto del total de reservas.

#### Explicación técnica

* Recibe dos parámetros: un valor parcial y un total.
* Si el total es cero o nulo, retorna 0 para evitar divisiones inválidas.
* De lo contrario, calcula `(Parcial * 100) / Total` con formato decimal controlado.

Esta función centraliza la lógica de porcentajes, evitando repetición de código y garantizando coherencia en todos los cálculos.
```sql
CREATE OR ALTER FUNCTION fn_Porcentaje
(
    @Parcial DECIMAL(18,2),
    @Total   DECIMAL(18,2)
)
RETURNS DECIMAL(6,2)
AS
BEGIN
    IF @Total IS NULL OR @Total = 0
        RETURN 0;

    RETURN CAST((@Parcial * 100.0) / @Total AS DECIMAL(6,2));
END;
GO
```
---

### 2. Procedimiento: `admin_EstadisticaClinicaGeneral`

Este procedimiento brinda una visión global del funcionamiento de la clínica en un rango de fechas. Permite al rol administrador observar tendencias y realizar evaluaciones del desempeño general.

#### Objetivo

Obtener indicadores agregados de:

* Reservas programadas.
* Reservas atendidas.
* Reservas canceladas.
* Ausencias.
* Promedio de atenciones por médico.
* Porcentajes asociados a cada tipo de estado.

#### Explicación paso a paso

1. **Definición de variables internas**:

   * Se declaran contadores para cada tipo de estado de reserva.
   * Se almacena el total de médicos con reservas durante el período.

2. **Obtención de reservas relevantes (CTE)**:

   * Se crea una CTE (`ReservasClinica`) que reúne todas las reservas dentro del rango.
   * Se enlaza `Reserva` con `Turno` y `Bloque_Horario`.
   * Permite acceder al estado de la reserva, la fecha, y el médico asociado.

3. **Asignación de agregados**:

   * Se contabiliza la cantidad total de reservas.
   * Se calculan atendidas, canceladas y ausentes (estas últimas verificando que la fecha haya pasado y su estado siga activo).
   * Se cuenta la cantidad de médicos involucrados.

4. **Devolución final de resultados**:

   * Se presentan todos los totales.
   * Se calculan los porcentajes usando la función `fn_Porcentaje`.
   * Se calcula el promedio de reservas atendidas por médico.
```sql
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
        @TotalAtendidos = ISNULL(SUM(CASE WHEN id_estado = 3 THEN 1 ELSE 0 END), 0),
        @TotalCancelados =  ISNULL(SUM(CASE WHEN id_estado = 2 THEN 1 ELSE 0 END), 0),
        @TotalAusencias =  ISNULL(SUM(CASE WHEN id_estado = 1 AND fecha_turno < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END), 0),
        @TotalMedicos = COUNT(DISTINCT id_medico)
    FROM ReservasClinica;

    -- 4) Devolver resultados
    SELECT
        @TotalProgramados AS [Reservas Programadas],
        @TotalAtendidos  AS [Reservas Atendidas],
        @TotalCancelados AS [Reservas Canceladas],
        @TotalAusencias  AS [Reservas con Ausencia],
        dbo.fn_Porcentaje(@TotalAtendidos, @TotalProgramados) AS [% Atendidas],
        dbo.fn_Porcentaje(@TotalCancelados, @TotalProgramados) AS [% Canceladas],
        dbo.fn_Porcentaje(@TotalAusencias, @TotalProgramados) AS [% Ausencias],
        CASE WHEN @TotalMedicos = 0 THEN 0
             ELSE CAST(@TotalAtendidos * 1.0 / @TotalMedicos AS DECIMAL(6,2))
        END AS [Promedio de Reservas Atendidas por Médico];
END;
GO
```

## Ejecución de Sentencias Manual (Ad Hoc) vs. Ejecución mediante Procedimientos y Funciones Almacenadas

| **Aspecto**                      | **Sentencias Manuales (Ad Hoc)**                                                            | **Procedimientos y Funciones Almacenadas**                                                     |
| -------------------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **Procesamiento y rendimiento**  | Cada sentencia se analiza y optimiza cada vez que se ejecuta. Mayor costo de procesamiento. | Se compilan una vez y luego se ejecutan rápidamente sin repetir el proceso de optimización.    |
| **Reutilización de lógica**      | La lógica queda dispersa y duplicada en distintas partes de la aplicación.                  | La lógica se encapsula dentro de la base de datos y se reutiliza desde un único punto.         |
| **Consistencia y mantenimiento** | Requiere actualizar la misma lógica en múltiples lugares; riesgo de inconsistencias.        | Una sola actualización impacta todo el sistema; garantiza uniformidad en la lógica de negocio. |
| **Seguridad**                    | Necesita permisos directos sobre las tablas, exponiendo datos sensibles.                    | Solo requiere permisos de ejecución; evita acceso directo a la información interna.            |


---

## **Conclusión**

La ejecución mediante procedimientos y funciones almacenadas ofrece una arquitectura más robusta, segura y eficiente para el manejo de datos.
Mientras que las sentencias manuales brindan flexibilidad, suelen producir:

* menor rendimiento,
* duplicación de lógica,
* mayor probabilidad de errores,
* y riesgos de seguridad.

En cambio, las rutinas almacenadas:

* **mejoran el rendimiento** gracias a la precompilación,
* **centralizan y estandarizan la lógica de negocio**,
* **incrementan la seguridad** evitando acceso directo a las tablas,
* y **simplifican el mantenimiento** para sistemas en crecimiento.

Por estos motivos, constituyen la opción profesional más adecuada para sistemas que requieren integridad, rendimiento y escalabilidad, como un software de gestión de turnos médicos.
