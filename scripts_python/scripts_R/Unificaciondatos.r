r

# ============================================================
# PROYECTO AIRBNB ESPAÑA
# PROCESO ETL: EXTRACCIÓN, TRANSFORMACIÓN Y CARGA
# ============================================================

# 1. CONFIGURACIÓN DEL ENTORNO

# Instalar las librerías si todavía no están instaladas:
# install.packages(c("readr", "dplyr", "stringr"))

library(readr)
library(dplyr)
library(stringr)

# Definimos la ruta raíz donde están las carpetas de las regiones.
RUTA_BASE <- "datos/"

# Columnas críticas que queremos conservar para optimizar memoria.
COLUMNAS_CLAVE <- c(
  "id", "listing_url", "name", "host_id", "host_name",
  "host_is_superhost", "neighbourhood_cleansed",
  "latitude", "longitude", "room_type", "accommodates",
  "bathrooms_text", "bedrooms", "beds", "price",
  "number_of_reviews", "review_scores_rating"
)

# Lista para almacenar los datos de cada región.
lista_dataframes <- list()

cat("🚀 Iniciando el proceso de unificación de datos...\n")


# ============================================================
# 2. BUCLE ETL: RECORRER CARPETAS POR REGIÓN
# ============================================================

# Obtenemos las subcarpetas del directorio principal.
carpetas <- list.dirs(
  path = RUTA_BASE,
  full.names = TRUE,
  recursive = FALSE
)

# Recorremos cada carpeta regional.
for (ruta_completa in carpetas) {

  carpeta_region <- basename(ruta_completa)

  archivo_listings <- file.path(
    ruta_completa,
    "listings.csv"
  )

  # Verificamos que exista el archivo listings.csv.
  if (file.exists(archivo_listings)) {

    cat(
      "📦 Procesando región:",
      toupper(carpeta_region),
      "...\n"
    )

    tryCatch({

      # LECTURA OPTIMIZADA:
      # Leemos solo las columnas clave del archivo.
      df_region <- read_csv(
        archivo_listings,
        col_select = any_of(COLUMNAS_CLAVE),
        show_col_types = FALSE,
        name_repair = "minimal"
      )

      # Comprobamos que las columnas esenciales existan.
      if (!"id" %in% names(df_region)) {
        stop("El archivo no contiene la columna obligatoria 'id'.")
      }

      if (!"price" %in% names(df_region)) {
        stop("El archivo no contiene la columna obligatoria 'price'.")
      }

      # TRANSFORMACIÓN:
      # Añadimos la región de origen para mantener la trazabilidad.
      df_region <- df_region %>%
        mutate(
          region_origen = str_to_title(carpeta_region)
        )

      # Guardamos el DataFrame en la lista.
      lista_dataframes[[length(lista_dataframes) + 1]] <-
        df_region

      cat(
        "   ✅ Leídas",
        nrow(df_region),
        "filas con éxito.\n"
      )

    }, error = function(e) {

      cat(
        "   ❌ Error al procesar",
        carpeta_region,
        ":",
        conditionMessage(e),
        "\n"
      )

    })
  }
}


# ============================================================
# 3. CONSOLIDACIÓN DE LOS DATASETS
# ============================================================

if (length(lista_dataframes) > 0) {

  cat("\n🔄 Uniendo todos los datasets en un archivo maestro...\n")

  # Unimos verticalmente los datos de todas las regiones.
  # bind_rows() combina las columnas y completa con NA
  # cuando alguna columna no existe en un archivo.
  df_espana_maestro <- bind_rows(lista_dataframes)

  cat(
    "   📊 Filas antes de eliminar duplicados:",
    nrow(df_espana_maestro),
    "\n"
  )


  # ==========================================================
  # 4. LIMPIEZA INICIAL DE DATOS
  # ==========================================================

  cat("🧹 Aplicando limpieza inicial...\n")

  # Aseguramos que el ID tenga un formato consistente.
  df_espana_maestro <- df_espana_maestro %>%
    mutate(
      id = as.character(id)
    )

  # Eliminamos duplicados por ID de alojamiento.
  # Conservamos la primera aparición de cada ID no nulo.
  df_espana_maestro <- df_espana_maestro %>%
    distinct(id, .keep_all = TRUE)

  # Limpiamos el precio:
  # "$1,034.00" -> "1034.00"
  # Convertimos los valores no válidos en NA.
  df_espana_maestro <- df_espana_maestro %>%
    mutate(
      price = as.character(price),
      price = str_remove_all(price, fixed("$")),
      price = str_remove_all(price, fixed(",")),
      price = parse_number(
        price,
        na = c("", "NA", "N/A"),
        locale = locale(decimal_mark = ".")
      )
    )


  # ==========================================================
  # 5. ALMACENAMIENTO DE LA CARGA (LOAD)
  # ==========================================================

  archivo_salida <- "airbnb_espana_master.csv"

  # Exportamos el dataset maestro sin la columna de índices.
  write_csv(
    df_espana_maestro,
    archivo_salida,
    na = ""
  )

  cat("\n🎉 ¡Proceso completado con éxito!\n")

  cat(
    "📊 Total de alojamientos consolidados en España:",
    nrow(df_espana_maestro),
    "filas.\n"
  )

  cat(
    "📋 Total de columnas:",
    ncol(df_espana_maestro),
    "\n"
  )

  cat(
    "💾 Archivo guardado como:",
    archivo_salida,
    "\n"
  )

} else {

  cat(
    "⚠️ No se encontraron archivos 'listings.csv' para unificar.\n"
  )

}