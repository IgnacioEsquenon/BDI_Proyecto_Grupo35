-- =============================================

--   CREACIÓN DE BASE DE DATOS MEDORA

CREATE DATABASE MedoraDB;
GO

USE MedoraDB;
GO

-- =================== ESTRUCTURA ==========================

--   TABLA: Especialidad
CREATE TABLE Especialidad (
  id_especialidad INT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  CONSTRAINT PK_Especialidad PRIMARY KEY (id_especialidad)
);

INSERT INTO Especialidad (id_especialidad, nombre)
VALUES (1, 'Cardiología'), (2, 'Oftalmología'), (3, 'Pediatría'), (4, 'Ginecología'), (5, 'Urología'), (6, 'Atención Primaria');
GO

-- =============================================

--   TABLA: Rol
CREATE TABLE Rol (
  id_rol INT NOT NULL,
  nombre VARCHAR(30) NOT NULL,
  CONSTRAINT PK_Rol PRIMARY KEY (id_rol)
);

INSERT INTO Rol (id_rol, nombre)
VALUES (1, 'Administrador'), (2, 'Médico'), (3, 'Recepcionista');
GO

-- =============================================

--   TABLA: Usuario
CREATE TABLE Usuario (
  id_usuario INT IDENTITY(1,1),
  nombre VARCHAR(50) NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  dni VARCHAR(15) NOT NULL,
  email VARCHAR(50) NOT NULL,
  telefono NUMERIC(12),
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
  VALUES ('Juan', 'Pérez', '26938124', 'juan@mail.com', null, 'hash123', 6, 2);
GO

-- =============================================

--   TABLA: Día
CREATE TABLE Día (
  id_dia INT NOT NULL,
  nombre VARCHAR(15) NOT NULL,
  CONSTRAINT PK_Dia PRIMARY KEY (id_dia)
);

INSERT INTO Día (id_dia, nombre)
VALUES (1, 'Lunes'), (2, 'Martes'), (3, 'Miércoles'), (4, 'Jueves'), (5, 'Viernes'), (6, 'Sábado');
GO


-- =============================================

--   TABLA: Bloque_Horario
CREATE TABLE Bloque_Horario (
  id_bloque INT IDENTITY(1,1) PRIMARY KEY,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  duracion_turnos INT NOT NULL,
  id_medico INT NOT NULL,
  id_dia INT NOT NULL,
  CONSTRAINT FK_Usuario_Bloque FOREIGN KEY (id_medico) REFERENCES Usuario(id_usuario),
  CONSTRAINT FK_Dia_Bloque FOREIGN KEY (id_dia) REFERENCES Día(id_dia),
  CONSTRAINT CK_DuracionNoNula CHECK (duracion_turnos > 0),
  CONSTRAINT CK_FechaValida CHECK (fecha_inicio < fecha_fin),
  CONSTRAINT CK_DuracionMinimaDeJornada CHECK (datediff (minute, [hora_inicio], [hora_fin]) >= [duracion_turnos])
);
GO

-- =============================================

--   TABLA: Estado_Turno
CREATE TABLE Estado_Turno (
  id_estado_turno INT NOT NULL,
  nombre VARCHAR(20) NOT NULL,
  CONSTRAINT PK_Estado_Turno PRIMARY KEY (id_estado_turno)
);

INSERT INTO Estado_Turno (id_estado_turno, nombre)
VALUES (1, 'Disponible'), (2, 'Reservado'), (3, 'Inactivo');
GO

-- =============================================

--   TABLA: Turno
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

-- =============================================

--   TABLA: Estado_Reserva

CREATE TABLE Estado_Reserva (
  id_estado INT NOT NULL,
  nombre VARCHAR(20) NOT NULL
  CONSTRAINT PK_Estado_Reserva PRIMARY KEY (id_estado)
);

INSERT INTO Estado_Reserva (id_estado, nombre)
VALUES (1, 'Activa'), (2, 'Cancelada'), (3, 'Atendida');
GO

-- =============================================

--   TABLA: Paciente

CREATE TABLE Paciente (
  id_paciente INT IDENTITY(1,1),
  nombre VARCHAR(50) NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  dni VARCHAR(15) NOT NULL,
  email VARCHAR(50),
  telefono VARCHAR(20),
  CONSTRAINT PK_Paciente PRIMARY KEY (id_paciente),
  CONSTRAINT UK_Dni_Paciente UNIQUE (dni),
  CONSTRAINT UK_Email_Paciente UNIQUE (email),
  CONSTRAINT UK_Telefono_Paciente UNIQUE (telefono)
);

INSERT INTO Paciente (nombre, apellido, dni, email, telefono)
VALUES ('Ramón', 'Méndez', '22837412', 'ramon@mail.com', null)
GO

-- =============================================

--   TABLA: Reserva

CREATE TABLE Reserva (
  id_reserva INT IDENTITY(1,1),
  motivo_consulta VARCHAR(200) NOT NULL,
  id_estado INT NOT NULL DEFAULT 1,
  id_turno INT NOT NULL,
  id_paciente INT NOT NULL,
  CONSTRAINT PK_Reserva PRIMARY KEY (id_reserva),
  CONSTRAINT FK_Estado_Reserva FOREIGN KEY (id_estado) REFERENCES Estado_Reserva(id_estado),
  CONSTRAINT FK_Turno_Reserva FOREIGN KEY (id_turno) REFERENCES Turno(id_turno),
  CONSTRAINT FK_Paciente_Reserva FOREIGN KEY (id_paciente) REFERENCES Paciente(id_paciente),
  CONSTRAINT UK_Turno UNIQUE (id_turno)
);
GO