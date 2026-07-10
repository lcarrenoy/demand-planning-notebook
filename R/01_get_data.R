#' 01_get_data.R
#' Descarga el dataset publico "Online Retail II" (UCI Machine Learning Repository).
#' Fuente: Chen, D. (2019). Online Retail II [Dataset]. UCI ML Repository.
#'         https://doi.org/10.24432/C5CG6D
#' No requiere autenticacion: descarga directa por HTTPS (funciona en GitHub Actions sin secrets).
#'
#' Uso: Rscript R/01_get_data.R

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(here)
})

RAW_DIR <- here("data", "raw")
dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)

url_zip   <- "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip"
zip_path  <- file.path(RAW_DIR, "online_retail_ii.zip")
csv_path  <- file.path(RAW_DIR, "online_retail_ii.csv")

if (!file.exists(csv_path)) {

  # Buscamos el .xlsx ya descomprimido en vez de asumir mayusculas/minusculas
  # exactas del nombre (el runner de GitHub Actions es Linux, case-sensitive,
  # y el zip de UCI no siempre conserva el mismo casing entre versiones).
  xlsx_candidatos <- list.files(RAW_DIR, pattern = "\\.xlsx$", full.names = TRUE)

  if (length(xlsx_candidatos) == 0) {
    message(">> Descargando dataset desde UCI ML Repository...")
    download.file(url_zip, destfile = zip_path, mode = "wb", quiet = FALSE)
    unzip(zip_path, exdir = RAW_DIR)
    xlsx_candidatos <- list.files(RAW_DIR, pattern = "\\.xlsx$", full.names = TRUE)
  }

  if (length(xlsx_candidatos) == 0) {
    stop("No se encontro ningun .xlsx tras descomprimir el zip de UCI.")
  }
  xlsx_path <- xlsx_candidatos[1]

  message(">> Leyendo hojas del Excel (2009-2010 y 2010-2011) desde ", basename(xlsx_path))
  sheet1 <- read_excel(xlsx_path, sheet = "Year 2009-2010")
  sheet2 <- read_excel(xlsx_path, sheet = "Year 2010-2011")

  datos <- bind_rows(sheet1, sheet2) %>%
    rename_with(~ gsub(" ", "_", tolower(.x)))

  message(">> Guardando CSV consolidado en ", csv_path)
  write.csv(datos, csv_path, row.names = FALSE)

} else {
  message(">> CSV ya existe, se omite descarga: ", csv_path)
}

message(">> Listo. Filas: ", nrow(read.csv(csv_path, nrows = 1)))
