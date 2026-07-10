#' 03_forecast_prophet.R
#' Ajusta un modelo Prophet sobre la demanda diaria y evalua su desempeno
#' con validacion cruzada temporal (rolling origin), tal como corresponde
#' a series de tiempo (nunca split aleatorio).
#'
#' Guarda:
#'   - data/processed/forecast.csv       (prediccion a 90 dias)
#'   - data/processed/cv_metrics.csv     (metricas de validacion cruzada: MAPE, RMSE, MAE)
#'
#' Uso: Rscript R/03_forecast_prophet.R

suppressPackageStartupMessages({
  library(prophet)
  library(dplyr)
  library(here)
})

PROC_DIR <- here("data", "processed")
serie_path <- file.path(PROC_DIR, "demanda_diaria.csv")

if (!file.exists(serie_path)) {
  stop("No se encontro data/processed/demanda_diaria.csv. Corre primero: Rscript R/02_prepare_data.R")
}

serie <- read.csv(serie_path, stringsAsFactors = FALSE) %>%
  mutate(ds = as.Date(ds)) %>%
  select(ds, y)

message(">> Ajustando modelo Prophet...")
modelo <- prophet(
  serie,
  daily.seasonality = FALSE,
  weekly.seasonality = TRUE,
  yearly.seasonality = TRUE,
  seasonality.mode = "multiplicative",
  changepoint.prior.scale = 0.05
)

HORIZONTE_DIAS <- 90
futuro <- make_future_dataframe(modelo, periods = HORIZONTE_DIAS)
prediccion <- predict(modelo, futuro)

forecast_out <- prediccion %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  mutate(ds = as.Date(ds))

write.csv(forecast_out, file.path(PROC_DIR, "forecast.csv"), row.names = FALSE)
message(">> Forecast guardado (", HORIZONTE_DIAS, " dias) en data/processed/forecast.csv")

# ---- Validacion cruzada temporal (rolling origin) ----
# initial: dias minimos de entrenamiento antes de la primera evaluacion
# period:  cada cuantos dias se mueve el "corte" de evaluacion
# horizon: cuantos dias hacia adelante se evalua en cada corte
message(">> Corriendo validacion cruzada temporal (puede tardar unos minutos)...")
dias_totales <- as.numeric(max(serie$ds) - min(serie$ds))
initial_dias <- max(180, floor(dias_totales * 0.5))

cv <- tryCatch({
  # Nota: la API de R (a diferencia de la de Python) espera initial/period/horizon
  # como NUMERICOS, con "units" indicando la unidad de todos ellos.
  cross_validation(
    modelo,
    initial = initial_dias,
    period  = 30,
    horizon = 30,
    units   = "days"
  )
}, error = function(e) {
  message("!! Validacion cruzada fallo (dataset puede ser muy corto): ", conditionMessage(e))
  NULL
})

if (!is.null(cv)) {
  metricas <- performance_metrics(cv, rolling_window = 1)
  write.csv(metricas, file.path(PROC_DIR, "cv_metrics.csv"), row.names = FALSE)

  mape_prom <- mean(metricas$mape, na.rm = TRUE) * 100
  rmse_prom <- mean(metricas$rmse, na.rm = TRUE)
  mae_prom  <- mean(metricas$mae, na.rm = TRUE)

  message(sprintf(">> MAPE promedio (CV): %.2f%%", mape_prom))
  message(sprintf(">> RMSE promedio (CV): %.2f", rmse_prom))
  message(sprintf(">> MAE promedio (CV):  %.2f", mae_prom))
} else {
  message(">> No se generaron metricas de CV. Revisar longitud de la serie.")
}

message(">> Listo.")
