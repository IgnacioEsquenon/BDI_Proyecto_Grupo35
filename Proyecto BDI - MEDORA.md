# Proyecto de Estudio\!

Asignatura: Base de Datos I (FACENA/UNNE)

## Integrantes: 

* Aguilar, Leandro Martin  
* Benitez, Natalia Librada  
* Esquenón, Ignacio Agustín  
* Gomez, Sebastián Exequiel

## Año: 2024

# CAPÍTULO I: INTRODUCCIÓN.

Este capítulo introduce el proyecto de estudio, proporcionando una idea clara del por qué, para qué y qué abarca su desarrollo.

## Tema y Planteamiento del Problema:

El tema se centra en el desarrollo de un sistema de gestión de turnos médicos denominado **“**Medora**”**.

El planteamiento del problema surge del panorama actual de los sistemas de gestión de turnos. Si bien existen diversas aplicaciones en el mercado (ej. Swiss Medical, OSDE), estas presentan limitaciones para clínicas pequeñas o medianas, tales como:

* Costos elevados y modelos de licenciamiento poco flexibles.

* Complejidad innecesaria para entornos administrativos reducidos.

* Dependencia de infraestructura web y conectividad constante.

El sistema Medora se plantea como una solución accesible, intuitiva y robusta, desarrollada como una aplicación de escritorio autónoma. Está orientado a clínicas pequeñas, con el objetivo de que el personal administrativo pueda gestionar fácilmente los turnos de los pacientes, y a su vez que los médicos puedan organizar de manera clara sus agendas y horarios.

## Objetivos del Trabajo Práctico:

El objetivo fundamental de este proyecto es la implementación del sistema planteado, aplicando correctamente los conceptos teóricos de bases de datos.

1. Definir y diseñar la base de datos del sistema “Medora”.

2. Implementarlo con una base de datos que permita gestionar eficientemente usuarios, agendas médicas, pacientes y turnos en entornos clínicos.

## Alcance

El sistema “Medora” funcionará como una aplicación de escritorio autónoma, cuyas funcionalidades principales incluyen:

* Registro y gestión de perfiles de usuario con roles diferenciados (médico, administrador, recepcionista).

* Gestión completa de pacientes (alta, baja, modificación).

* Gestión de turnos (búsqueda, asignación, modificación).

* Gestión de agendas de disponibilidad horaria de los médicos.

* Visualización del historial de turnos de pacientes y de médicos.

* Generación de reportes estadísticos (ocupación de agendas, demanda por especialidad, desempeño individual y general).

El diseño de su base de datos será la base para todas estas funcionalidades.

# CAPÍTULO II: MARCO REFERENCIAL.

En la actualidad, la digitalización de los procesos administrativos en el sector salud ha dejado de ser una opción para convertirse en una necesidad operativa. La administración eficiente de la agenda médica es crítica para la calidad del servicio al paciente y la optimización de los recursos de los profesionales de la salud. Sin embargo, el mercado de software actual presenta una dicotomía marcada en cuanto a la accesibilidad de estas herramientas. Al analizar el panorama de sistemas de gestión de turnos vigentes, se identifican soluciones robustas implementadas por grandes corporaciones de medicina prepaga. Si bien estas plataformas son funcionalmente completas, su diseño está orientado a grandes infraestructuras, lo que genera una brecha de acceso para pequeños y medianos centros de salud.   
El sistema Medora se posiciona dentro de este marco como una solución tecnológica diseñada específicamente para cubrir el segmento desatendido de clínicas pequeñas y medianas.

# CAPÍTULO III: METODOLOGÍA SEGUIDA.

La etapa inicial del proyecto se centró en comprender el entorno en el que operará el sistema y definir los requerimientos funcionales.

* Análisis del Mercado de Gestión Sanitaria: Se realizó una investigación sobre los sistemas de gestión de turnos vigentes. Esta tarea permitió identificar las carencias de las soluciones actuales (costos elevados, dependencia de internet) y validar la oportunidad para una aplicación de escritorio orientada a clínicas pequeñas y medianas.  
* Estudio y Abstracción de Entidades: Se procedió al planteo de las entidades participantes del sistema. Esta tarea implicó identificar los "actores" clave (médicos, pacientes, administrativos) y los objetos de negocio (turnos, historias clínicas, especialidades), definiendo sus atributos y las reglas de negocio que establecen sus interacciones.

Una vez definidos los requisitos, se utilizaron herramientas específicas para pasar del análisis funcional a un modelo de datos robusto.

* Herramientas de Diseño y Modelado (ERDPlus): Para la creación del Diagrama Entidad-Relación (DER) para visualizar las conexiones entre las entidades. Y también para la transformación del DER al esquema relacional, definiendo claves primarias, foráneas y normalización de tablas antes de la programación.  
* Entorno de Implementación (Microsoft SQL Server): La implementación de la base de datos se realizó utilizando este motor principalmente por su compatibilidad nativa y rendimiento óptimo en entornos con el sistema operativo Windows.

# CAPÍTULO IV: DESARROLLO DEL TEMA/ PRESENTACIÓN DE RESULTADOS.

En este capítulo, se presentará de forma detallada, los datos e información que se fueron recopilando para comprender, analizar el caso de estudio y conseguir los resultados esperados.

Se emplearon diversas herramientas para lograr el diseño y la gestión de la información de la base de datos. Algunas de estas herramientas nos permitieron representar gráficamente las entidades, tablas y las relaciones entre las mismas, identificando de manera clara y fácilmente los datos, su estructura y comportamiento.

## Diagrama del modelo relacional:

En la siguiente imagen se puede visualizar el diagrama relacional de la base de datos con las entidades participantes, sus atributos y las relaciones entre ellas.

![\[diagrama\_relacional\](Doc/diagrama\_relacional.jpeg)](https://github.com/IgnacioEsquenon/BDI_Proyecto_Grupo35/blob/main/Doc/diagrama_relacional.jpeg)

## Diccionario de datos:

Es la herramienta que nos permite entender mejor a las entidades con sus comportamientos y restricciones.  
Acceso al documento [\[PDF\]](https://github.com/IgnacioEsquenon/BDI_Proyecto_Grupo35/blob/main/Doc/diccionario_datos.pdf) del diccionario de datos.

## Desarrollo TEMA 1 "Procedimientos y funciones almacenadas"

Acceder a la siguiente carpeta para la descripción completa del tema [![Procedimientos y funciones almacenadas\]](https://github.com/IgnacioEsquenon/BDI_Proyecto_Grupo35/tree/main/Script/Tema01-Procedimientos%20y%20funciones%20almacenadas)

## Desarrollo TEMA 2 "Optimización de consultas a través de índices".

Acceder a la siguiente carpeta para la descripción completa del tema [\[Optimización de consultas a través de índices\]](https://github.com/IgnacioEsquenon/BDI_Proyecto_Grupo35/tree/main/Script/Tema02-Optimizaci%C3%B3n%20de%20consultas%20a%20trav%C3%A9s%20de%20%C3%ADndices)

## Desarrollo TEMA 3 "Manejo de transacciones y transacciones anidadas".

Acceder a la siguiente carpeta para la descripción completa del tema [\[Manejo de transacciones y transacciones anidadas\]](https://github.com/IgnacioEsquenon/BDI_Proyecto_Grupo35/tree/main/Script/Tema03-Manejo%20de%20transacciones%20y%20transacciones%20anidadas)

## Desarrollo TEMA 4 "Réplica de Base de Datos".

Acceder a la siguiente carpeta para la descripción completa del tema [\[Réplica de Base de Datos\]](https://github.com/IgnacioEsquenon/BDI_Proyecto_Grupo35/tree/main/Script/Tema04-R%C3%A9plica%20de%20Base%20de%20Datos)

# CAPÍTULO V: CONCLUSIONES

## Conclusión tema 1 ”Procedimientos y funciones almacenadas”: 
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
## Conclusión tema 2 “Optimización de consultas a través de índices”:
A través de este ejercicio pudimos visualizar la potencia de esta técnica de optimización que resulta indispensable para los sistemas modernos que requieren de enormes consultas con millones de registros en distintas bases de datos al bajar drásticamente el tiempo de ejecución moviendo mas de dos millones de registros. Con respecto a la investigación pudimos profundizar en los tipos de indices existentes y los elementos que los componen.
## Conclusión tema 3 “Manejo de transacciones y transacciones anidadas”:

Las pruebas realizadas en los scripts demuestran la implementación práctica y la importancia crítica del modelo ACID en SQL Server.  
Las transacciones simples (BEGIN/COMMIT/ROLLBACK) son la herramienta fundamental para garantizar la Atomicidad en operaciones de "todo o nada", previniendo la corrupción de datos.  
Los SAVEPOINTs (SAVE TRANSACTION) proveen un mecanismo de control de errores más granular. Permiten que el sistema sea resiliente, manejando fallos en tareas secundarias sin deshacer operaciones críticas que ya se han completado.  
El manejo correcto de transacciones no es una característica opcional, sino un requisito indispensable para cualquier base de datos que deba mantener la integridad y consistencia de sus datos.

## Conclusión tema 4 “Réplica de Base de Datos”:

A través de la implementación de la replicación de bases de datos, utilizando un esquema maestro-esclavo sobre dos instancias de servidor distintas en la misma máquina pudimos visualizar los procedimientos de sincronización y obtener una idea de cómo se trabaja sobre las bases de datos distribuidas.  
Con el caso de estudio trabajado (MedoraDB) pudimos profundizar sobre los conceptos aplicados en este tipo de replicación, así como también las precauciones que hay que tener para prevenir conflictos.

## 

