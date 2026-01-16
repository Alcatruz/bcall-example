# ============================================================================
# Ejemplo B-Call: Análisis de Votaciones Cámara de Diputados Chile 2025
# ============================================================================
#
# Este script demuestra el uso del paquete bcall para analizar votaciones
# legislativas reales de la Cámara de Diputados de Chile.
#
# Autor: Daniel Alcatruz
# Paquete: https://github.com/bcallr/bcall
# Datos: https://github.com/Alcatruz/bcall-example
# ============================================================================

# ----------------------------------------------------------------------------
# 1. INSTALACIÓN Y CARGA DE PAQUETES
# ----------------------------------------------------------------------------

# Instalar bcall desde GitHub (solo la primera vez)
if (!require("bcall")) {
  if (!require("devtools")) install.packages("devtools")
  devtools::install_github("bcallr/bcall")
}

# Cargar paquetes necesarios
library(bcall)
library(dplyr)   # Para manipulación de datos
library(ggplot2) # Para gráficos adicionales

# Crear carpeta results si no existe
if (!dir.exists("results")) {
  dir.create("results")
  cat("✓ Carpeta 'results' creada\n\n")
}

# ----------------------------------------------------------------------------
# 2. CARGAR DATOS
# ----------------------------------------------------------------------------

# Asegúrate de estar en el directorio correcto
# setwd("C:/Users/tu_usuario/Documents/bcall-example")

# Cargar votaciones (matriz con diputados en filas, votaciones en columnas)
rollcall <- read.csv("data/CHL-rollcall-2025.csv", row.names = 1)

# Cargar clustering manual (izquierda/derecha)
clustering <- read.csv("data/CHL-clustering-2025.csv", row.names = 1)

# Explorar los datos
cat("Dimensiones de la matriz de votaciones:\n")
cat(sprintf("  - %d diputados\n", nrow(rollcall)))
cat(sprintf("  - %d votaciones\n", ncol(rollcall)))

cat("\nPrimeras filas de votaciones:\n")
print(rollcall[1:3, 1:5])

cat("\nPrimeras filas del clustering:\n")
print(head(clustering))

# ----------------------------------------------------------------------------
# 3. EJEMPLO 1: ANÁLISIS CON CLUSTERING AUTOMÁTICO
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("EJEMPLO 1: Análisis con Clustering Automático\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Ejecutar bcall_auto
resultado_auto <- bcall_auto(
  rollcall = rollcall,
  distance_method = 1,    # 1 = Manhattan (recomendado), 2 = Euclidean
  pivot = "Alessandri_Vergara_Jorge",           # NULL = selección automática del pivot
  threshold = 0.1,        # Mínimo 10% de participación
  verbose = TRUE
)

# Ver estructura del resultado
cat("\nEstructura del objeto resultado:\n")
cat("  - $results: data.frame con d1, d2 y cluster para cada diputado\n")
cat("  - $bcall_object: objeto R6 BCall (uso avanzado)\n")
cat("  - $metadata: información sobre el análisis\n\n")

# Ver primeros resultados
cat("Primeros 10 diputados (ordenados por d1):\n")
print(head(resultado_auto$results %>% arrange(d1), 10))

# Resumen estadístico
cat("\nResumen estadístico:\n")
summary(resultado_auto$results[, c("d1", "d2")])

# Contar diputados por cluster
cat("\nDiputados por cluster automático:\n")
print(table(resultado_auto$results$auto_cluster))

# ----------------------------------------------------------------------------
# 4. VISUALIZACIÓN - CLUSTERING AUTOMÁTICO
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Generando visualizaciones (clustering automático)...\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Gráfico estático
p1 <- plot_bcall_analysis(
  resultado_auto,
  title = "B-Call: Cámara de Diputados Chile 2025 (Clustering Automático)",
  show_names = FALSE,
  alpha = 0.7,
  size = 3
)
print(p1)

# Guardar gráfico
ggsave(
  "results/plot_auto.png",
  plot = p1,
  width = 10,
  height = 7,
  dpi = 300
)
cat("✓ Gráfico guardado en: results/plot_auto.png\n")

# Gráfico interactivo (se abre en el navegador)
plot_interactivo <- plot_bcall_analysis_interactive(
  resultado_auto,
  title = "B-Call Chile 2025 - Interactivo (pasa el mouse sobre los puntos)"
)
print(plot_interactivo)

# Guardar como HTML para la web
if (requireNamespace("htmlwidgets", quietly = TRUE)) {
  htmlwidgets::saveWidget(
    plot_interactivo,
    "results/plot_interactive.html",
    selfcontained = TRUE,
    title = "B-Call Chile 2025 - Análisis Interactivo"
  )
  cat("✓ Gráfico interactivo guardado en: results/plot_interactive.html\n")
} else {
  cat("! Para guardar gráfico interactivo, instala: install.packages('htmlwidgets')\n")
}

# ----------------------------------------------------------------------------
# 5. ANÁLISIS EXPLORATORIO - CLUSTERING AUTOMÁTICO
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("ANÁLISIS EXPLORATORIO\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Diputados más de izquierda (d1 más bajo)
cat("Top 5 diputados más de IZQUIERDA (d1 más bajo):\n")
izquierda_extrema <- resultado_auto$results %>%
  arrange(d1) %>%
  head(5) %>%
  select(legislator, d1, d2, auto_cluster)
print(izquierda_extrema)

# Diputados más de derecha (d1 más alto)
cat("\nTop 5 diputados más de DERECHA (d1 más alto):\n")
derecha_extrema <- resultado_auto$results %>%
  arrange(desc(d1)) %>%
  head(5) %>%
  select(legislator, d1, d2, auto_cluster)
print(derecha_extrema)

# Diputados más cohesivos (d2 más bajo = votan con su bloque)
cat("\nTop 5 diputados más COHESIVOS (d2 más bajo):\n")
mas_cohesivos <- resultado_auto$results %>%
  arrange(d2) %>%
  head(5) %>%
  select(legislator, d1, d2, auto_cluster)
print(mas_cohesivos)

# Diputados menos cohesivos (d2 más alto = votan contra su bloque)
cat("\nTop 5 diputados menos COHESIVOS (d2 más alto):\n")
menos_cohesivos <- resultado_auto$results %>%
  arrange(desc(d2)) %>%
  head(5) %>%
  select(legislator, d1, d2, auto_cluster)
print(menos_cohesivos)

# ----------------------------------------------------------------------------
# 6. EJEMPLO 2: ANÁLISIS CON CLUSTERING MANUAL
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("EJEMPLO 2: Análisis con Clustering Manual (Izquierda/Derecha)\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Seleccionar un pivot del cluster "derecha"
# El pivot es un diputado de referencia que define la orientación del eje d1
diputados_derecha <- rownames(clustering)[clustering$cluster == "derecha"]
pivot_legislator <- diputados_derecha[1]  # Tomar el primero
cat(sprintf("Pivot seleccionado: %s (cluster: derecha)\n\n", pivot_legislator))

# Ejecutar bcall con clustering manual
resultado_manual <- bcall(
  rollcall = rollcall,
  clustering = clustering,
  pivot = pivot_legislator,
  threshold = 0.1,
  verbose = TRUE
)

# Ver resultados
cat("\nPrimeros 10 diputados (clustering manual):\n")
print(head(resultado_manual$results %>% arrange(d1), 10))

# Comparar clusters automático vs manual
cat("\nTabla cruzada: cluster automático vs manual:\n")
comparacion <- resultado_auto$results %>%
  left_join(
    resultado_manual$results %>% select(legislator, cluster_manual = cluster),
    by = "legislator"
  )
print(table(
  Auto = comparacion$auto_cluster,
  Manual = comparacion$cluster_manual
))

# ----------------------------------------------------------------------------
# 7. VISUALIZACIÓN - CLUSTERING MANUAL
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Generando visualizaciones (clustering manual)...\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Gráfico con clustering manual (detecta automáticamente "izquierda"/"derecha")
p2 <- plot_bcall_analysis(
  resultado_manual,
  title = "B-Call: Cámara de Diputados Chile 2025 (Clustering Manual)",
  show_names = FALSE,
  alpha = 0.7,
  size = 3
)
print(p2)

# Guardar gráfico
ggsave(
  "results/plot_manual.png",
  plot = p2,
  width = 10,
  height = 7,
  dpi = 300
)
cat("✓ Gráfico guardado en: results/plot_manual.png\n")

# ----------------------------------------------------------------------------
# 8. EXPORTAR RESULTADOS
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Exportando resultados...\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Guardar resultados como CSV
write.csv(
  resultado_auto$results,
  "results/resultados_auto.csv",
  row.names = FALSE
)
cat("✓ Resultados automáticos guardados en: results/resultados_auto.csv\n")

write.csv(
  resultado_manual$results,
  "results/resultados_manual.csv",
  row.names = FALSE
)
cat("✓ Resultados manuales guardados en: results/resultados_manual.csv\n")

# Guardar comparación
write.csv(
  comparacion,
  "results/comparacion_auto_vs_manual.csv",
  row.names = FALSE
)
cat("✓ Comparación guardada en: results/comparacion_auto_vs_manual.csv\n")

# ----------------------------------------------------------------------------
# 9. ANÁLISIS ADICIONAL: ESTADÍSTICAS POR CLUSTER
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("ESTADÍSTICAS POR CLUSTER\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Estadísticas por cluster manual
stats_cluster <- resultado_manual$results %>%
  group_by(cluster) %>%
  summarise(
    n = n(),
    d1_mean = mean(d1, na.rm = TRUE),
    d1_sd = sd(d1, na.rm = TRUE),
    d2_mean = mean(d2, na.rm = TRUE),
    d2_sd = sd(d2, na.rm = TRUE)
  )

cat("Estadísticas por cluster (manual):\n")
print(stats_cluster)

# ----------------------------------------------------------------------------
# FIN DEL SCRIPT
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("✓ Análisis completado exitosamente!\n")
cat(strrep("=", 70), "\n\n", sep = "")

cat("Archivos generados:\n")
cat("  - results/plot_auto.png\n")
cat("  - results/plot_manual.png\n")
cat("  - results/plot_interactive.html (gráfico web interactivo)\n")
cat("  - results/resultados_auto.csv\n")
cat("  - results/resultados_manual.csv\n")
cat("  - results/comparacion_auto_vs_manual.csv\n\n")

cat("Para más información:\n")
cat("  - Documentación: https://github.com/bcallr/bcall\n")
cat("  - Ejemplos: https://github.com/Alcatruz/bcall-example\n\n")
