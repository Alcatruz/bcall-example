# ============================================================================
# Comparación: Importancia del Etiquetado Previo en B-Call
# ============================================================================
#
# Este script demuestra cómo un etiquetado incorrecto puede afectar
# el análisis B-Call con clustering manual.
#
# Comparamos:
# 1. Clustering ORIGINAL (con errores de etiquetado)
# 2. Clustering CORREGIDO (basado en comportamiento real de votación)
# ============================================================================

library(bcall)
library(dplyr)
library(ggplot2)
library(gridExtra)

# Cargar datos de votaciones
rollcall <- read.csv("data/CHL-rollcall-2025.csv", row.names = 1)

# Cargar ambas versiones del clustering
clustering_original <- read.csv("data/CHL-clustering-2025.csv", row.names = 1)
clustering_corregido <- read.csv("data/CHL-clustering-2025-CORREGIDO.csv", row.names = 1)

cat("\n", strrep("=", 70), "\n", sep = "")
cat("COMPARACIÓN: CLUSTERING ORIGINAL VS CORREGIDO\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Contar diputados por cluster en cada versión
cat("CLUSTERING ORIGINAL (con errores de etiquetado):\n")
print(table(clustering_original$cluster))

cat("\nCLUSTERING CORREGIDO (basado en comportamiento real):\n")
print(table(clustering_corregido$cluster))

# ----------------------------------------------------------------------------
# ANÁLISIS 1: Con clustering ORIGINAL (potencialmente erróneo)
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("ANÁLISIS 1: Clustering ORIGINAL\n")
cat(strrep("=", 70), "\n\n", sep = "")

resultado_original <- bcall(
  rollcall = rollcall,
  clustering = clustering_original,
  pivot = "Alessandri_Vergara_Jorge",
  threshold = 0.1,
  verbose = TRUE
)

# ----------------------------------------------------------------------------
# ANÁLISIS 2: Con clustering CORREGIDO
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("ANÁLISIS 2: Clustering CORREGIDO\n")
cat(strrep("=", 70), "\n\n", sep = "")

resultado_corregido <- bcall(
  rollcall = rollcall,
  clustering = clustering_corregido,
  pivot = "Alessandri_Vergara_Jorge",
  threshold = 0.1,
  verbose = TRUE
)

# ----------------------------------------------------------------------------
# COMPARACIÓN DE RESULTADOS
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("COMPARACIÓN DE RESULTADOS\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Identificar diputados que cambiaron de cluster
comparacion <- resultado_original$results %>%
  select(legislator, d1, d2, cluster_original = cluster) %>%
  left_join(
    resultado_corregido$results %>% select(legislator, cluster_corregido = cluster),
    by = "legislator"
  ) %>%
  mutate(
    cambio = ifelse(cluster_original != cluster_corregido, "SI", "NO")
  )

# Diputados reclasificados
reclasificados <- comparacion %>%
  filter(cambio == "SI") %>%
  arrange(cluster_original, d1)

cat(sprintf("Diputados reclasificados: %d\n\n", nrow(reclasificados)))

cat("Detalle de reclasificaciones:\n\n")
cat(sprintf("%-40s %15s -> %-15s %8s\n",
            "Diputado", "Original", "Corregido", "d1"))
cat(strrep("-", 80), "\n", sep = "")

for (i in 1:nrow(reclasificados)) {
  cat(sprintf("%-40s %15s -> %-15s %+8.3f\n",
              reclasificados$legislator[i],
              reclasificados$cluster_original[i],
              reclasificados$cluster_corregido[i],
              reclasificados$d1[i]))
}

# Estadísticas de la reclasificación
cat("\n\nRESUMEN DE RECLASIFICACIONES:\n")
reclasif_summary <- reclasificados %>%
  group_by(cluster_original, cluster_corregido) %>%
  summarise(
    n = n(),
    d1_mean = mean(d1),
    .groups = "drop"
  )
print(reclasif_summary)

# ----------------------------------------------------------------------------
# VISUALIZACIÓN COMPARATIVA
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Generando visualizaciones comparativas...\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Gráfico con clustering original
p_original <- plot_bcall_analysis(
  resultado_original,
  title = "Clustering ORIGINAL (con errores de etiquetado)",
  show_names = FALSE,
  alpha = 0.7,
  size = 3
)

# Gráfico con clustering corregido
p_corregido <- plot_bcall_analysis(
  resultado_corregido,
  title = "Clustering CORREGIDO (basado en comportamiento real)",
  show_names = FALSE,
  alpha = 0.7,
  size = 3
)

# Guardar gráficos individuales
ggsave("results/plot_clustering_original.png", p_original, width = 10, height = 7, dpi = 300)
ggsave("results/plot_clustering_corregido.png", p_corregido, width = 10, height = 7, dpi = 300)

# Crear gráfico comparativo lado a lado
p_comparacion <- grid.arrange(p_original, p_corregido, ncol = 2)

ggsave(
  "results/comparacion_etiquetado.png",
  p_comparacion,
  width = 20,
  height = 7,
  dpi = 300
)

cat("✓ Gráficos guardados:\n")
cat("  - results/plot_clustering_original.png\n")
cat("  - results/plot_clustering_corregido.png\n")
cat("  - results/comparacion_etiquetado.png\n\n")

# Gráficos interactivos
plot_int_original <- plot_bcall_analysis_interactive(
  resultado_original,
  title = "Clustering ORIGINAL (con errores)"
)

plot_int_corregido <- plot_bcall_analysis_interactive(
  resultado_corregido,
  title = "Clustering CORREGIDO"
)

# Guardar interactivos
if (requireNamespace("htmlwidgets", quietly = TRUE)) {
  htmlwidgets::saveWidget(
    plot_int_original,
    "results/plot_interactive_original.html",
    selfcontained = TRUE,
    title = "B-Call Chile 2025 - Clustering Original"
  )

  htmlwidgets::saveWidget(
    plot_int_corregido,
    "results/plot_interactive_corregido.html",
    selfcontained = TRUE,
    title = "B-Call Chile 2025 - Clustering Corregido"
  )

  cat("✓ Gráficos interactivos guardados:\n")
  cat("  - results/plot_interactive_original.html\n")
  cat("  - results/plot_interactive_corregido.html\n\n")
}

# ----------------------------------------------------------------------------
# ANÁLISIS DE LA MEJORA
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("ANÁLISIS: ¿MEJORA EL CLUSTERING CORREGIDO?\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Calcular coherencia: diputados con d1 que coincide con su cluster
coherencia_original <- resultado_original$results %>%
  mutate(
    coherente = case_when(
      cluster == "derecha" & d1 > 0 ~ TRUE,
      cluster == "izquierda" & d1 < 0 ~ TRUE,
      TRUE ~ FALSE
    )
  ) %>%
  summarise(
    total = n(),
    coherentes = sum(coherente),
    porcentaje = 100 * coherentes / total
  )

coherencia_corregido <- resultado_corregido$results %>%
  mutate(
    coherente = case_when(
      cluster == "derecha" & d1 > 0 ~ TRUE,
      cluster == "izquierda" & d1 < 0 ~ TRUE,
      TRUE ~ FALSE
    )
  ) %>%
  summarise(
    total = n(),
    coherentes = sum(coherente),
    porcentaje = 100 * coherentes / total
  )

cat("Coherencia entre cluster asignado y comportamiento real (d1):\n\n")
cat(sprintf("ORIGINAL:   %d/%d diputados coherentes (%.1f%%)\n",
            coherencia_original$coherentes,
            coherencia_original$total,
            coherencia_original$porcentaje))

cat(sprintf("CORREGIDO:  %d/%d diputados coherentes (%.1f%%)\n",
            coherencia_corregido$coherentes,
            coherencia_corregido$total,
            coherencia_corregido$porcentaje))

cat(sprintf("\nMEJORA: +%.1f puntos porcentuales\n",
            coherencia_corregido$porcentaje - coherencia_original$porcentaje))

# ----------------------------------------------------------------------------
# EXPORTAR RESULTADOS
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("Exportando resultados...\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Guardar comparación
write.csv(
  comparacion,
  "results/comparacion_clusters.csv",
  row.names = FALSE
)

# Guardar solo los reclasificados
write.csv(
  reclasificados,
  "results/diputados_reclasificados.csv",
  row.names = FALSE
)

cat("✓ Archivos CSV guardados:\n")
cat("  - results/comparacion_clusters.csv\n")
cat("  - results/diputados_reclasificados.csv\n")

# ----------------------------------------------------------------------------
# CONCLUSIÓN
# ----------------------------------------------------------------------------

cat("\n", strrep("=", 70), "\n", sep = "")
cat("CONCLUSIÓN\n")
cat(strrep("=", 70), "\n\n", sep = "")

cat("Este análisis demuestra la importancia del ETIQUETADO PREVIO en B-Call:\n\n")

cat(sprintf("1. Con etiquetado ORIGINAL: %.1f%% de coherencia\n",
            coherencia_original$porcentaje))
cat(sprintf("2. Con etiquetado CORREGIDO: %.1f%% de coherencia\n",
            coherencia_corregido$porcentaje))
cat(sprintf("3. Mejora: +%.1f puntos porcentuales\n\n",
            coherencia_corregido$porcentaje - coherencia_original$porcentaje))

cat("LECCIONES CLAVE:\n\n")
cat("• El clustering manual requiere una clasificación previa PRECISA\n")
cat("• Errores en el etiquetado previo pueden distorsionar el análisis\n")
cat("• Los 'tránsfugas' identificados probablemente NO son tránsfugas,\n")
cat("  sino diputados mal etiquetados desde el inicio\n")
cat("• B-Call REVELA estos errores de clasificación al mostrar el\n")
cat("  comportamiento real de votación\n\n")

cat("RECOMENDACIÓN:\n\n")
cat("Usa clustering AUTOMÁTICO (bcall_auto) cuando:\n")
cat("  - No tienes clasificación previa confiable\n")
cat("  - Quieres descubrir agrupaciones naturales sin sesgos\n")
cat("  - Sospechas que las etiquetas actuales son incorrectas\n\n")

cat("Usa clustering MANUAL (bcall) cuando:\n")
cat("  - Tienes clasificación previa VERIFICADA y confiable\n")
cat("  - Quieres comparar comportamiento real vs. afiliación política\n")
cat("  - Buscas identificar tránsfugas o cambios ideológicos reales\n\n")

cat(strrep("=", 70), "\n\n", sep = "")
