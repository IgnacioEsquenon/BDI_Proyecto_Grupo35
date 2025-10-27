----- Creación de la Base de Datos 'MedoraDB' ================================================================================

CREATE DATABASE MedoraDB;
GO

USE MedoraDB;
GO

----- Estructura ================================================================================
----- Tablas ====================================================================================
    -- Especialidad -----------------------------------------------------------------------------
        CREATE TABLE Especialidad (
          id_especialidad INT IDENTITY(1,1),
          nombre VARCHAR(50) NOT NULL,
          CONSTRAINT PK_Especialidad PRIMARY KEY (id_especialidad),
          CONSTRAINT UK_Especialidad_Unica UNIQUE (nombre)
        );

        INSERT INTO Especialidad (nombre)
        VALUES ('Cardiología'), ('Pediatria'), ('Dermatologia'), ('Ginecología'), ('Urología'), ('Traumatologia'), ('Clinica Medica'); 
        GO

    -- Rol --------------------------------------------------------------------------------------
        CREATE TABLE Rol (
          id_rol INT NOT NULL,
          nombre VARCHAR(30) NOT NULL,
          CONSTRAINT PK_Rol PRIMARY KEY (id_rol)
        );

        INSERT INTO Rol (id_rol, nombre)
        VALUES (1, 'Administrador'), (2, 'Médico'), (3, 'Recepcionista');
        GO

    -- Usuario ----------------------------------------------------------------------------------
        CREATE TABLE Usuario (
          id_usuario INT IDENTITY(1,1),
          nombre VARCHAR(50) NOT NULL,
          apellido VARCHAR(50) NOT NULL,
          dni VARCHAR(15) NOT NULL,
          email VARCHAR(50) NOT NULL,
          telefono VARCHAR(20) NOT NULL,
          contraseña_hash VARCHAR(100) NOT NULL,
          id_especialidad INT NULL,
          id_rol INT NOT NULL,
          CONSTRAINT PK_Usuario PRIMARY KEY (id_usuario),
          CONSTRAINT FK_Especialidad_Medico FOREIGN KEY (id_especialidad) REFERENCES Especialidad(id_especialidad),
          CONSTRAINT FK_Rol_Usuario FOREIGN KEY (id_rol) REFERENCES Rol(id_rol),
          CONSTRAINT UK_Dni_Usuario UNIQUE (dni),
          CONSTRAINT UK_Email_Usuario UNIQUE (email),
          CONSTRAINT UK_Telefono_Usuario UNIQUE (telefono),
        );

          INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
          VALUES ('Roberto', 'Sanchez', '212348124', 'admin@mail.com', '36412312', 'hash123', NULL, 1); -- Administrador

          INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
          VALUES ('Juan', 'Pérez', '26938124', 'med1@mail.com', '3682193212', 'hash123', 1, 2); -- Cardiólogo

          INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
          VALUES ('Mirna', 'Mettini', '2134623', 'med2@mail.com', '32146342', 'hash123', 2, 2); -- Pediatra

          INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
          VALUES ('Laura', 'Juarez', '32194823', 'med3@mail.com', '381264812', 'hash123', 3, 2); -- Dermatóloga

          INSERT INTO Usuario (nombre, apellido, dni, email, telefono, contraseña_hash, id_especialidad, id_rol)
          VALUES ('Romina', 'Marquez', '299383514', 'recep@mail.com', '321874923', 'hash123', NULL, 3); -- Recepcionista
        GO

    -- Día --------------------------------------------------------------------------------------
        CREATE TABLE Día (
          id_dia INT NOT NULL,
          nombre VARCHAR(15) NOT NULL,
          CONSTRAINT PK_Dia PRIMARY KEY (id_dia)
        );

        INSERT INTO Día (id_dia, nombre)
        VALUES (1, 'Lunes'), (2, 'Martes'), (3, 'Miércoles'), (4, 'Jueves'), (5, 'Viernes'), (6, 'Sábado');
        GO

    -- Bloque Horario ----------------------------------------------------------------------------
        CREATE TABLE Bloque_Horario (
          id_bloque INT IDENTITY(1,1) PRIMARY KEY,
          fecha_inicio DATE NOT NULL,
          fecha_fin DATE NOT NULL,
          hora_inicio TIME NOT NULL,
          hora_fin TIME NOT NULL,
          duracion_turnos INT NOT NULL,
          activo BIT DEFAULT 1,
          id_medico INT NOT NULL,
          id_dia INT NOT NULL,
          CONSTRAINT FK_Usuario_Bloque FOREIGN KEY (id_medico) REFERENCES Usuario(id_usuario),
          CONSTRAINT FK_Dia_Bloque FOREIGN KEY (id_dia) REFERENCES Día(id_dia),
          CONSTRAINT CK_DuracionNoNula CHECK (duracion_turnos > 0),
          CONSTRAINT CK_FechaValida CHECK (fecha_inicio < fecha_fin),
          CONSTRAINT CK_DuracionMinimaDeJornada CHECK (datediff (minute, [hora_inicio], [hora_fin]) >= [duracion_turnos])
        );
        GO

    -- Estado de Turno ---------------------------------------------------------------------------
        CREATE TABLE Estado_Turno (
          id_estado_turno INT NOT NULL,
          nombre VARCHAR(20) NOT NULL,
          CONSTRAINT PK_Estado_Turno PRIMARY KEY (id_estado_turno)
        );

        INSERT INTO Estado_Turno (id_estado_turno, nombre)
        VALUES (1, 'Disponible'), (2, 'Reservado'), (3, 'Inactivo');
        GO

    -- Turno ----------------------------------------------------------------------------
        CREATE TABLE Turno (
          id_turno INT IDENTITY(1,1),
          fecha_turno DATE NOT NULL,
          hora_inicio TIME NOT NULL,
          hora_fin TIME NOT NULL,
          id_bloque INT NOT NULL,
          id_estado_turno INT NOT NULL DEFAULT 1,
          CONSTRAINT PK_Turno PRIMARY KEY (id_turno),
          CONSTRAINT FK_Bloque_Turno FOREIGN KEY (id_bloque) REFERENCES Bloque_Horario(id_bloque),
          CONSTRAINT FK_Estado_Turno FOREIGN KEY (id_estado_turno) REFERENCES Estado_Turno(id_estado_turno),
          CONSTRAINT CK_HorarioValido CHECK (hora_inicio < hora_fin)
        );
        GO

    -- Estado de Reserva ----------------------------------------------------------------
        CREATE TABLE Estado_Reserva (
          id_estado INT NOT NULL,
          nombre VARCHAR(20) NOT NULL
          CONSTRAINT PK_Estado_Reserva PRIMARY KEY (id_estado)
        );

        INSERT INTO Estado_Reserva (id_estado, nombre)
        VALUES (1, 'Activa'), (2, 'Cancelada'), (3, 'Atendida');
        GO

    -- Obra Social ----------------------------------------------------------------------
        CREATE TABLE Obra_Social (
            id_obra_social INT PRIMARY KEY IDENTITY(1,1),
            nombre VARCHAR(100) NOT NULL UNIQUE
        ); 

        INSERT INTO Obra_Social (nombre) VALUES
        ('IOSCOR'),
        ('PAMI'),
        ('OSDE'),
        ('SWISS MEDICAL');

        GO

    -- Paciente ----------------------------------------------------------------
        CREATE TABLE Paciente (
          id_paciente INT IDENTITY(1,1),
          nombre VARCHAR(50) NOT NULL,
          apellido VARCHAR(50) NOT NULL,
          dni VARCHAR(15) NOT NULL,
          email VARCHAR(50) NOT NULL,
          telefono VARCHAR(20) NOT NULL,
          id_obra_social INT,
          CONSTRAINT PK_Paciente PRIMARY KEY (id_paciente),
          CONSTRAINT UK_Dni_Paciente UNIQUE (dni),
          CONSTRAINT UK_Email_Paciente UNIQUE (email),
          CONSTRAINT UK_Telefono_Paciente UNIQUE (telefono),
          CONSTRAINT FK_Paciente_Obra_Social FOREIGN KEY (id_obra_social) REFERENCES Obra_Social(id_obra_social)
        );

        INSERT INTO Paciente (nombre, apellido, dni, email, telefono, id_obra_social)
        VALUES ('Ramón', 'Méndez', '22837412', 'ramon@mail.com', '3682191232', 1);

        INSERT INTO Paciente (nombre, apellido, dni, email, telefono, id_obra_social)
        VALUES ('Juan', 'Lopez', '22835122', 'juan@mail.com', '32142321', 2);

        INSERT INTO Paciente (nombre, apellido, dni, email, telefono, id_obra_social)
        VALUES ('Carla', 'Fernandez', '3214231', 'carla@mail.com', '31242132', NULL);
        GO

    -- Motivo de Consulta --------------------------------------------------------
        CREATE TABLE Motivo_Consulta (
          id_motivo_consulta INT PRIMARY KEY IDENTITY(1,1),
          descripcion VARCHAR(255) NOT NULL,
          id_especialidad INT NOT NULL,

          CONSTRAINT FK_MotivoConsulta_Especialidad
          FOREIGN KEY (id_especialidad) REFERENCES Especialidad(id_especialidad)
        );
        

        -- Insert para Cardiologia --
        INSERT INTO Motivo_Consulta 
        VALUES  ('Dolor de Pecho',1), 
                ('Mareos',1), 
                ('Falta de Aire',1), 
                ('Taquicardia',1), 
                ('Arritmia',1);

        --Insert para Pediatria -- 
        INSERT INTO Motivo_Consulta 
        VALUES  ('Fiebre',2), 
                ('Diarrea',2), 
                ('Constipacion',2), 
                ('Vomitos',2), 
                ('Dificultad para Caminar',2);

        --Insert para Dermatologia -- 
        INSERT INTO Motivo_Consulta 
        VALUES  ('Quemaduras',3), 
                ('Urticarias',3), 
                ('Acne',3), 
                ('Picaduras',3), 
                ('Despigmentacion',3); 

        --Insert para Traumatologia --
        INSERT INTO Motivo_Consulta 
        VALUES  ('Fractura',6), 
                ('Dolor Lumbar',6), 
                ('Artrosis',6), 
                ('Dolor de Cervicales',6), 
                ('Vertigo',6); 

        --Insert para Clinica Medica -- 
        INSERT INTO Motivo_Consulta 
        VALUES  ('Dolor Abdominal',7), 
                ('Cefaleas',7), 
                ('Sintoma Gastrointestinal',7), 
                ('Hipoglucemia',7), 
                ('Hipertension Arterial',7);
        GO

    -- Reserva ------------------------------------------------------------------
        CREATE TABLE Reserva (
          id_reserva INT IDENTITY(1,1),
          diagnostico VARCHAR(500) DEFAULT NULL,
          id_estado INT NOT NULL DEFAULT 1,
          id_turno INT NOT NULL,
          id_paciente INT NOT NULL,
          id_motivo_consulta INT NOT NULL,
          CONSTRAINT PK_Reserva PRIMARY KEY (id_reserva),
          CONSTRAINT FK_Estado_Reserva FOREIGN KEY (id_estado) REFERENCES Estado_Reserva(id_estado),
          CONSTRAINT FK_Turno_Reserva FOREIGN KEY (id_turno) REFERENCES Turno(id_turno),
          CONSTRAINT FK_Paciente_Reserva FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente),
          CONSTRAINT FK_Motivo_Reserva FOREIGN KEY (id_motivo_consulta) REFERENCES Motivo_Consulta(id_motivo_consulta),
          CONSTRAINT UK_Turno UNIQUE (id_turno)
        );
        GO

----------------------------------------------------------------------------------------------
