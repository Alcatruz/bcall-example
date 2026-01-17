# ==============================================================================
# Análisis de Volatilidad: B-Call captura lo que W-NOMINATE ignora
# ==============================================================================

library(bcall)
library(dplyr)
library(ggplot2)
library(readxl)
library(ggrepel)

# Cargar datos
rollcall <- read.csv("data/CHL-rollcall-2025.csv", row.names = 1)
clustering_corregido <- read.csv("data/CHL-clustering-2025-CORREGIDO.csv", row.names = 1)

# Ejecutar B-Call
resultado_bcall <- bcall(
  rollcall = rollcall,
  clustering = clustering_corregido,
  pivot = "Alessandri_Vergara_Jorge",
  threshold = 0.1,
  verbose = FALSE
)

# Cargar W-NOMINATE
wnominate <- read_excel("df_wnominate.xlsx")

# Matchear
comparacion <- resultado_bcall$results %>%
  select(legislator, d1, d2, cluster) %>%
  left_join(
    wnominate %>% select(legislator, coord1D, coord2D),
    by = "legislator"
  )

# ==============================================================================
# IDENTIFICAR DOS TIPOS DE OUTLIERS
# ==============================================================================

# ZONA ROJA: d2 alto + coord2D centrado = "W-NOMINATE los ve bipolares"
outliers_zona_roja <- comparacion %>%
  filter(
    d2 > 0.9,                    # Alta volatilidad en B-Call
    abs(coord2D) < 0.2           # Centrados en W-NOMINATE
  ) %>%
  mutate(zona = "Roja: W-NOMINATE los ve bipolares") %>%
  arrange(desc(d2))

# ZONA AMARILLA: d1 centrado + d2 alto = "Centrados pero erráticos"
outliers_zona_amarilla <- comparacion %>%
  filter(
    abs(d1) < 0.3,               # Centrados ideológicamente
    d2 > 0.9                     # Alta volatilidad
  ) %>%
  mutate(zona = "Amarilla: Centrados pero erráticos") %>%
  arrange(desc(d2))

# Combinar outliers (sin duplicados)
outliers <- bind_rows(outliers_zona_roja, outliers_zona_amarilla) %>%
  distinct(legislator, .keep_all = TRUE)

# ==============================================================================
# MOSTRAR OUTLIERS
# ==============================================================================

cat("\n", strrep("=", 80), "\n", sep = "")
cat("OUTLIERS: Dos zonas de alta volatilidad\n")
cat(strrep("=", 80), "\n\n", sep = "")

cat(sprintf("ZONA ROJA (d2 > 0.9 + |coord2D| < 0.2): %d legisladores\n", nrow(outliers_zona_roja)))
cat("W-NOMINATE los ve bipolares (coord2D centrado), B-Call los ve volátiles\n\n")

if (nrow(outliers_zona_roja) > 0) {
  cat(sprintf("%-40s %10s %8s %8s %10s %10s\n",
              "Legislador", "Cluster", "d1", "d2", "coord1D", "coord2D"))
  cat(strrep("-", 80), "\n", sep = "")
  for (i in 1:nrow(outliers_zona_roja)) {
    cat(sprintf("%-40s %10s %+8.3f %8.3f %+10.3f %+10.3f\n",
                outliers_zona_roja$legislator[i],
                outliers_zona_roja$cluster[i],
                outliers_zona_roja$d1[i],
                outliers_zona_roja$d2[i],
                outliers_zona_roja$coord1D[i],
                outliers_zona_roja$coord2D[i]))
  }
  cat("\n")
}

cat(sprintf("ZONA AMARILLA (|d1| < 0.3 + d2 > 0.9): %d legisladores\n", nrow(outliers_zona_amarilla)))
cat("Centrados ideológicamente pero erráticos (B-Call lo detecta, W-NOMINATE no)\n\n")

if (nrow(outliers_zona_amarilla) > 0) {
  cat(sprintf("%-40s %10s %8s %8s %10s %10s\n",
              "Legislador", "Cluster", "d1", "d2", "coord1D", "coord2D"))
  cat(strrep("-", 80), "\n", sep = "")
  for (i in 1:nrow(outliers_zona_amarilla)) {
    cat(sprintf("%-40s %10s %+8.3f %8.3f %+10.3f %+10.3f\n",
                outliers_zona_amarilla$legislator[i],
                outliers_zona_amarilla$cluster[i],
                outliers_zona_amarilla$d1[i],
                outliers_zona_amarilla$d2[i],
                outliers_zona_amarilla$coord1D[i],
                outliers_zona_amarilla$coord2D[i]))
  }
  cat("\n")
}

cat("INSIGHT:\n")
cat("- ZONA ROJA: W-NOMINATE no detecta su volatilidad (coord2D centrado)\n")
cat("- ZONA AMARILLA: Centrados ideológicamente pero muy erráticos en votación\n")
cat("- B-Call CAPTURA ambos tipos de volatilidad que W-NOMINATE IGNORA\n\n")

# Marcar outliers con zona
comparacion <- comparacion %>%
  mutate(
    zona_outlier = case_when(
      legislator %in% outliers_zona_roja$legislator ~ "Roja",
      legislator %in% outliers_zona_amarilla$legislator ~ "Amarilla",
      TRUE ~ "Normal"
    )
  )

# ==============================================================================
# GRÁFICO 1: Scatter d1 vs d2 con DOS ZONAS destacadas
# ==============================================================================

p1 <- ggplot(comparacion, aes(x = d1, y = d2, color = cluster)) +
  # Zona Roja: toda la franja d2 > 0.9
  annotate(
    "rect",
    xmin = -Inf, xmax = Inf,
    ymin = 0.9, ymax = Inf,
    alpha = 0.1,
    fill = "red"
  ) +
  # Zona Amarilla: intersección d1 centrado + d2 alto
  annotate(
    "rect",
    xmin = -0.3, xmax = 0.3,
    ymin = 0.9, ymax = Inf,
    alpha = 0.15,
    fill = "yellow"
  ) +
  geom_point(aes(size = zona_outlier != "Normal", alpha = zona_outlier != "Normal")) +
  scale_size_manual(values = c("FALSE" = 2, "TRUE" = 4), guide = "none") +
  scale_alpha_manual(values = c("FALSE" = 0.6, "TRUE" = 1), guide = "none") +
  scale_color_manual(values = c("izquierda" = "#E74C3C", "derecha" = "#3498DB")) +
  geom_hline(yintercept = 0.9, linetype = "dashed", color = "black", alpha = 0.5) +
  geom_vline(xintercept = c(-0.3, 0.3), linetype = "dashed", color = "orange", alpha = 0.5) +
  # Etiquetas ZONA ROJA
  geom_text_repel(
    data = comparacion %>% filter(zona_outlier == "Roja"),
    aes(label = legislator),
    size = 3,
    box.padding = 0.5,
    max.overlaps = 20,
    color = "darkred",
    fontface = "bold"
  ) +
  # Etiquetas ZONA AMARILLA
  geom_text_repel(
    data = comparacion %>% filter(zona_outlier == "Amarilla"),
    aes(label = legislator),
    size = 3,
    box.padding = 0.5,
    max.overlaps = 20,
    color = "darkorange",
    fontface = "bold"
  ) +
  labs(
    title = "B-Call detecta volatilidad legislativa que W-NOMINATE no ve",
    subtitle = "Roja: Volátiles (d2 alto), pero W-NOMINATE no lo detecta | Amarilla: Centrados ideológicamente, pero sin cohesión en votación",
    x = "d1 (Ideología: izquierda/derecha)",
    y = "d2 (Cohesión: alto = volátil)",
    color = "Cluster"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

print(p1)
ggsave("results/scatter_d1_d2_dos_zonas.png", p1, width = 12, height = 8, dpi = 300, bg = "white")
cat("✓ Gráfico guardado: results/scatter_d1_d2_dos_zonas.png\n\n")

# ==============================================================================
# GRÁFICO 2: Histogramas comparativos
# ==============================================================================

hist_data <- comparacion %>%
  select(legislator, cluster, d2, coord2D) %>%
  tidyr::pivot_longer(
    cols = c(d2, coord2D),
    names_to = "metodo",
    values_to = "valor"
  ) %>%
  mutate(
    metodo_label = case_when(
      metodo == "d2" ~ "B-Call d2 (cohesión)",
      metodo == "coord2D" ~ "W-NOMINATE coord2D"
    )
  )

p2 <- ggplot(hist_data, aes(x = valor, fill = cluster)) +
  geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
  scale_fill_manual(values = c("izquierda" = "#E74C3C", "derecha" = "#3498DB")) +
  facet_wrap(~metodo_label, scales = "free_x") +
  geom_vline(
    data = data.frame(
      metodo_label = c("B-Call d2 (cohesión)", "W-NOMINATE coord2D"),
      xintercept = c(0.9, 0)
    ),
    aes(xintercept = xintercept),
    linetype = "dashed",
    color = "black",
    size = 0.8
  ) +
  labs(
    title = "Comparación Segunda Dimensión: B-Call d2 captura volatilidad",
    subtitle = "d2 > 0.9 identifica volátiles | coord2D de W-NOMINATE sin interpretación clara",
    x = "Valor",
    y = "Frecuencia",
    fill = "Cluster"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom",
    strip.text = element_text(face = "bold", size = 11)
  )

print(p2)
ggsave("results/histogramas_segunda_dimension.png", p2, width = 12, height = 6, dpi = 300, bg = "white")
cat("✓ Gráfico guardado: results/histogramas_segunda_dimension.png\n\n")

# ==============================================================================
# EXPORTAR RESULTADOS
# ==============================================================================

write.csv(outliers_zona_roja, "results/outliers_zona_roja.csv", row.names = FALSE)
cat("✓ Zona Roja guardada: results/outliers_zona_roja.csv\n")

write.csv(outliers_zona_amarilla, "results/outliers_zona_amarilla.csv", row.names = FALSE)
cat("✓ Zona Amarilla guardada: results/outliers_zona_amarilla.csv\n")

write.csv(outliers, "results/outliers_combinados.csv", row.names = FALSE)
cat("✓ Outliers combinados: results/outliers_combinados.csv\n\n")

# ==============================================================================
# CONCLUSIÓN
# ==============================================================================

cat(strrep("=", 80), "\n", sep = "")
cat("CONCLUSIÓN\n")
cat(strrep("=", 80), "\n\n", sep = "")

cat("B-Call captura DOS TIPOS de volatilidad que W-NOMINATE ignora:\n\n")

cat("ZONA ROJA:\n")
cat("  - W-NOMINATE los ve 'bipolares' (coord2D centrado)\n")
cat("  - B-Call detecta que son volátiles (d2 alto)\n\n")

cat("ZONA AMARILLA:\n")
cat("  - Centrados ideológicamente pero muy erráticos\n")
cat("  - B-Call lo detecta, W-NOMINATE no\n\n")

cat(sprintf("Total: %d zona roja, %d zona amarilla\n\n",
            nrow(outliers_zona_roja),
            nrow(outliers_zona_amarilla)))
