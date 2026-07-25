MetroBus Analytics - Proyecto Final
Autor: Ricardo Fernández Chamorro

Este repositorio contiene el pipeline completo de datos para el análisis operativo y financiero de la flota de MetroBus, cubriendo desde la limpieza de datos crudos hasta la visualización ejecutiva.

1. Stack Tecnológico:

Lenguaje: Python 3.14.2

Librerías principales: pandas, psycopg2 / SQLAlchemy (conexión a base de datos), numpy.

Base de Datos: PostgreSQL.

Herramienta de Business Intelligence: Tableau Desktop.

2. Cómo ejecutar el proyecto:

Para reproducir este análisis desde cero en una máquina local, sigue estos pasos en estricto orden:

- Exploración y limpieza: Abre el archivo 01_eda.ipynb en Jupyter Notebook y ejecuta todas las celdas (Run All). Esto procesará los archivos CSV crudos de la carpeta /data.

- Creación del esquema: En tu gestor de PostgreSQL (ej. pgAdmin), ejecuta la primera parte del script 03_sql.sql (sección DDL) para crear la base de datos y las tablas vacías del modelo en estrella.

- Inyección de datos: Abre el archivo 02_carga_datos.ipynb y ejecútalo (Run All). Durante la ejecución, el script te solicitará por pantalla que introduzcas la contraseña de tu instancia local de PostgreSQL para establecer la conexión y poblar las tablas.

- Consultas de negocio: Vuelve al archivo 03_sql.sql y ejecuta las consultas analíticas (sección DML) para validar la integridad de la base de datos.

- Visualización: Abre el archivo 05_Dashboard.twbx para interactuar con los cuadros de mando, y la presentación en Power Point en el archivo: 06_Presentacion.pdf.

3. Decisiones no obvias:

Para este proyecto, se tomó la decisión técnica de separar el pipeline de Python en dos notebooks independientes (01_eda.ipynb para la limpieza y exploración, y 02_carga_datos.ipynb exclusivo para la inyección) en lugar de unificarlo todo en el archivo de EDA que pedía el enunciado inicial. Esta decisión se basa en el principio de separación de responsabilidades: permite iterar, analizar y documentar los datos crudos de forma segura, sin el riesgo de ejecutar accidentalmente múltiples veces las sentencias de inserción en la base de datos PostgreSQL, protegiendo así la integridad del modelo en estrella durante la fase de desarrollo.

4. El hallazgo más importante:

El altísimo coste de las reparaciones correctivas de la flota no se debe al desgaste mecánico propio de los autobuses, sino a una altísima tasa de siniestralidad y eventos de seguridad externos en la calle. Estos incidentes imprevistos, que sufren picos extremos en abril y diciembre, obligan a inyectar miles de euros en reparaciones de urgencia, superando y desequilibrando por completo la inversión en el mantenimiento preventivo.

