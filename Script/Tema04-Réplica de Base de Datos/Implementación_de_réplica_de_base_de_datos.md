# Implementación de replicación sobre el caso de estudio: MedoraDB.

Para una sencilla demostración de la aplicación de réplicas de bases de datos, se crearán dos instancias de servidores en una misma máquina donde una de ellas cumplirá con las funciones de Publicador-Distribuidor y la otra se encargará de ser Suscriptor.

# Elementos de la replicación:

## Publicador-Distribuidor:
<img width="844" height="258" alt="image" src="https://github.com/user-attachments/assets/2ab1a652-55f8-4e4f-8654-19cee6dc1c0b" />

## 

## Suscriptor:
<img width="1027" height="410" alt="image" src="https://github.com/user-attachments/assets/2297a545-f855-4d34-8823-3064625fb5f7" />

## Artículos:
<img width="699" height="494" alt="image" src="https://github.com/user-attachments/assets/08b4e851-e854-4c75-ba7d-7f770b893df3" />

## Publicación:
<img width="826" height="199" alt="image" src="https://github.com/user-attachments/assets/a8bed9d4-b071-4446-994c-74d77eaaf91c" />

## Agentes de replicación:


* ### Agente de instantáneas:
<img width="849" height="472" alt="image" src="https://github.com/user-attachments/assets/33c4fd61-42f2-4346-8ce6-cd30ca74cc9d" />

* ### Agente del lector del Log:
<img width="854" height="507" alt="image" src="https://github.com/user-attachments/assets/cb7ff78a-6b07-4f8c-b6c8-458b41466765" />

* ### Agente de distribución:
<img width="844" height="452" alt="image" src="https://github.com/user-attachments/assets/88d930b4-6a21-4cad-8d3f-61acd88dcf5c" />

# Transacciones con la replicación:

* Inserción de registros en el publicador.
<img width="974" height="542" alt="image" src="https://github.com/user-attachments/assets/c1ebcafb-b5e1-475f-9ee4-5cb2febf13d5" />

* Visualización de registros en el suscriptor
<img width="807" height="574" alt="image" src="https://github.com/user-attachments/assets/1c1f2cfb-9b42-4b08-9287-0e5d1bb6f2d2" />

* Intento de inserción de registros en el suscriptor
<img width="936" height="483" alt="image" src="https://github.com/user-attachments/assets/69ab0d30-97f1-4ba0-b133-cc1a9ba8fe22" />

* Inserción de registro exitosa en el suscriptor
<img width="904" height="431" alt="image" src="https://github.com/user-attachments/assets/40c65c50-f805-40c1-b439-75b70fd07442" />


* Consulta del registro insertado en el publicador
<img width="902" height="454" alt="image" src="https://github.com/user-attachments/assets/b9927284-d569-40fd-b447-6c1e3eea9e08" />

* Inserción de registro en el publicador con la misma PK que ya tiene un registro en el suscriptor
<img width="905" height="423" alt="image" src="https://github.com/user-attachments/assets/07b217fd-0c83-468e-b71d-73f4445c5f51" />

* Error de sincronización
<img width="903" height="203" alt="image" src="https://github.com/user-attachments/assets/034072c0-b733-488e-9168-9979b2e8ca44" />

* Eliminación del registro conflictivo en el suscriptor
<img width="904" height="321" alt="image" src="https://github.com/user-attachments/assets/2716baa7-c90c-4821-9fbd-fe56b8fe4162" />

* Visualización en el suscriptor del registro insertado en el publicador.
<img width="905" height="418" alt="image" src="https://github.com/user-attachments/assets/e1e2f3bf-c1ce-44a9-86eb-2573094a022f" />

