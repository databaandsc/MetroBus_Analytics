# MetroBus Analytics - Proyecto Final
**Autor:** Ricardo Fernández Chamorro

Este repositorio contiene el pipeline completo de datos para el análisis operativo y financiero de la flota de MetroBus. El proyecto cubre el ciclo de vida íntegro de los datos: desde la limpieza de datos crudos (ETL), el diseño de un modelo en estrella, hasta la orquestación en base de datos y la visualización ejecutiva.

## Stack Tecnológico
* **Lenguaje:** Python 3.14.2
* **Librerías principales:** pandas (limpieza y EDA), psycopg2 / SQLAlchemy (conexión y orquestación) y numpy.
* **Base de Datos:** PostgreSQL.
* **Business Intelligence:** Tableau Desktop.

---

## Cómo ejecutar el proyecto (Pipeline Reproducible)
Para reproducir este análisis desde cero en una máquina local y testear la arquitectura de datos, sigue estos pasos en estricto orden:

1. **Exploración y limpieza (EDA):** Abre el archivo `01_eda.ipynb` en Jupyter Notebook y ejecuta todas las celdas (Run All). Este paso procesará los archivos CSV crudos de la carpeta `data/raw/`, imputará valores nulos, aplicará filtros estrictos de integridad referencial y exportará los datos completamente limpios a la carpeta principal `data/`.
2. **Inyección de datos y creación del esquema:** Abre el archivo `02_carga_datos.ipynb` y ejecútalo (Run All). Este script actúa como un orquestador automático: primero ejecuta por debajo el script `03_creacion_tablas.sql` para regenerar la base de datos vacía (asegurando la idempotencia) y, acto seguido, puebla las tablas de PostgreSQL.
   > **IMPORTANTE:** Una vez ejecutado el script, te pedirá por pantalla que introduzcas una clave para poder inyectar los datos en PostgreSQL. **ESTA CLAVE ES LA PROPIA CONTRASEÑA QUE TENGAS ASOCIADA EN TU INSTANCIA LOCAL DE PGADMIN.**
3. **Consultas de negocio (SQL):** Abre en tu cliente SQL (ej. pgAdmin) el script `04_consultas_analiticas.sql`, conéctate a la base de datos `metrobus_db` y ejecútalo para extraer los KPIs estratégicos mediante Window Functions y agregaciones.
4. **Visualización:** Abre el archivo `06_Dashboard.twbx` para interactuar con los cuadros de mando y consulta la presentación ejecutiva en `07_Presentación.pptx`.

---

## Decisiones de Arquitectura e Ingeniería de Datos
Para garantizar un pipeline robusto, se tomaron las siguientes decisiones de diseño:

* **Separación de Responsabilidades:** Se dividió el código de Python en dos libretas (`01_eda` y `02_carga_datos`). Esto permite iterar y documentar los datos crudos de forma segura sin riesgo de ejecutar accidentalmente inserciones masivas en PostgreSQL durante el desarrollo.
* **Idempotencia del Pipeline:** Se automatizó la ejecución del DDL SQL (`03_creacion_tablas.sql`) desde dentro de Python. De este modo, el script de inyección se puede ejecutar infinitas veces sin provocar errores de duplicidad de claves (UniqueViolation), regenerando el modelo desde cero.
* **Garantía de Integridad Referencial:** Durante el EDA, la eliminación de outliers en los viajes generaba registros huérfanos en la tabla de incidencias, lo que rompía las Foreign Keys en PostgreSQL. Se implementó un filtrado dinámico en Python que purga en cascada cualquier incidencia cuyo viaje haya sido eliminado, asegurando una cohesión perfecta del Modelo en Estrella.

---

## El hallazgo de negocio más importante
Tras cruzar y modelar los datos, se descubrió que el altísimo coste de las reparaciones correctivas de la flota no se debe al desgaste mecánico propio de los autobuses, sino a una altísima tasa de siniestralidad y eventos de seguridad en ruta. Estos incidentes imprevistos, que sufren picos extremos en abril y diciembre, obligan a inyectar miles de euros en reparaciones de urgencia, desequilibrando por completo el presupuesto frente a la inversión en mantenimiento preventivo.

***
*Nota: Los Markdown y parte de la redacción técnica de la documentación del proyecto han sido realizados con el soporte de asistentes de Inteligencia Artificial.*

