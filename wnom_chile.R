library(pscl)
library(wnominate)
# ============================================================================
# W-NOMINATE: Chile Congreso 2025
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

# 4. W-NOMINATE 1D
cat("Ejecutando W-NOMINATE 1D...\n")

scores_wnom_1d <- wnominate(rc,
                            polarity = c(idx_alessandri, idx_perez))

dxs <- scores_wnom_1d[["legislators"]]

results_1d <- data.frame(
    legislator = rownames(scores_wnom_1d$legislators),
    ideal_point = scores_wnom_1d$legislators[, 1],
    gc = scores_wnom_1d$legislators[, 2],
    stringsAsFactors = FALSE
)


results_1d <- results_1d[order(results_1d$ideal_point), ]

write.csv(results_1d, file = 'CHL-wnom-1d.csv', row.names = FALSE)

cat("✓ W-NOMINATE 1D completado\n")
cat("  GOF:", round(scores_wnom_1d$gof, 4), "\n")
cat("  Resultados guardados en: CHL-wnom-1d.csv\n\n")

# 5. W-NOMINATE 2D
cat("Ejecutando W-NOMINATE 2D...\n")
scores_wnom_2d <- wnominate(rc,
                            dims = 2,
                            polarity = c(idx_perez, idx_alessandri))

results_2d <- data.frame(
    legislator = rownames(scores_wnom_2d$legislators),
    dim1 = scores_wnom_2d$legislators[, 1],
    dim2 = scores_wnom_2d$legislators[, 2],
    gc = scores_wnom_2d$legislators[, 3],
    stringsAsFactors = FALSE
)

write.csv(results_2d, file = 'CHL-wnom-2d.csv', row.names = FALSE)

cat("✓ W-NOMINATE 2D completado\n")
cat("  GOF:", round(scores_wnom_2d$gof, 4), "\n")
cat("  Resultados guardados en: CHL-wnom-2d.csv\n\n")

# 6. RESUMEN
cat("=============================================================================\n")
cat("TOP 10 IZQUIERDISTAS (1D)\n")
cat("=============================================================================\n")
print(head(results_1d, 10))

cat("\n")
cat("=============================================================================\n")
cat("TOP 10 DERECHISTAS (1D)\n")
cat("=============================================================================\n")
print(tail(results_1d, 10))

cat("\n")
cat("✓ Análisis completado\n")
