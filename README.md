# demand-planning-notebook

[![Render y publicar Quarto site](https://github.com/lcarrenoy/demand-planning-notebook/actions/workflows/publish.yml/badge.svg)](https://github.com/lcarrenoy/demand-planning-notebook/actions/workflows/publish.yml)
[![Sitio publicado](https://img.shields.io/badge/sitio-GitHub%20Pages-2c3e50)](https://lcarrenoy.github.io/demand-planning-notebook/)

Forecasting de demanda reproducible end-to-end: **Quarto + Prophet + R**, con
publicación automática a GitHub Pages vía GitHub Actions.

**Sitio publicado**: https://lcarrenoy.github.io/demand-planning-notebook/

## Qué hace este proyecto

1. Descarga un dataset público real de transacciones retail ([Online Retail II,
   UCI ML Repository](https://doi.org/10.24432/C5CG6D)) — sin necesidad de API keys.
2. Limpia las transacciones (cancelaciones, devoluciones, códigos administrativos) y
   arma una serie de tiempo diaria de demanda (unidades vendidas/día).
3. Ajusta un modelo **Prophet** con estacionalidad semanal y anual.
4. Evalúa el modelo con **validación cruzada temporal (rolling origin)** — nunca con
   split aleatorio, porque en series de tiempo eso filtra información del futuro.
5. Genera un forecast a 90 días con banda de incertidumbre.
6. Publica todo como un notebook Quarto interactivo en GitHub Pages.

## Por qué no hay números de precisión escritos en este README

El notebook (`index.qmd`) corre el pipeline completo — descarga, limpieza, modelo y
validación cruzada — cada vez que se renderiza, tanto localmente como en CI/CD. El
MAPE/RMSE/MAE reales están en **la sección "Desempeño del modelo" del sitio
publicado**, no acá, para evitar que un número quede desactualizado si el dataset o
el modelo cambian. Esa es la única fuente de verdad.

## Stack

| Componente | Herramienta |
|---|---|
| Modelo de forecasting | [Prophet](https://facebook.github.io/prophet/) (R) |
| Notebook / sitio | [Quarto](https://quarto.org/) |
| Lenguaje | R |
| CI/CD | GitHub Actions |
| Publicación | GitHub Pages (rama `gh-pages`) |
| Dataset | [Online Retail II](https://doi.org/10.24432/C5CG6D) (UCI ML Repository) |

## Estructura

```
demand-planning-notebook/
├── R/
│   ├── 01_get_data.R          # descarga dataset UCI (sin auth)
│   ├── 02_prepare_data.R      # limpieza + serie diaria (ds, y)
│   ├── 03_forecast_prophet.R  # modelo Prophet + validación cruzada
│   └── install_packages.R     # dependencias de R
├── index.qmd                  # notebook principal (orquesta el pipeline)
├── _quarto.yml                # config del sitio Quarto
├── styles.css
├── .github/workflows/publish.yml  # CI/CD: render + deploy a GitHub Pages
├── data/                      # (no versionado) datos crudos y procesados
└── README.md
```

## Cómo reproducirlo localmente

Requisitos: [R](https://www.r-project.org/) 4.3+, [Quarto CLI](https://quarto.org/docs/get-started/).

```bash
git clone https://github.com/lcarrenoy/demand-planning-notebook.git
cd demand-planning-notebook

Rscript R/install_packages.R
quarto render
```

Esto descarga el dataset, corre el pipeline completo y genera el sitio en `docs/`.
Para verlo localmente: `quarto preview`.

## CI/CD

En cada push a `main`, `.github/workflows/publish.yml`:

1. Instala R y las dependencias de sistema que necesita Prophet/rstan.
2. Instala los paquetes de R (`R/install_packages.R`).
3. Corre `quarto render`, que ejecuta todo el pipeline de datos y modelo desde cero.
4. Publica el resultado en la rama `gh-pages`, servida por GitHub Pages.

No requiere secrets adicionales — el dataset es público y se descarga por HTTPS.

## Metodología (resumen)

- **Serie objetivo**: unidades vendidas por día, agregando todos los SKU del dataset.
- **Limpieza**: se excluyen cancelaciones (`invoice` que empieza con `C`), cantidades
  o precios ≤ 0, y códigos administrativos (`POST`, `D`, `M`, `BANK CHARGES`, etc.).
- **Modelo**: Prophet con estacionalidad semanal + anual, modo multiplicativo,
  `changepoint_prior_scale = 0.05`.
- **Validación**: rolling-origin cross-validation con `prophet::cross_validation()` —
  simula múltiples cortes en el tiempo y mide error solo contra datos futuros reales.
- **Horizonte de forecast**: 90 días.

## Licencia de los datos

El dataset Online Retail II es de uso público bajo los términos del UCI Machine
Learning Repository. Cita: Chen, D. (2019). *Online Retail II* [Dataset]. UCI Machine
Learning Repository. https://doi.org/10.24432/C5CG6D

---

Parte del [portafolio de Luis Carreño](https://github.com/lcarrenoy).
