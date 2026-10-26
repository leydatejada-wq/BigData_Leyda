r

# ============================================================
# EXPLORACIÓN Y ANÁLISIS DE DATOS - AIRBNB CENTROAMÉRICA
# ============================================================

# 1. CARGAR LIBRERÍAS
# Instala las librerías si todavía no las tienes:
# install.packages(c("dplyr", "readr", "tidyr"))

library(dplyr)
library(readr)
library(tidyr)

# 2. CARGAR DATASET PREPROCESADO
df <- read_csv(
  "airbnb_centroamerica_clean.csv",
  show_col_types = FALSE
)

cat("🔍 Dataset cargado. Iniciando batería de consultas de exploración...\n")


# ============================================================
# EJERCICIO 1: TOP 5 ALOJAMIENTOS MÁS CAROS DE CENTROAMÉRICA
# ============================================================

cat("\n📌 1. TOP 5 ALOJAMIENTOS MÁS CAROS EN CENTROAMÉRICA:\n")

columnas_vista <- c(
  "name",
  "region_origen",
  "price",
  "room_type"
)

top_caros <- df %>%
  arrange(desc(price)) %>%
  select(all_of(columnas_vista)) %>%
  slice_head(n = 5)

print(top_caros, n = 5, width = Inf)


# ============================================================
# EJERCICIO 2: PRECIO PROMEDIO Y TOTAL DE ALOJAMIENTOS POR REGIÓN
# ============================================================

cat("\n📌 2. RESUMEN DEL MERCADO POR REGIÓN:\n")

resumen_region <- df %>%
  group_by(region_origen) %>%
  summarise(
    precio_promedio = round(mean(price, na.rm = TRUE), 2),
    total_alojamientos = sum(!is.na(id)),
    .groups = "drop"
  ) %>%
  arrange(desc(precio_promedio))

print(resumen_region, n = Inf, width = Inf)


# ============================================================
# EJERCICIO 3: EL EFECTO SUPERHOST
# ============================================================

cat("\n📌 3. COMPARATIVA: ¿SER SUPERHOST MARCA LA DIFERENCIA?\n")

# Filtramos los alojamientos con puntuaciones válidas (> 0).

df_con_resenas <- df %>%
  filter(
    !is.na(review_scores_rating),
    review_scores_rating > 0
  )

efecto_superhost <- df_con_resenas %>%
  group_by(host_is_superhost) %>%
  summarise(
    precio_medio = mean(price, na.rm = TRUE),
    puntuacion_media = mean(review_scores_rating, na.rm = TRUE),
    total_propiedades = sum(!is.na(id)),
    .groups = "drop"
  ) %>%
  mutate(
    across(
      c(precio_medio, puntuacion_media),
      ~ round(.x, 2)
    )
  )

print(efecto_superhost, n = Inf, width = Inf)


# ============================================================
# EJERCICIO 4: FILTRADO AVANZADO MULTICRITERIO
# OPORTUNIDADES DE INVERSIÓN
# ============================================================

cat("\n📌 4. BÚSQUEDA DE OPORTUNIDADES DE INVERSIÓN:\n")

# Criterios:
# - Región: Madrid
# - Tipo: vivienda o apartamento entero
# - Precio inferior a 80
# - Capacidad mínima para 4 personas
# - Puntuación mínima de 4.5

oportunidades <- df %>%
  filter(
    region_origen == "Madrid",
    room_type == "Entire home/apt",
    price < 80,
    accommodates >= 4,
    review_scores_rating >= 4.5
  ) %>%
  select(
    name,
    neighbourhood_cleansed,
    price,
    review_scores_rating
  )

cat(
  "🎯 Se han encontrado",
  nrow(oportunidades),
  "opciones que cumplen los requisitos del inversor.\n"
)

# Mostramos las primeras 5 opciones.

print(
  head(oportunidades, 5),
  n = 5,
  width = Inf
)