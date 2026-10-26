r

# ============================================================
# PREPROCESAMIENTO AVANZADO DE DATOS - AIRBNB CENTROAMÉRICA
# ============================================================

# 1. INSTALAR Y CARGAR LIBRERÍAS
# Ejecuta install.packages() solo si no tienes las librerías instaladas.

# install.packages(c("dplyr", "readr", "stringr"))

library(dplyr)
library(readr)
library(stringr)

# Cargamos el dataset unificado generado en el paso anterior
cat("🧹 Iniciando la fase avanzada de preprocesamiento de datos...\n")

df <- read_csv(
  "airbnb_centroamerica_master.csv",
  show_col_types = FALSE
)

# ============================================================
# RETO 1: TRATAMIENTO DE VALORES NULOS (MISSING VALUES)
# ============================================================

cat("\n1. Tratando valores nulos...\n")

# Imputamos bedrooms y beds con la mediana de cada región.
# Si una región tiene todos sus valores nulos, se mantienen como NA.

df <- df %>%
  group_by(region_origen) %>%
  mutate(
    bedrooms = {
      mediana <- median(bedrooms, na.rm = TRUE)
      if (is.nan(mediana)) NA_real_ else
        coalesce(bedrooms, mediana)
    },
    beds = {
      mediana <- median(beds, na.rm = TRUE)
      if (is.nan(mediana)) NA_real_ else
        coalesce(beds, mediana)
    }
  ) %>%
  ungroup()

# Creamos una bandera para identificar alojamientos sin puntuación.
# 1 = no tiene puntuación; 0 = tiene puntuación.

df <- df %>%
  mutate(
    has_no_reviews = as.integer(is.na(review_scores_rating)),
    review_scores_rating = coalesce(
      review_scores_rating,
      0
    )
  )

# Rellenamos los valores nulos de superhost con 'f'.

df <- df %>%
  mutate(
    host_is_superhost = coalesce(
      as.character(host_is_superhost),
      "f"
    )
  )

cat(
  "   Nulos tratados. Habitaciones vacías restantes:",
  sum(is.na(df$bedrooms)),
  "\n"
)

# ============================================================
# RETO 2: GESTIÓN DE OUTLIERS EN PRECIOS
# ============================================================

cat("\n2. Filtrando valores atípicos en precios...\n")

# Registramos el número de filas original.

filas_originales <- nrow(df)

# 1. LIMPIEZA:
# Eliminamos el símbolo '$' y las comas de los miles.
# Ejemplo: "$1,034.00" -> "1034.00"

df <- df %>%
  mutate(
    price = as.character(price),
    price = str_remove_all(price, fixed("$")),
    price = str_remove_all(price, fixed(","))
  )

# 2. CONVERSIÓN:
# Convertimos price a formato numérico.
# Los valores no válidos se convierten en NA.

df <- df %>%
  mutate(
    price = parse_number(
      price,
      na = c("", "NA", "N/A"),
      locale = locale(decimal_mark = ".")
    )
  )

# 3. FILTRADO:
# Conservamos precios entre 10 y 1000, ambos incluidos.
# Los precios nulos también se descartan.

df <- df %>%
  filter(!is.na(price), price >= 10, price <= 1000)

# Calculamos cuántas filas se han eliminado.

filas_filtradas <- filas_originales - nrow(df)

cat(
  "   Outliers eliminados:",
  filas_filtradas,
  "filas fuera del rango [10 - 1000].\n"
)

# ============================================================
# RETO 3: INGENIERÍA DE CARACTERÍSTICAS
# ============================================================

cat("\n3. Ejecutando Ingeniería de Características...\n")

# Extraemos el número de baños desde bathrooms_text.
# Ejemplos:
# "1.5 baths"       -> 1.5
# "1 private bath"  -> 1
# "Half-bath"       -> 0.5
# "Shared half-bath"-> 0.5

df <- df %>%
  mutate(
    bathrooms_text = str_to_lower(
      coalesce(as.character(bathrooms_text), "1")
    ),

    # Extraemos el primer número entero o decimal.
    bathrooms_num = str_extract(
      bathrooms_text,
      "\\d+\\.?\\d*"
    ),

    bathrooms_num = as.numeric(bathrooms_num),

    # Asignamos 0.5 si aparece "half" y no se extrajo un número.
    bathrooms_num = if_else(
      str_detect(bathrooms_text, "half") &
        is.na(bathrooms_num),
      0.5,
      bathrooms_num
    ),

    # Los demás valores nulos se rellenan con 1 baño.
    bathrooms_num = coalesce(bathrooms_num, 1.0)
  )

# Eliminamos la columna de texto original.

df <- df %>%
  select(-bathrooms_text)

cat(
  "   Columna numérica 'bathrooms_num' creada correctamente.\n"
)

# ============================================================
# GUARDAR DATASET FINAL Y LIMPIO
# ============================================================

archivo_final <- "airbnb_centroamerica_clean.csv"

write_csv(df, archivo_final)

cat("\n🎉 ¡Preprocesamiento avanzado finalizado!\n")
cat("📊 Dataset listo para análisis en R y Power BI.\n")
cat("💾 Archivo guardado como:", archivo_final, "\n")
cat("📈 Total de filas:", nrow(df), "\n")
cat("📋 Total de columnas:", ncol(df), "\n")