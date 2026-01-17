library(pscl)

# ============================================================================
# IDEAL: Chile Congreso 2025
# Método: Bayesian IRT
# Polaridades: Catalina Pérez (FA - izquierda) vs Alessandri (derecha)
# ============================================================================

# 1. CARGAR DATOS
df <- read.csv('data/CHL-rollcall-2025.csv', row.names = 1)
cat("✓ Datos cargados:", nrow(df), "legisladores x", ncol(df), "votaciones\n\n")

# 2. CREAR ROLLCALL
votes <- as.matrix(df)
legislators <- rownames(df)

rc <- rollcall(votes,
               yea = c(1),
               nay = c(-1, 0),
               legis.names = legislators)

# 3. IDENTIFICAR POLARIDADES
idx_perez <- which(rownames(df) == "Pérez_Salinas_Catalina")
idx_alessandri <- which(rownames(df) == "Alessandri_Vergara_Jorge")

cat("Polaridades identificadas:\n")
cat("  [", idx_perez, "] Catalina Pérez (FA - izquierda)\n")
cat("  [", idx_alessandri, "] Jorge Alessandri (derecha)\n\n")

# 4. IDEAL 1D
cat("Ejecutando IDEAL 1D (Bayesian IRT)...\n")
cat("(Esto toma 1-2 minutos)\n\n")

ideal_1d <- ideal(rc,
                  d = 1,
                  normalize = TRUE,
                  store.item = TRUE,
                  maxiter = 260000,
                  burnin = 10000,
                  thin = 100)

ideal_pts_1d <- ideal_1d$xbar

results_1d <- data.frame(
    legislator = rownames(ideal_pts_1d),
    ideal_point = as.numeric(ideal_pts_1d),
    stringsAsFactors = FALSE
)

# Invertir si es necesario
perez_pos <- results_1d$ideal_point[results_1d$legislator == "Pérez_Salinas_Catalina"]
alessandri_pos <- results_1d$ideal_point[results_1d$legislator == "Alessandri_Vergara_Jorge"]

if(perez_pos > alessandri_pos) {
    results_1d$ideal_point <- -results_1d$ideal_point
}

results_1d <- results_1d[order(results_1d$ideal_point), ]

write.csv(results_1d, file = 'CHL-ideal-1d.csv', row.names = FALSE)

cat("✓ IDEAL 1D completado\n")
cat("  Range:", round(min(results_1d$ideal_point), 4), "a",
    round(max(results_1d$ideal_point), 4), "\n")
cat("  Resultados guardados en: CHL-ideal-1d.csv\n\n")

# 5. IDEAL 2D
cat("Ejecutando IDEAL 2D (Bayesian IRT)...\n")
cat("(Esto toma 2-3 minutos)\n\n")

ideal_2d <- ideal(rc,
                  d = 2,
                  normalize = TRUE,
                  store.item = TRUE,
                  maxiter = 260000,
                  burnin = 10000,
                  thin = 100)

ideal_pts_2d <- ideal_2d$xbar

results_2d <- data.frame(
    legislator = rownames(ideal_pts_2d),
    dim1 = as.numeric(ideal_pts_2d[, 1]),
    dim2 = as.numeric(ideal_pts_2d[, 2]),
    stringsAsFactors = FALSE
)

# Invertir dimensión 1 si es necesario
perez_pos_2d <- results_2d$dim1[results_2d$legislator == "Pérez_Salinas_Catalina"]
alessandri_pos_2d <- results_2d$dim1[results_2d$legislator == "Alessandri_Vergara_Jorge"]

if(perez_pos_2d > alessandri_pos_2d) {
    results_2d$dim1 <- -results_2d$dim1
}

write.csv(results_2d, file = 'CHL-ideal-2d.csv', row.names = FALSE)

cat("✓ IDEAL 2D completado\n")
cat("  Dim 1 range:", round(min(results_2d$dim1), 4), "a",
    round(max(results_2d$dim1), 4), "\n")
cat("  Dim 2 range:", round(min(results_2d$dim2), 4), "a",
    round(max(results_2d$dim2), 4), "\n")
cat("  Resultados guardados en: CHL-ideal-2d.csv\n\n")

# 6. RESUMEN
cat("=============================================================================\n")
cat("TOP 10 IZQUIERDISTAS (1D)\n")
cat("=============================================================================\n")
print(head(results_1d, 10), row.names = FALSE)

cat("\n")
cat("=============================================================================\n")
cat("TOP 10 DERECHISTAS (1D)\n")
cat("=============================================================================\n")
print(tail(results_1d, 10), row.names = FALSE)

cat("\n")
cat("✓ Análisis completado\n")
