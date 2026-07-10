#' 02_prepare_data.R
#' Limpia el dataset crudo y construye una serie de tiempo diaria de demanda
#' (unidades vendidas) lista para Prophet (columnas ds, y).
#'
#' Reglas de limpieza:
#'   - Se excluyen facturas de cancelacion (invoice empieza con "C").
#'   - Se excluyen cantidades y precios negativos o cero (devoluciones/ajustes).
#'   - Se excluyen codigos de prueba conocidos del dataset (POST, D, M, BANK CHARGES, etc.).
#'   - La demanda se agrega a nivel diario (unidades totales vendidas, todos los SKU).
#'
#' Uso: Rscript R/02_prepare_data.R

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(here)
})

RAW_DIR <- here("data", "raw")
PROC_DIR <- here("data", "processed")
dir.create(PROC_DIR, recursive = TRUE, showWarnings = FALSE)

csv_path <- file.path(RAW_DIR, "online_retail_ii.csv")
if (!file.exists(csv_path)) {
  stop("No se encontro data/raw/online_retail_ii.csv. Corre primero: Rscript R/01_get_data.R")
}

message(">> Cargando datos crudos...")
datos <- read.csv(csv_path, stringsAsFactors = FALSE)

codigos_no_producto <- c("POST", "D", "M", "BANK CHARGES", "DOT", "C2", "PADS", "AMAZONFEE")

message(">> Limpiando...")
datos_limpios <- datos %>%
  filter(
    !grepl("^C", invoice),                 # cancelaciones
    quantity > 0,                            # sin devoluciones/ajustes negativos
    price > 0,                               # sin precio cero o negativo
    !stockcode %in% codigos_no_producto      # sin codigos administrativos
  ) %>%
  mutate(
    invoicedate = as.Date(invoicedate),
    revenue = quantity * price
  )

message(">> Filas validas tras limpieza: ", nrow(datos_limpios), " de ", nrow(datos))

serie_diaria <- datos_limpios %>%
  group_by(ds = invoicedate) %>%
  summarise(
    y = sum(quantity),
    revenue = sum(revenue),
    n_ordenes = n_distinct(invoice),
    .groups = "drop"
  ) %>%
  arrange(ds)

out_path <- file.path(PROC_DIR, "demanda_diaria.csv")
write.csv(serie_diaria, out_path, row.names = FALSE)

message(">> Serie diaria guardada en ", out_path)
message(">> Rango de fechas: ", min(serie_diaria$ds), " a ", max(serie_diaria$ds))
message(">> Dias en la serie: ", nrow(serie_diaria))
