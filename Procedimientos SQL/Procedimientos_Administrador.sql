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