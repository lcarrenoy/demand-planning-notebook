#' install_packages.R
#' Instala las dependencias de R necesarias para el proyecto.
#' Se usa tanto localmente como en el workflow de GitHub Actions.
#'
#' Uso: Rscript R/install_packages.R

paquetes <- c(
  "prophet",
  "dplyr",
  "readxl",
  "lubridate",
  "here",
  "ggplot2",
  "plotly",
  "knitr",
  "rmarkdown",
  "scales",
  "DT"
)

instalados <- rownames(installed.packages())
faltantes <- setdiff(paquetes, instalados)

if (length(faltantes) > 0) {
  message(">> Instalando paquetes faltantes: ", paste(faltantes, collapse = ", "))
  install.packages(faltantes, repos = "https://cloud.r-project.org")
} else {
  message(">> Todos los paquetes ya estan instalados.")
}
