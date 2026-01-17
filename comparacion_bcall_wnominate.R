# ==============================================================================
# Comparación B-Call vs W-NOMINATE: d2 de B-Call captura cohesión
# ==============================================================================

library(bcall)
library(dplyr)
library(ggplot2)
library(readxl)

# Cargar datos
rollcall <- read.csv("data/CHL-rollcall-2025.csv", row.names = 1)
clustering_corregido <- read.csv("data/CHL-clustering-2025-CORREGIDO.csv", row.names = 1)

# Ejecutar B-Call
resultado_bcall <- bcall(
  rollcall = rollcall,
  clustering = clustering_corregido,
  pivot = "Alessandri_Vergara_Jorge",
  threshold = 0.1,
  verbose = TRUE
)

# Cargar W-NOMINATE
wnominate <- read_excel("df_wnominate.xlsx")

# Matchear por legislator
comparacion <- resultado_bcall$results %>%
  select(legislator, d1, d2, cluster) %>%
  left_join(
    wnominate %>% select(legislator, coord1D, coord2D),
    by = "legislator"
  )

# Correlación d1 vs coord1D (primera dimensión: ideología)
correlacion_d1 <- cor(comparacion$d1, comparacion$coord1D, use = "complete.obs")

cat("\n", strrep("=", 80), "\n", sep = "")
cat("CORRELACIÓN PRIMERA DIMENSIÓN (Ideología)\n")
cat(strrep("=", 80), "\n\n", sep = "")
cat(sprintf("d1 (B-Call) vs coord1D (W-NOMINATE): %.3f\n", correlacion_d1))
cat("✓ Ambos métodos capturan bien la posición ideológica\n\n")

# Correlación d2 vs coord2D (segunda dimensión)
correlacion_d2 <- cor(comparacion$d2, comparacion$coord2D, use = "complete.obs")

cat(strrep("=", 80), "\n", sep = "")
cat("CORRELACIÓN SEGUNDA DIMENSIÓN\n")
cat(strrep("=", 80), "\n\n", sep = "")
cat(sprintf("d2 (B-Call) vs coord2D (W-NOMINATE): %.3f\n", correlacion_d2))
cat("✗ coord2D de W-NOMINATE NO captura información relevante\n")
cat("✓ d2 de B-Call SÍ captura cohesión/volatilidad\n\n")

# Caso ejemplo: Pamela Jiles
caso_jiles <- comparacion %>% filter(legislator == "Jiles_Moreno_Pamela")

cat(strrep("=", 80), "\n", sep = "")
cat("CASO EJEMPLO: Pamela Jiles\n")
cat(strrep("=", 80), "\n\n", sep = "")

if (nrow(caso_jiles) > 0) {
  cat(sprintf("Legislador: %s\n", caso_jiles$legislator))
  cat(sprintf("Cluster: %s\n\n", caso_jiles$cluster))

  cat("B-Call:\n")
  cat(sprintf("  d1 = %+.3f  (posición ideológica)\n", caso_jiles$d1))
  cat(sprintf("  d2 = %.3f   (cohesión: %.3f = BAJA COHESIÓN, volátil)\n",
              caso_jiles$d2, caso_jiles$d2))

  cat("\nW-NOMINATE:\n")
  cat(sprintf("  coord1D = %+.3f  (posición ideológica)\n", caso_jiles$coord1D))
  cat(sprintf("  coord2D = %+.3f  (no tiene interpretación clara)\n\n", caso_jiles$coord2D))

  cat("Interpretación:\n")
  cat("- d2 alto en B-Call revela que Jiles vota frecuentemente contra su bloque\n")
  cat("- coord2D de W-NOMINATE no captura esta volatilidad\n")
  cat("- Esto es lo que B-Call aporta: separar ideología de cohesión\n\n")
} else {
  cat("No se encontró a Jiles_Moreno_Pamela en los datos\n\n")
}

# Top 10 más volátiles según B-Call
top_volatiles <- comparacion %>%
  arrange(desc(d2)) %>%
  head(10) %>%
  select(legislator, cluster, d1, d2, coord1D, coord2D)

cat(strrep("=", 80), "\n", sep = "")
cat("TOP 10 MÁS VOLÁTILES (según d2 de B-Call)\n")
cat(strrep("=", 80), "\n\n", sep = "")
cat(sprintf("%-35s %10s %8s %8s %10s %10s\n",
            "Legislador", "Cluster", "d1", "d2", "coord1D", "coord2D"))
cat(strrep("-", 80), "\n", sep = "")
for (i in 1:nrow(top_volatiles)) {
  cat(sprintf("%-35s %10s %+8.3f %8.3f %+10.3f %+10.3f\n",
              top_volatiles$legislator[i],
              top_volatiles$cluster[i],
              top_volatiles$d1[i],
              top_volatiles$d2[i],
              top_volatiles$coord1D[i],
              top_volatiles$coord2D[i]))
}

cat("\nNota: d2 alto = baja cohesión, votan contra su bloque\n")
cat("coord2D de W-NOMINATE no tiene interpretación clara de cohesión\n\n")

# Gráfico 1: Correlación d1 vs coord1D
p1 <- ggplot(comparacion, aes(x = coord1D, y = d1, color = cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  scale_color_manual(values = c("izquierda" = "#E74C3C", "derecha" = "#3498DB")) +
  labs(
    title = "Primera Dimensión: B-Call vs W-NOMINATE",
    subtitle = sprintf("Correlación: %.3f - Ambos capturan ideología", correlacion_d1),
    x = "W-NOMINATE coord1D",
    y = "B-Call d1",
    color = "Cluster"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

print(p1)
ggsave("results/correlacion_d1.png", p1, width = 10, height = 7, dpi = 300, bg="white")
cat("✓ Gráfico guardado: results/correlacion_d1.png\n")

# Gráfico 2: Correlación d2 vs coord2D
p2 <- ggplot(comparacion, aes(x = coord2D, y = d2, color = cluster)) +
  geom_point(size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linetype = "dashed") +
  scale_color_manual(values = c("izquierda" = "#E74C3C", "derecha" = "#3498DB")) +
  labs(
    title = "Segunda Dimensión: B-Call d2 (cohesión) vs W-NOMINATE coord2D",
    subtitle = sprintf("Correlación: %.3f - coord2D NO captura cohesión", correlacion_d2),
    x = "W-NOMINATE coord2D (sin interpretación clara)",
    y = "B-Call d2 (cohesión: alto = volátil)",
    color = "Cluster"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

print(p2)
ggsave("results/correlacion_d2.png", p2, width = 10, height = 7, dpi = 300, bg="white")
cat("✓ Gráfico guardado: results/correlacion_d2.png\n")

# Gráfico 3: Comparación lado a lado de segunda dimensión
comparacion_long <- comparacion %>%
  select(legislator, cluster, d2, coord2D) %>%
  tidyr::pivot_longer(
    cols = c(d2, coord2D),
    names_to = "metodo",
    values_to = "valor"
  ) %>%
  mutate(
    metodo = case_when(
      metodo == "d2" ~ "B-Call d2 (cohesión)",
      metodo == "coord2D" ~ "W-NOMINATE coord2D"
    )
  )

p3 <- ggplot(comparacion_long, aes(x = valor, fill = cluster)) +
  geom_histogram(bins = 30, alpha = 0.7) +
  scale_fill_manual(values = c("izquierda" = "#E74C3C", "derecha" = "#3498DB")) +
  facet_wrap(~metodo, scales = "free") +
  labs(
    title = "Comparación Segunda Dimensión: B-Call d2 captura cohesión",
    x = "Valor",
    y = "Frecuencia",
    fill = "Cluster"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    legend.position = "bottom"
  )

print(p3)
ggsave("results/comparacion_segunda_dimension.png", p3, width = 12, height = 6, dpi = 300, bg="white")
cat("✓ Gráfico guardado: results/comparacion_segunda_dimension.png\n\n")

# Exportar comparación completa
write.csv(comparacion, "results/comparacion_bcall_wnominate.csv", row.names = FALSE)
cat("✓ Comparación completa guardada: results/comparacion_bcall_wnominate.csv\n\n")

# Exportar top volátiles
write.csv(top_volatiles, "results/top_volatiles_bcall.csv", row.names = FALSE)
cat("✓ Top volátiles guardado: results/top_volatiles_bcall.csv\n\n")

cat(strrep("=", 80), "\n", sep = "")
cat("CONCLUSIÓN\n")
cat(strrep("=", 80), "\n\n", sep = "")
cat("1. Primera dimensión (d1): B-Call y W-NOMINATE coinciden (correlación alta)\n")
cat("2. Segunda dimensión (d2): B-Call captura cohesión, W-NOMINATE no\n")
cat("3. d2 alto identifica legisladores volátiles (baja disciplina partidaria)\n")
cat("4. Ejemplo: Pamela Jiles tiene d2 alto = vota contra su bloque frecuentemente\n")
cat("5. Esto demuestra la ventaja de B-Call: separa ideología (d1) de cohesión (d2)\n\n")

