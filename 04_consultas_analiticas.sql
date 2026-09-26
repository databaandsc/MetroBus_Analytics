-- ==============================================================================
-- CONSULTAS DE ANÁLISIS Y KPIs
-- ==============================================================================

-- ==============================================================================
--Mantenimiento y Fiabilidad de la Flota
-- ==============================================================================

-- 1. ¿Cuáles son los 3 modelos de vehículos que generan los mayores costes acumulados por incidencias y mantenimientos,
-- y cuántas horas de servicio se han perdido por su culpa?

SELECT 
    v.modelo,
    ROUND(SUM(i.coste_estimado_eur)) AS coste_total_incidencias,
    SUM(i.duracion_resolucion_min) / 60 AS horas_perdidas
FROM dim_vehiculo v
JOIN fact_incidencias i ON v.vehiculo_id = i.vehiculo_id
GROUP BY v.modelo
ORDER BY coste_total_incidencias DESC
LIMIT 10;

-- 2. ¿Existe una correlación entre los vehículos que han pasado menos mantenimientos preventivos este año
-- y los que han sufrido averías de severidad "Alta" o "Crítica" en ruta?

-- 1. Primer resumen: Contamos los mantenimientos preventivos por vehículo
WITH ResumenMantenimiento AS (
    SELECT 
        vehiculo_id, 
        COUNT(*) AS total_preventivos
    FROM fact_mantenimiento
    WHERE es_correctivo = FALSE 
    GROUP BY vehiculo_id
),

-- 2. Segundo resumen: Contamos las averías graves por vehículo
ResumenIncidencias AS (
    SELECT 
        vehiculo_id, 
        COUNT(*) AS averias_graves
    FROM fact_incidencias
    WHERE severidad IN ('Alta', 'Crítica') 
    GROUP BY vehiculo_id
)

-- 3. Consulta final: Juntamos todo con el catálogo de vehículos
SELECT 
    v.modelo,
    COALESCE(m.total_preventivos, 0) AS mantenimientos_preventivos,
    COALESCE(i.averias_graves, 0) AS averias_graves_en_ruta
FROM dim_vehiculo v
LEFT JOIN ResumenMantenimiento m ON v.vehiculo_id = m.vehiculo_id
LEFT JOIN ResumenIncidencias i ON v.vehiculo_id = i.vehiculo_id
ORDER BY mantenimientos_preventivos ASC, averias_graves_en_ruta DESC;

-- ==============================================================================
--Rendimiento y Seguridad de Conductores
-- ==============================================================================

-- 3. ¿Qué conductores tienen el mayor ratio de "Incidencias de Seguridad" por cada 10.000 kilómetros recorridos?

-- 1. Primer resumen: Sumamos los kilómetros totales que ha conducido cada conductor
WITH KilometrosConductor AS (
    SELECT 
        conductor_id, 
        SUM(km_recorridos) AS total_km
    FROM fact_viajes
    GROUP BY conductor_id
    HAVING SUM(km_recorridos) > 0 
),

-- 2. Segundo resumen: Contamos las incidencias de la categoría 'Seguridad'
IncidenciasSeguridad AS (
    SELECT 
        conductor_id, 
        COUNT(*) AS total_incidencias
    FROM fact_incidencias
    WHERE categoria = 'Seguridad'
    GROUP BY conductor_id
)

-- 3. Mezclamos todo con el catálogo de conductores y hacemos las matemáticas
SELECT 
    c.nombre || ' ' || c.apellidos AS nombre_completo,
    COALESCE(i.total_incidencias, 0) AS total_incidencias_seguridad,
    ROUND(k.total_km::numeric, 2) AS kms_recorridos,
    -- Ccalculamos el ratio: (Incidencias / Kilómetros) * 10.000
    ROUND(((COALESCE(i.total_incidencias, 0) / k.total_km) * 10000)::numeric, 2) AS ratio_por_10k_km
FROM dim_conductor c
JOIN KilometrosConductor k ON c.conductor_id = k.conductor_id
LEFT JOIN IncidenciasSeguridad i ON c.conductor_id = i.conductor_id
ORDER BY ratio_por_10k_km DESC
LIMIT 5;


-- 4.Comparando los años de incorporación de los conductores,
-- ¿tienen los conductores más novatos una mayor tasa de incidencias que requieren vehículo sustituto respecto a los veteranos?
SELECT 
    c.antiguedad_anos,
    COUNT(i.incidencia_id) AS incidencias_con_sustituto
FROM dim_conductor c
JOIN fact_incidencias i ON c.conductor_id = i.conductor_id
WHERE i.vehiculo_sustituto = TRUE
GROUP BY c.antiguedad_anos
ORDER BY c.antiguedad_anos ASC;

-- ==============================================================================
--Sostenibilidad y Medio Ambiente (Eco-Eficiencia)
-- ==============================================================================

-- 5.Utilizando la columna emisiones_co2_gkm que arreglaste, ¿cuáles son las 5 líneas (rutas) más contaminantes en total, combinando la longitud del viaje y el tipo de vehículos asignados a ellas?
SELECT 
    l.codigo,
    ROUND(SUM(v.km_recorridos * dv.emisiones_co2_gkm / 1000000)::numeric, 2) AS toneladas_co2_totales
FROM fact_viajes v
JOIN dim_linea l ON v.linea_id = l.linea_id
JOIN dim_vehiculo dv ON v.vehiculo_id = dv.vehiculo_id
GROUP BY l.codigo
ORDER BY toneladas_co2_totales DESC
LIMIT 5;

-- 6. Si retiráramos de circulación el 10% de los vehículos más antiguos de cada depot, ¿cuál sería la reducción porcentual estimada de emisiones totales de CO2?
WITH EmisionesPorVehiculo AS (
    SELECT 
        v.vehiculo_id,
        dv.depot_id,
        dv.anno_fabricacion,
        SUM(v.km_recorridos * dv.emisiones_co2_gkm) AS emisiones_totales,
        -- Calculamos el percentil de antigüedad por cada cochera
        PERCENT_RANK() OVER(PARTITION BY dv.depot_id ORDER BY dv.anno_fabricacion ASC) as percentil_antiguedad
    FROM fact_viajes v
    JOIN dim_vehiculo dv ON v.vehiculo_id = dv.vehiculo_id
    GROUP BY v.vehiculo_id, dv.depot_id, dv.anno_fabricacion
),
CalculoReduccion AS (
    SELECT 
        SUM(emisiones_totales) AS emisiones_actuales,
        -- Si está en el 10% más viejo (<= 0.10), sumamos sus emisiones como "ahorro"
        SUM(CASE WHEN percentil_antiguedad <= 0.10 THEN emisiones_totales ELSE 0 END) AS emisiones_reducidas
    FROM EmisionesPorVehiculo
)
SELECT 
    ROUND((emisiones_reducidas / emisiones_actuales * 100)::numeric, 2) AS porcentaje_reduccion_co2
FROM CalculoReduccion;
-- ==============================================================================
-- Operaciones y Rentabilidad
-- ==============================================================================

--7 . ¿Cuál ha sido la pérdida económica total estimada
-- (sumando el coste de la incidencia y la necesidad de vehículos sustitutos) agrupada por línea y mes durante el último año?
SELECT 
    l.codigo,
    i.anno,
    i.mes,
    ROUND(SUM(i.coste_estimado_eur)::numeric, 2) AS perdida_total_eur
FROM fact_incidencias i
JOIN dim_linea l ON i.linea_id = l.linea_id
GROUP BY l.codigo, i.anno, i.mes
ORDER BY i.anno DESC, i.mes DESC, perdida_total_eur DESC;

-- 8. ¿Qué depot tiene el mejor tiempo medio de resolución de incidencias,
-- y cómo se compara esto con el volumen total de viajes que gestionan al mes?
WITH TiemposDepot AS (
    SELECT 
        d.nombre,
        ROUND(AVG(i.duracion_resolucion_min)::numeric, 1) AS tiempo_medio_resolucion_min
    FROM fact_incidencias i
    JOIN dim_vehiculo v ON i.vehiculo_id = v.vehiculo_id
    JOIN dim_depot d ON v.depot_id = d.depot_id
    GROUP BY d.nombre
),
ViajesDepot AS (
    SELECT 
        d.nombre,
        COUNT(v.viaje_id) AS total_viajes
    FROM fact_viajes v
    JOIN dim_vehiculo dv ON v.vehiculo_id = dv.vehiculo_id
    JOIN dim_depot d ON dv.depot_id = d.depot_id
    GROUP BY d.nombre
)
SELECT 
    t.nombre,
    t.tiempo_medio_resolucion_min,
    v.total_viajes
FROM TiemposDepot t
JOIN ViajesDepot v ON t.nombre = v.nombre
ORDER BY t.tiempo_medio_resolucion_min ASC;

--9. Queremos un ranking mensual de las líneas más problemáticas según el coste total de sus incidencias,
--indicando además qué porcentaje de ese coste representó sobre el total de toda la empresa en ese mes.

-- Primer resumen: Agrupamos y sumamos los costes por Mes y Línea
WITH CostesMensualesPorLinea AS (
    SELECT 
        i.mes,
        i.anno,
        l.codigo,
        COUNT(i.incidencia_id) AS total_incidencias,
        SUM(i.coste_estimado_eur) AS coste_linea,
        SUM(i.duracion_resolucion_min) AS minutos_perdidos
    FROM fact_incidencias i
    JOIN dim_linea l ON i.linea_id = l.linea_id
    GROUP BY i.mes, i.anno, l.codigo
),

-- Segundo resumen: Calculamos el coste total de todas las líneas juntas por mes
CostesTotalesEmpresa AS (
    SELECT 
        mes,
        anno,
        SUM(coste_linea) AS coste_total_empresa
    FROM CostesMensualesPorLinea
    GROUP BY mes, anno
)

-- Consulta Final: Unimos ambos resúmenes y aplicamos Window Functions para el ranking
SELECT 
    c.anno,
    c.mes,
    c.codigo,
    c.total_incidencias,
    c.coste_linea,
    -- Calculamos el porcentaje que supone esta línea sobre el gasto total del mes
    ROUND(((c.coste_linea / t.coste_total_empresa) * 100)::numeric, 2) AS porcentaje_gasto_mes,
    -- Función de ventana: Clasificamos las líneas de mayor a menor coste dentro de cada mes
    RANK() OVER(PARTITION BY c.anno, c.mes ORDER BY c.coste_linea DESC) AS ranking_problematico
FROM CostesMensualesPorLinea c
JOIN CostesTotalesEmpresa t ON c.mes = t.mes AND c.anno = t.anno
-- Filtramos por ejemplo para ver solo el 'Top 3' de líneas más caras de cada mes
WHERE c.coste_linea > 0
ORDER BY c.anno DESC, c.mes DESC, ranking_problematico ASC;