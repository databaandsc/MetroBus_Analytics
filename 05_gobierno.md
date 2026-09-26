# Gobierno del Dato: MetroBus Analytics

Este documento establece las reglas de negocio, el diccionario de datos y las decisiones de limpieza (Data Quality) tomadas durante la fase de análisis exploratorio (EDA) y carga, garantizando la trazabilidad y auditabilidad del pipeline para su pase a producción.

---

## 1. Diccionario de Datos

### Tablas de Dimensión (Niveles 1 y 2)

#### `dim_depot` (Cocheras)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `depot_id` | INT | Identificador único de la cochera. | Clave Primaria (PK) | Sin observaciones. |
| `nombre` | VARCHAR(100) | Nombre comercial de la cochera. | Texto no nulo | - |
| `barrio` | VARCHAR(100) | Distrito o barrio de ubicación. | Texto | Posibles diferencias de capitalización. |
| `latitud` | FLOAT | Coordenada GPS latitud. | [-90, 90] | - |
| `longitud` | FLOAT | Coordenada GPS longitud. | [-180, 180] | - |
| `capacidad_vehiculos` | INT | Número máximo de vehículos que puede albergar. | > 0 | - |

#### `dim_linea` (Líneas de servicio)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `linea_id` | INT | Identificador único de la línea. | Clave Primaria (PK) | Sin observaciones. |
| `codigo` | VARCHAR(50) | Código alfanumérico público (ej. L1, N1). | Texto único | - |
| `tipo` | VARCHAR(50) | Clasificación del servicio. | Urbana, Interurbana, Nocturna | - |
| `km_recorrido` | FLOAT | Distancia total de la ruta en km. | > 0 | - |
| `n_paradas` | INT | Cantidad de paradas en la ruta. | > 0 | - |
| `frecuencia_min` | INT | Tiempo programado entre autobuses (minutos). | > 0 | - |
| `origen` | VARCHAR(100) | Parada cabecera de inicio. | Texto | - |
| `destino` | VARCHAR(100) | Parada cabecera de fin. | Texto | Algunas rutas indican "Circular / Zona Única". |

#### `dim_parada` (Paradas)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `parada_id` | INT | Identificador único de la parada. | Clave Primaria (PK) | Sin observaciones. |
| `nombre_parada` | VARCHAR(100) | Nombre descriptivo público. | Texto | - |
| `barrio` | VARCHAR(100) | Barrio de ubicación. | Texto | - |
| `tipo` | VARCHAR(50) | Clasificación de la parada. | Intermedia, Cabecera, Intercambiador | - |
| `latitud` | FLOAT | Coordenada GPS latitud. | [-90, 90] | Faltan coordenadas en ciertas paradas ("Centro 11"). |
| `longitud` | FLOAT | Coordenada GPS longitud. | [-180, 180] | - |
| `accesible_silla` | BOOLEAN | Indica si es accesible para PMR. | TRUE, FALSE | - |
| `marquesina` | BOOLEAN | Indica si dispone de techo/marquesina. | TRUE, FALSE | - |
| `panel_informacion` | BOOLEAN | Indica si dispone de panel digital. | TRUE, FALSE | - |
| `activa` | BOOLEAN | Estado operativo actual. | TRUE, FALSE | - |

#### `dim_tarifa` (Tipos de billete)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `tarifa_id` | INT | Identificador único de la tarifa. | Clave Primaria (PK) | Sin observaciones. |
| `tipo_titulo` | VARCHAR(100) | Nombre del billete o bono. | Texto | - |
| `categoria` | VARCHAR(50) | Grupo demográfico objetivo. | Adulto, Joven, Jubilado, Social... | - |
| `precio_eur` | FLOAT | Coste en euros por viaje estimado. | >= 0.0 | - |
| `es_abono` | BOOLEAN | Indica si es un título multipersonal/temporal. | TRUE, FALSE | - |
| `bonificado` | BOOLEAN | Indica si tiene subvención pública. | TRUE, FALSE | - |

#### `dim_vehiculo` (Flota)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `vehiculo_id` | INT | Identificador interno del bus. | Clave Primaria (PK) | Sin observaciones. |
| `matricula` | VARCHAR(10) | Placa de matrícula oficial. | Formato placa | Algunos usan formato interno "XXXX BUS". |
| `modelo` | VARCHAR(50) | Marca y modelo comercial. | Texto | - |
| `combustible` | VARCHAR(50) | Tipo de propulsión. | Diesel, Electrico, Hibrido | Inconsistencia de formato (diesel vs Diesel). Nulos detectados. |
| `capacidad_sentados` | INT | Plazas sentadas. | > 0 | - |
| `capacidad_total` | INT | Plazas totales máximas. | >= capacidad_sentados | - |
| `anno_fabricacion` | INT | Año de construcción. | 1990 - Presente | Errores tipográficos (ej. 2099). |
| `anno_incorporacion` | INT | Año de entrada a la flota. | >= anno_fabricacion | - |
| `km_totales` | INT | Odómetro acumulado. | >= 0 | Presencia de valores negativos (ej. -500). |
| `depot_id` | INT | Cochera base asignada. | Clave Foránea (FK) | - |
| `emisiones_co2_gkm` | INT | Emisiones teóricas (g/km). | >= 0 | Eléctricos deberían ser 0. |
| `en_servicio` | BOOLEAN | Estado de alta en la flota. | TRUE, FALSE | - |

#### `dim_conductor` (Plantilla de conductores)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `conductor_id` | INT | ID de empleado. | Clave Primaria (PK) | Sin observaciones. |
| `nombre` | VARCHAR(100) | Nombre del empleado. | Texto | - |
| `apellidos` | VARCHAR(100) | Apellidos del empleado. | Texto | - |
| `anno_incorporacion` | INT | Año de contratación. | <= Año actual | - |
| `antiguedad_anos` | INT | Años en la empresa. | >= 0 | Debe coincidir con (Año Actual - incorporacion). |
| `depot_id` | INT | Cochera base asignada. | Clave Foránea (FK) | - |
| `activo` | BOOLEAN | Indica si sigue en plantilla. | TRUE, FALSE | - |
| `ausencias_2024` | INT | Días de ausencia en el año. | >= 0 | - |
| `turno` | VARCHAR(50) | Tipo de jornada. | Manana, Tarde, Noche, Partido | - |
| `horario` | VARCHAR(50) | Franja horaria típica. | HH:MM-HH:MM | Nulo en turnos partidos. |
| `formacion_nivel` | VARCHAR(100) | Nivel de formación interno. | Basica, Completa | Presencia de espacios extra ("Basica "). |
| `formacion_especialidad` | VARCHAR(100) | Especialidad técnica. | Articulado, Electrico... | - |
| `licencia_base` | VARCHAR(50) | Permiso de conducir. | D | - |
| `licencia_extra` | VARCHAR(50) | Complemento de permiso. | E, Sin Remolque | - |

### Tablas de Hechos (Nivel 3)

#### `fact_viajes` (Operativa diaria)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `viaje_id` | INT | Identificador único de viaje. | Clave Primaria (PK) | - |
| `linea_id` | INT | Línea operada. | FK | - |
| `vehiculo_id` | INT | Vehículo utilizado. | FK | - |
| `conductor_id` | INT | Conductor a cargo. | FK | - |
| `parada_origen_id` | INT | Parada real de inicio. | FK | - |
| `parada_destino_id` | INT | Parada real de fin. | FK | - |
| `fecha` | DATE | Fecha de operación. | Formato YYYY-MM-DD | - |
| `anno`, `mes`, `dia_semana` | INT / VARCHAR | Campos derivados de fecha. | Respectivos rangos temporales | - |
| `es_festivo` | BOOLEAN | Indica festividad. | TRUE, FALSE | - |
| `franja_horaria` | VARCHAR(50) | Agrupación comercial horaria. | Punta, Valle... | - |
| `hora_salida_prog`, `hora_salida_real`, `hora_llegada_real` | VARCHAR(20) | Tiempos de operación. | Formato HH:MM | - |
| `retraso_salida_min` | INT | Diferencia real vs programada. | Numérico | Puede ser negativo (adelanto). |
| `duracion_real_min` | INT | Tiempo total trayecto. | > 0 | - |
| `pasajeros_subidos` | FLOAT | Conteo de validaciones. | >= 0 | - |
| `ocupacion_pct` | FLOAT | % pasajeros sobre capacidad total. | [0.0, 1.0] | Valores anómalos > 1.0 por picos. |
| `km_programados`, `km_recorridos` | FLOAT | Distancia operativa. | >= 0.0 | - |
| `viaje_completado` | BOOLEAN | TRUE si llegó a destino. | TRUE, FALSE | - |
| `consumo` | FLOAT | Consumo energético estimado. | >= 0.0 | - |
| `tarifa_predominante_id` | INT | Tarifa más usada en el viaje. | FK | - |

#### `fact_mantenimiento` (Órdenes de trabajo)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `mantenimiento_id` | INT | Identificador orden de taller. | Clave Primaria (PK) | - |
| `vehiculo_id`, `depot_id` | INT | FKs asociadas. | FK | - |
| `fecha_entrada`, `fecha_salida` | DATE | Fechas de taller. | Salida >= Entrada | - |
| `anno`, `mes` | INT | Derivados de fecha entrada. | Numérico | - |
| `tipo_mantenimiento` | VARCHAR(100) | Tarea realizada. | Texto | - |
| `categoria` | VARCHAR(100) | Tipo general. | Preventivo, Correctivo | - |
| `es_correctivo` | BOOLEAN | TRUE si fue no planificado. | TRUE, FALSE | - |
| `dias_fuera_servicio` | INT | Tiempo parado. | >= 0 | - |
| `km_en_revision` | INT | Odómetro al entrar al taller. | >= 0 | - |
| `coste_eur` | FLOAT | Coste de la factura. | >= 0.0 | - |
| `proveedor` | VARCHAR(100) | Taller / Mecánico. | Texto | - |
| `garantia_meses` | INT | Periodo cubierto tras arreglo. | >= 0 | - |

#### `fact_incidencias` (Sucesos en ruta)
| Nombre de Campo | Tipo de Dato | Descripción | Valores Válidos / Rango | Observaciones de Calidad |
| :--- | :--- | :--- | :--- | :--- |
| `incidencia_id` | INT | ID del suceso. | Clave Primaria (PK) | - |
| `viaje_id`, `vehiculo_id`, `conductor_id`, `linea_id` | INT | Contexto de la incidencia. | FK | `viaje_id` puede ser nulo si pasó en base. |
| `fecha`, `anno`, `mes` | DATE / INT | Temporalidad. | - | - |
| `hora_incidencia` | VARCHAR(10) | Hora exacta del suceso. | HH:MM | - |
| `tipo_incidencia` | VARCHAR(100) | Descripción breve. | Texto | - |
| `categoria` | VARCHAR(50) | Clasificación de alto nivel. | Operacional, Vehiculo, Seguridad | - |
| `severidad` | VARCHAR(50) | Nivel de impacto. | Baja, Media, Alta, Crítica | - |
| `requiere_retirada` | BOOLEAN | Si el bus tuvo que volver a base. | TRUE, FALSE | - |
| `duracion_resolucion_min` | INT | Minutos hasta restaurar servicio. | >= 0 | - |
| `vehiculo_sustituto` | BOOLEAN | Si se mandó otra unidad. | TRUE, FALSE | - |
| `coste_estimado_eur` | FLOAT | Impacto económico de la incidencia. | >= 0.0 | Ceros en incidencias graves a imputar. |

---

## 2. Registro de Decisiones de Limpieza (Data Quality Log)

| Tabla | Campo | Tipo de Problema | Frecuencia (Est.) | Decisión Tomada | Justificación |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `dim_vehiculo` | `km_totales` | Valores negativos o ilógicos (ej. -500). | < 1% de la flota | Imputar valor absoluto o usar valor medio de vehículos del mismo año. | Un vehículo no puede tener un recorrido negativo físicamente. |
| `dim_vehiculo` | `anno_fabricacion` | Errores tipográficos / Valores futuros (ej. 2099). | ~ 1 a 3 filas | Reemplazar usando `anno_incorporacion` - 1 o imputar por el modelo de bus. | Corrige typos sin perder el resto del registro del bus operativo. |
| `dim_vehiculo` | `combustible` | Inconsistencia de formato (ej. "diesel" vs "Diesel") o valores nulos. | 5% de la flota | Normalizar a capitalización ("Diesel", "Electrico") e imputar nulos según modelo de bus. | Permite usar la columna de forma fiable para agrupaciones de emisiones. |
| `dim_conductor` | `formacion_nivel` | Espacios en blanco no deseados (ej. "Basica "). | > 50% de conductores | Aplicar función de limpieza `TRIM()` / `.str.strip()`. | Evita generar dos categorías distintas ("Basica" y "Basica ") en el dashboard. |
| `dim_parada` | `latitud` / `longitud` | Valores nulos (ej. parada "Centro 11"). | 1-2 filas | Imputar geolocalización aproximada usando centroide del barrio o dejar en mapa general. | Necesario para que el componente de mapa en BI no de errores al plotear rutas. |

| `fact_incidencias` | `coste_estimado_eur` | Ausencia de coste (0.0) en averías catalogadas como "Alta" o "Crítica". | ~ 5-10% incidencias | Imputar con la mediana del coste histórico para esa misma `categoria` y `severidad`. | Un coste 0 en incidencias graves distorsiona el cálculo del ROI de mantenimiento. |
| `dim_depot` | `barrio` | Variación en capitalización ("centro" vs "Centro"). | Múltiples registros | Normalizar todo a formato título `Title Case`. | Mantiene homogeneidad en los filtros cruzados con `dim_parada`. |

---

## 3. Definición Formal de KPIs (Métricas de Dashboard)

Las siguientes métricas son el corazón analítico del proyecto y deberán implementarse en la herramienta de visualización (PowerBI/Tableau/Superset) respetando esta semántica.

### 1. Índice de Disponibilidad de Flota (Uptime)
* **Descripción:** Porcentaje de días que los vehículos están disponibles para dar servicio en relación al total posible.
* **Fórmula Exacta:** `1 - (SUM(dias_fuera_servicio) / (COUNT(DISTINCT vehiculo_id) * Días del Periodo Analizado))`
* **Fuente de Datos:** `fact_mantenimiento` (`dias_fuera_servicio`), `dim_vehiculo` (`vehiculo_id`).
* **Criterios de exclusión:** Vehículos donde `en_servicio = FALSE` (dados de baja).
* **Responsable de Validación:** Director de Operaciones / Jefe de Taller.

### 2. Coste Medio de Incidencia Crítica
* **Descripción:** Gasto promedio provocado por incidencias graves que alteran la operación normal.
* **Fórmula Exacta:** `SUM(coste_estimado_eur) / COUNT(incidencia_id)`
* **Fuente de Datos:** `fact_incidencias` (`coste_estimado_eur`).
* **Criterios de exclusión:** Filtrar solo donde `severidad IN ('Alta', 'Crítica')`.
* **Responsable de Validación:** Dirección Financiera.

### 3. Tasa de Incidencias de Seguridad por 10K km (Safety Ratio)
* **Descripción:** Frecuencia con la que un conductor o línea sufre un percance de seguridad ponderado por su kilometraje.
* **Fórmula Exacta:** `(COUNT(incidencia_id) / SUM(km_recorridos)) * 10000`
* **Fuente de Datos:** `fact_incidencias` (Conteo donde `categoria = 'Seguridad'`), `fact_viajes` (`km_recorridos`).
* **Criterios de exclusión:** Solo contar viajes con kilometraje > 0.
* **Responsable de Validación:** Departamento de RRHH / Seguridad Vial.

### 4. Eco-Eficiencia: Emisiones de CO2 Totales
* **Descripción:** Toneladas de dióxido de carbono emitidas por la flota en un periodo determinado.
* **Fórmula Exacta:** `SUM(km_recorridos * emisiones_co2_gkm) / 1000000`
* **Fuente de Datos:** `fact_viajes` (`km_recorridos`), `dim_vehiculo` (`emisiones_co2_gkm`).
* **Criterios de exclusión:** Ninguno (incluye desplazamientos en vacío si se registran).
* **Responsable de Validación:** Director de Sostenibilidad.

### 5. Retraso Medio en Salida
* **Descripción:** Medición de puntualidad en origen respecto a la hora programada.
* **Fórmula Exacta:** `AVG(retraso_salida_min)`
* **Fuente de Datos:** `fact_viajes` (`retraso_salida_min`).
* **Criterios de exclusión:** Solo considerar donde `retraso_salida_min > 0` (ignorar adelantos) si se quiere penalizar solo el retraso puro, o todos los registros si se evalúa la desviación total.
* **Responsable de Validación:** Gerente de Servicio / Planificación.

### 6. Ocupación Media Ponderada
* **Descripción:** Porcentaje medio de llenado de los autobuses, crucial para entender la rentabilidad y capacidad de cada línea.
* **Fórmula Exacta:** `AVG(ocupacion_pct)` *O bien* `SUM(pasajeros_subidos) / SUM(capacidad_total de todos los viajes)`
* **Fuente de Datos:** `fact_viajes` (`ocupacion_pct`, `pasajeros_subidos`), `dim_vehiculo` (`capacidad_total`).
* **Criterios de exclusión:** Excluir viajes donde `viaje_completado = FALSE` (viajes cancelados o interrumpidos).
* **Responsable de Validación:** Planificación de Rutas / Negocio.
