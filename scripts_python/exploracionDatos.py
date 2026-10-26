import pandas as pd

# Cargamos el dataset preprocesado y limpio
df = pd.read_csv("airbnb_centroamerica_master.csv", low_memory=False)
print("🔍 Dataset cargado. Iniciando batería de consultas de exploración...")

# =====================================================================
# EJERCICIO 1: Top 5 de Alojamientos Más Caros de crentroamerica
# Muestra cómo ordenar datos y seleccionar columnas específicas para visualización rápida.
# =====================================================================
print("\n📌 1. TOP 5 ALOJAMIENTOS MÁS CAROS EN centroamerica:")
columnas_vista = ['name', 'region_origen', 'price', 'room_type']
top_caros = df.sort_values(by='price', ascending=False)[columnas_vista].head(5)
print(top_caros.to_string(index=False))


# =====================================================================
# EJERCICIO 2: Precio Promedio y Total de Alojamientos por Región
# Enseña el uso fundamental de .groupby() y la agregación de múltiples métricas.
# =====================================================================
print("\n📌 2. RESUMEN DEL MERCADO POR REGIÓN (Precio Promedio y Volumen):")
# 1. Elimina espacios en blanco y caracteres no numéricos si los hubiera (ej: $, €, comas)
df['price'] = df['price'].astype(str).str.replace('$', '', regex=False).str.replace(',', '', regex=False).str.strip()

# 2. Convierte la columna a tipo numérico (los valores no válidos se convertirán en NaN)
df['price'] = pd.to_numeric(df['price'], errors='coerce')
resumen_region = df.groupby('region_origen').agg(
    precio_promedio=('price', 'mean'),
    total_alojamientos=('id', 'count')
).sort_values(by='precio_promedio', ascending=False)

# Formateamos el precio a dos decimales para una lectura limpia
resumen_region['precio_promedio'] = resumen_region['precio_promedio'].round(2)
print(resumen_region)


# =====================================================================
# EJERCICIO 3: El Efecto "Superhost"
# Filtrado analítico para comprobar si los Superhosts cobran más o tienen mejores notas.
# =====================================================================
print("\n📌 3. COMPARATIVA: ¿SER SUPERHOST MARCA LA DIFERENCIA?")
# Filtramos solo los que tienen reseñas válidas (puntuación > 0)
df_con_resenas = df[df['review_scores_rating'] > 0]

efecto_superhost = df_con_resenas.groupby('host_is_superhost').agg(
    precio_medio=('price', 'mean'),
    puntuacion_media=('review_scores_rating', 'mean'),
    total_propiedades=('id', 'count')
).round(2)
print(efecto_superhost)


# =====================================================================
# EJERCICIO 4: Filtrado Avanzado Multicriterio (Oportunidades de Inversión)
# Simula una petición real de un inversor: "Busco apartamentos enteros en Madrid, 
# económicos (<80€), con buena puntuación y capacidad para mínimo 4 personas".
# =====================================================================
print("\n📌 4. BÚSQUEDA DE OPORTUNIDADES (Filtro Cruzado Complejo):")
filtros = (
    (df['region_origen'] == 'Madrid') & 
    (df['room_type'] == 'Entire home/apt') & 
    (df['price'] < 80) & 
    (df['accommodates'] >= 4) & 
    (df['review_scores_rating'] >= 4.5)
)

#filtros = (
#    (df['region_origen'] == 'Madrid') & 
#    (df['room_type'] == 'Entire home/apt') & 
#    (df['price'] < 80) & 
#    (df['accommodates'] >= 4) & 
#    (df['review_scores_rating'] >= 4.5)
#)

oportunidades = df[filtros][['name', 'neighbourhood_cleansed', 'price', 'review_scores_rating']]
print(f"🎯 Se han encontrado {len(oportunidades)} opciones que cumplen los requisitos del inversor.")
print(oportunidades.head(5).to_string(index=False))  # Mostramos solo las primeras 5 para no saturar la pantalla


# =====================================================================
# EJERCICIO 5: Distribución del Tipo de Alojamiento por Región (Matriz de Contingencia)
# Muestra cómo cruzar dos variables categóricas usando crosstab, ideal antes de graficar barras apiladas.
# =====================================================================
print("\n📌 5. MATRIZ DE DISTRIBUCIÓN: TIPO DE ALOJAMIENTO POR REGIÓN:")
matriz_tipos = pd.crosstab(df['region_origen'], df['room_type'])
print(matriz_tipos)