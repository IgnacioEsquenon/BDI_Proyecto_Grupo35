----- Recepcionista =================================================================================
----- Procedimiento #01: Registrar Paciente ---------------------------------------------------------
              CREATE OR ALTER PROCEDURE rec_RegistrarPaciente
                    @Nombre VARCHAR(50),
                    @Apellido VARCHAR(50),
                    @Dni VARCHAR(15),
                    @Email VARCHAR(100),
                    @Telefono VARCHAR(20),
                    @IdObraSocial INT = NULL -- Parámetro opcional, si no es proporcionado se asume NULL
                AS
                BEGIN
                    SET NOCOUNT ON; -- Esta sentencia indica que al hacer la consulta no se devuelva el mensaje de cuántas filas fueron afectadas.

                    INSERT INTO Paciente (nombre, apellido, dni, email, telefono, id_obra_social)
                    VALUES (@Nombre, @Apellido, @Dni, @Email, @Telefono, @IdObraSocial);
                END;
                GO
                
                --------------------------------------------
                /* Ejemplo de uso: EXEC rec_RegistrarPaciente
                                        @Nombre='Juan',
                                        @Apellido='Pérez',
                                        @Dni='12345678', 
                                        @Email='jp@gmail.com', 
                                        @Telefono='3777897856';*/
-----------------------------------------------------------------------------------------------------
----- Procedimiento #02: Listar pacientes con opción de filtrado ------------------------------------
              CREATE OR ALTER PROCEDURE rec_ListarPacientes
                    @Filtro VARCHAR(50) = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        P.id_paciente AS id_paciente,
                        P.nombre AS Nombre,
                        P.apellido AS Apellido,
                        P.dni AS DNI,
                        P.telefono AS Telefono,
                        P.email AS Email,
                        CASE
                          WHEN OS.nombre IS NULL THEN 'No posee' -- Si el nombre de la obra social es NULL se muestra ese mensaje.
                          ELSE OS.nombre                         -- De lo contrario, muestra el nombre de la obra social
                        END AS [Obra Social]                      
                    FROM Paciente P
                    LEFT JOIN Obra_Social OS ON P.id_obra_social = OS.id_obra_social
                    WHERE
                        @Filtro IS NULL -- Si es null, la evaluación dará verdadera y mostrará todas las tuplas.
                        OR UPPER(P.nombre) + ' ' + UPPER(P.apellido) LIKE '%' + UPPER(@Filtro) + '%'   -- Ejemplo, si P.nombre = Juan y @Filtro = Juan, realiza: UPPER(Juan) LIKE %UPPER(Juan)%
                        /*OR UPPER(P.apellido) LIKE '%' + UPPER(@Filtro) + '%'*/ --                                                        JUAN LIKE %JUAN% (Esto evalúa true y va a estar en la lista)
                        OR P.dni LIKE '%' + @Filtro + '%'                    -- '%' Se usa para buscar en cualquier parte de una cadena.
                    ORDER BY P.apellido, P.nombre;                           -- Por ejemplo, podría buscar '%ua%' y me aparecería 'Juan' ya que contiene en el medio esos caracteres.
                END;                                                         -- TRIM se utiliza para eliminar espacios, por ejemplo si tiene apellido doble, solo buscará las coincidencias 
                GO                                                           -- que coincidan con los caracteres del apellido, ignorando si existe un espacio.
                
                --------------------------------------------
                /* Ejemplo de uso: EXEC rec_ListarPacientes; -- Muestra todos los pacientes
                                   EXEC rec_ListarPacientes @Filtro = 'juan lop'; -- Muestra pacientes que se llamen 'juan'
                                   EXEC rec_ListarPacientes @Filtro = '45678900'; -- Muestra al paciente con DNI 45678900*/