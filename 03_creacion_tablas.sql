-- ==============================================================================
-- CREACIÓN DE LA BASE DE DATOS
-- ==============================================================================

-- 1. Borramos tablas de Hechos si existieran
DROP TABLE IF EXISTS fact_incidencias CASCADE;
DROP TABLE IF EXISTS fact_mantenimiento CASCADE;
DROP TABLE IF EXISTS fact_viajes CASCADE;

-- 2. Borramos tablas de Dimensiones si existieran
DROP TABLE IF EXISTS dim_vehiculo CASCADE;
DROP TABLE IF EXISTS dim_conductor CASCADE;
DROP TABLE IF EXISTS dim_tarifa CASCADE;
DROP TABLE IF EXISTS dim_parada CASCADE;
DROP TABLE IF EXISTS dim_linea CASCADE;
DROP TABLE IF EXISTS dim_depot CASCADE;


-- ==============================================================================
-- NIVEL 1: DIMENSIONES INDEPENDIENTES
-- ==============================================================================

-- Tabla de dimensiones cocheras
CREATE TABLE dim_depot (
    depot_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    barrio VARCHAR(100),
    latitud FLOAT,
    longitud FLOAT,
    capacidad_vehiculos INT
);

-- Tabla de dimensiones lineas
CREATE TABLE dim_linea (
    linea_id INT PRIMARY KEY,
    codigo VARCHAR(50),
    tipo VARCHAR(50),
    km_recorrido FLOAT,
    n_paradas INT,
    frecuencia_min INT,
    origen VARCHAR(100),
    destino VARCHAR(100)
);

-- Tabla de dimensiones paradas
CREATE TABLE dim_parada (
    parada_id INT PRIMARY KEY,
    nombre_parada VARCHAR(100),
    barrio VARCHAR(100),
    tipo VARCHAR(50),
    latitud FLOAT,
    longitud FLOAT,
    accesible_silla BOOLEAN,
    marquesina BOOLEAN,
    panel_informacion BOOLEAN,
    activa BOOLEAN
);

-- Tabla de dimensiones tarifas
CREATE TABLE dim_tarifa (
    tarifa_id INT PRIMARY KEY,
    tipo_titulo VARCHAR(100),
    categoria VARCHAR(50),
    precio_eur FLOAT,
    es_abono BOOLEAN,
    bonificado BOOLEAN
);


-- ==============================================================================
-- NIVEL 2: DIMENSIONES DEPENDIENTES
-- ==============================================================================

-- Tabla de dimensiones vehículos
CREATE TABLE dim_vehiculo(
    vehiculo_id INT PRIMARY KEY,
    matricula VARCHAR(10),
    marca VARCHAR(50),
    modelo VARCHAR(50),
    combustible VARCHAR(50),
    capacidad_sentados INT,
    capacidad_total INT,
    anno_fabricacion INT,
    anno_incorporacion INT,
    km_totales INT,
    depot_id INT,
    emisiones_co2_gkm INT,
    en_servicio BOOLEAN,
    FOREIGN KEY (depot_id) REFERENCES dim_depot(depot_id)
);

-- Tabla de dimensiones conductores
CREATE TABLE dim_conductor (
    conductor_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    apellidos VARCHAR(100),
    anno_incorporacion INT,
    antiguedad_anos INT,
    depot_id INT,
    activo BOOLEAN,
    ausencias_2024 INT,
    turno VARCHAR(50),
    horario VARCHAR(50),
    formacion_nivel VARCHAR(100),
    formacion_especialidad VARCHAR(100),
    licencia_base VARCHAR(50),
    licencia_extra VARCHAR(50),
    FOREIGN KEY (depot_id) REFERENCES dim_depot(depot_id)
);


-- ==============================================================================
-- NIVEL 3: TABLAS DE HECHOS
-- ==============================================================================

-- Tabla de hechos viajes
CREATE TABLE fact_viajes (
    viaje_id INT PRIMARY KEY,
    linea_id INT,
    vehiculo_id INT,
    conductor_id INT,
    parada_origen_id INT,
    parada_destino_id INT,
    fecha DATE,
    anno INT,
    mes INT,
    dia_semana VARCHAR(50),
    es_festivo BOOLEAN,
    franja_horaria VARCHAR(50),
    hora_salida_prog VARCHAR(20),
    hora_salida_real VARCHAR(20),
    hora_llegada_real VARCHAR(20),
    retraso_salida_min INT,
    duracion_real_min INT,
    pasajeros_subidos FLOAT,
    ocupacion_pct FLOAT,
    km_programados FLOAT,
    km_recorridos FLOAT,
    viaje_completado BOOLEAN,
    consumo FLOAT,
    tarifa_predominante_id INT,
    estado_vehiculo VARCHAR(50),
    
    -- Relaciones con las dimensiones (Foreign Keys)
    FOREIGN KEY (linea_id) REFERENCES dim_linea(linea_id),
    FOREIGN KEY (vehiculo_id) REFERENCES dim_vehiculo(vehiculo_id),
    FOREIGN KEY (conductor_id) REFERENCES dim_conductor(conductor_id),
    FOREIGN KEY (parada_origen_id) REFERENCES dim_parada(parada_id),
    FOREIGN KEY (parada_destino_id) REFERENCES dim_parada(parada_id),
    FOREIGN KEY (tarifa_predominante_id) REFERENCES dim_tarifa(tarifa_id)
);

-- Tabla de hechos mantenimiento
CREATE TABLE fact_mantenimiento (
    mantenimiento_id INT PRIMARY KEY,
    vehiculo_id INT,
    depot_id INT,
    fecha_entrada DATE,
    fecha_salida DATE,
    anno INT,
    mes INT,
    tipo_mantenimiento VARCHAR(100),
    categoria VARCHAR(100),
    es_correctivo BOOLEAN,
    dias_fuera_servicio INT,
    km_en_revision INT,
    coste_eur FLOAT,
    proveedor VARCHAR(100),
    garantia_meses INT,
    
    -- Relaciones con las dimensiones (Foreign Keys)
    FOREIGN KEY (vehiculo_id) REFERENCES dim_vehiculo(vehiculo_id),
    FOREIGN KEY (depot_id) REFERENCES dim_depot(depot_id)
);

-- Tabla de hechos incidencias
CREATE TABLE fact_incidencias (
    incidencia_id INT PRIMARY KEY,
    viaje_id INT,
    vehiculo_id INT,
    conductor_id INT,
    linea_id INT,
    fecha DATE,
    anno INT,
    mes INT,
    hora_incidencia VARCHAR(10),
    tipo_incidencia VARCHAR(100),
    categoria VARCHAR(50),
    severidad VARCHAR(50),
    requiere_retirada BOOLEAN,
    duracion_resolucion_min INT,
    vehiculo_sustituto BOOLEAN,
    coste_estimado_eur FLOAT,
    FOREIGN KEY (viaje_id) REFERENCES fact_viajes(viaje_id),
    FOREIGN KEY (vehiculo_id) REFERENCES dim_vehiculo(vehiculo_id),
    FOREIGN KEY (conductor_id) REFERENCES dim_conductor(conductor_id),
    FOREIGN KEY (linea_id) REFERENCES dim_linea(linea_id)
);

