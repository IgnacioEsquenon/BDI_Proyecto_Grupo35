# Optimización de consultas a través de índices

# Conceptos Generales

Los índices son estructuras que facilitan el ordenamiento de los datos dentro de las tablas. Al ser objetos físicos, consumen espacio en disco, aunque en menor medida que las tablas mismas, dado que solo almacenan referencias a los datos clave utilizados para esa tabla, en lugar de guardar todos los datos. Es una copia de todas las filas, pero solamente de algunas columnas de la tabla sobre la cual definimos el índice.

# Elementos de los índices:

En SQL Server, los índices se organizan como árboles b.

- Páginas: Las páginas del árbol se llaman nodos del índice  
- Nodo Raíz: Es el nodo que se encuentra en el nivel superior del árbol  
- Nodo Hoja: Son los nodos que se encuentran en el nivel inferior  
- Nodos Intermedios: Son los nodos cuyo nivel está entre el superior e inferior

# Tipos de índices:

- Índice agrupado: Este tipo de índice lo que hace es ordenar de forma física los datos en la tabla según la columna que se indexa. Solo una tabla puede contener un índice agrupado. Es buena para buscar rangos o intervalos de una columna en especifico.  
- Índice no agrupado: En este tipo de índice se crea una estructura aparte para poder ordenar y buscar los datos, a diferencia del agrupado este no cambia el orden físico de los datos. Una tabla puede tener varios índices no agrupados.  
- Índice único: Este índice no permite valores duplicados en una columna previamente indexada, el valor de la columna debe ser único, bastante similar al uso de claves primarias.  
- Índice compuesto: Es un índice que utiliza dos o más columnas de una misma tabla. Resulta especialmente útil cuando se consulta por 2 columnas a la vez.  
- Índice columnar: Índice diseñado para manejar grandes cantidades de datos, este organiza los datos en columnas en lugar de filas lo que hace que sea más rápido analizar datos específicos de muchas filas.

