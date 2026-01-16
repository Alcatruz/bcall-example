# Ejemplo B-Call: Cámara de Diputados Chile 2025

Análisis de votaciones de la Cámara de Diputados de Chile usando el paquete [bcall](https://github.com/bcallr/bcall).

Este repositorio contiene datos reales y ejemplos prácticos para demostrar el uso del paquete `bcall` en el análisis de comportamiento legislativo.

## Datos Disponibles

Este repositorio incluye datos de votaciones de la Cámara de Diputados de Chile del año 2025:

- **[CHL-rollcall-2025.csv](data/CHL-rollcall-2025.csv)** (303 KB)
  - Matriz de votaciones: diputados en filas, votaciones en columnas
  - Valores: `1` (Sí), `-1` (No), `0` (Abstención), `NA` (Ausente)
  - Formato listo para usar con `bcall`

- **[CHL-clustering-2025.csv](data/CHL-clustering-2025.csv)** (5 KB)
  - Clasificación manual izquierda/derecha (ejemplo ilustrativo con algunos errores intencionales)
  - Para demostrar importancia del etiquetado previo

- **[CHL-clustering-2025-CORREGIDO.csv](data/CHL-clustering-2025-CORREGIDO.csv)** (5 KB)
  - Clasificación corregida basada en comportamiento de votación
  - Para análisis con clustering confiable

## Inicio Rápido

**¿Quieres probar rápidamente?** Descarga y ejecuta el script completo:

```r
# Descargar el script
download.file(
  "https://raw.githubusercontent.com/Alcatruz/bcall-example/main/ejemplo_bcall_chile.R",
  "ejemplo_bcall_chile.R"
)

# Ejecutar
source("ejemplo_bcall_chile.R")
```

El script [`ejemplo_bcall_chile.R`](ejemplo_bcall_chile.R) incluye:
- Instalación automática del paquete
- Carga de datos
- Análisis automático y manual
- Visualizaciones
- Exportación de resultados
- Análisis exploratorio completo

## Descargar Datos

Puedes descargar los datos de dos formas:

1. **Clonar el repositorio completo:**
   ```bash
   git clone https://github.com/Alcatruz/bcall-example.git
   cd bcall-example
   ```

2. **Descargar archivos individuales:**
   - Click en el archivo que quieras → botón "Raw" → botón derecho "Guardar como..."

## Instalación

Primero, instala el paquete `bcall` desde GitHub:

```r
# Instalar devtools si no lo tienes
install.packages("devtools")

# Instalar bcall
devtools::install_github("bcallr/bcall")

# Cargar el paquete
library(bcall)
```

## Ejemplo 1: Análisis Automático

El análisis automático detecta los grupos ideológicos sin necesidad de clasificación previa:

```r
# Cargar datos de votaciones
rollcall <- read.csv("data/CHL-rollcall-2025.csv", row.names = 1)

# Ejecutar análisis B-Call con clustering automático
resultado_auto <- bcall_auto(
  rollcall = rollcall,
  distance_method = 1,    # 1 = Manhattan, 2 = Euclidean
  threshold = 0.1,        # Mínimo 10% participación
  verbose = TRUE
)

# Ver primeros resultados
head(resultado_auto$results)
```

**Resultado:**
```
                              d1          d2 auto_cluster          legislator
Barrios_Oteíza_Arturo   0.4523156  0.08234567        right   Barrios_Oteíza_Arturo
Acevedo_Sáez_María      0.4312891  0.09123456        right   Acevedo_Sáez_María
...
```

### Visualizar Resultados

```r
# Gráfico estático
plot_bcall_analysis(
  resultado_auto,
  title = "Cámara de Diputados Chile 2025",
  show_names = FALSE
)

# Gráfico interactivo (con tooltips)
plot_bcall_analysis_interactive(resultado_auto)
```

**Resultado del análisis automático:**

![B-Call Análisis Automático](results/plot_auto.png)

*Figura 1: Análisis B-Call con clustering automático. El eje d1 representa la posición ideológica (izquierda-derecha), mientras que d2 muestra la cohesión política de cada diputado.*

### Gráfico Interactivo

**[Explorar gráfico interactivo en tu navegador](https://alcatruz.github.io/bcall-example/results/plot_interactive.html)**

Pasa el mouse sobre los puntos para ver:
- Nombre del diputado
- Posición ideológica (d1)
- Cohesión política (d2)
- Cluster asignado

Puedes hacer zoom, pan y explorar los datos en detalle.

## Ejemplo 2: Con Clustering Manual

Si tienes clasificaciones previas (ej. izquierda/derecha por coalición), puedes usarlas:

```r
# Cargar clustering manual
clustering <- read.csv("data/CHL-clustering-2025.csv", row.names = 1)

# Ver estructura
head(clustering)
#                        cluster
# Soto_Ferrada_Leonardo  izquierda
# Trisotti_Martínez_Renzo derecha
# ...

# Seleccionar un diputado de referencia (del cluster "derecha")
# Este será el pivot que define la orientación del eje d1
pivot_legislator <- "Alessandri_Vergara_Jorge"

# Ejecutar análisis con clustering predefinido
resultado_manual <- bcall(
  rollcall = rollcall,
  clustering = clustering,
  pivot = pivot_legislator,
  threshold = 0.1,
  verbose = TRUE
)

# Ver resultados
head(resultado_manual$results)
```

### Visualizar con Clustering Manual

```r
# El paquete detecta automáticamente los nombres en español
plot_bcall_analysis(
  resultado_manual,
  title = "Análisis con Clustering Manual",
  color_by = "auto"  # Detecta automáticamente si es 'cluster' o 'auto_cluster'
)
```

**Resultado del análisis manual:**

![B-Call Análisis Manual](results/plot_manual.png)

*Figura 2: Análisis B-Call con clustering manual (izquierda/derecha). Los colores muestran la clasificación política predefinida de cada diputado.*

## Ejemplo Pedagógico: Importancia del Etiquetado Previo

Este repositorio incluye un **ejemplo ilustrativo** que demuestra cómo el análisis B-Call manual **depende de la calidad del etiquetado previo** proporcionado por el investigador.

### 📊 Visualización Comparativa Interactiva

**[Ver tutorial completo con gráficos comparativos →](https://alcatruz.github.io/bcall-example/)**

El tutorial muestra lado a lado:
- Análisis con clustering original (con etiquetado incorrecto intencional)
- Análisis con clustering corregido (basado en comportamiento real)
- Código R completo para reproducir ambos análisis

### Dos Versiones del Clustering

1. **[CHL-clustering-2025.csv](data/CHL-clustering-2025.csv)** - Con errores intencionales (ilustrativo)
2. **[CHL-clustering-2025-CORREGIDO.csv](data/CHL-clustering-2025-CORREGIDO.csv)** - Basado en comportamiento real

### Ejecutar Comparación

```r
# Ejecutar análisis comparativo completo
source("comparacion_etiquetado.R")
```

Esto ilustra cómo un etiquetado incorrecto puede hacer que el análisis muestre:
- 23 diputados aparentemente votando contra su clasificación
- Coherencia de solo 85% vs 98% con etiquetado correcto
- "Tránsfugas fantasma" que en realidad son errores de clasificación previa

### Conclusión del Ejemplo

El análisis B-Call manual refleja el etiquetado que proporciona el investigador. Si el etiquetado es incorrecto, el análisis mostrará inconsistencias aparentes.

---

## Interpretar Resultados

### Dimensión d1: Posición Ideológica
- **Valores positivos**: Posiciones de derecha
- **Valores negativos**: Posiciones de izquierda
- **Magnitud**: Distancia del centro político

### Dimensión d2: Cohesión Política
- **Valores bajos** (cerca de 0): Alta cohesión - vota consistentemente con su bloque
- **Valores altos**: Baja cohesión - vota frecuentemente contra su bloque

### Ejemplo de Interpretación

```r
# Encontrar diputados más de izquierda
library(dplyr)
resultado_auto$results %>%
  arrange(d1) %>%
  head(5)

# Encontrar diputados más de derecha
resultado_auto$results %>%
  arrange(desc(d1)) %>%
  head(5)

# Encontrar diputados más cohesivos (disciplinados)
resultado_auto$results %>%
  arrange(d2) %>%
  head(5)

# Encontrar diputados menos cohesivos (independientes)
resultado_auto$results %>%
  arrange(desc(d2)) %>%
  head(5)
```

## Casos de Uso

Este análisis es útil para:

1. **Ciencia Política**: Estudiar comportamiento legislativo y disciplina partidaria
2. **Periodismo de Datos**: Visualizar posiciones reales vs. declaradas
3. **Investigación Académica**: Analizar evolución ideológica en el tiempo
4. **Análisis de Coaliciones**: Identificar fracturas y alianzas implícitas

## Más Información

- **Documentación del paquete**: [https://github.com/bcallr/bcall](https://github.com/bcallr/bcall)
- **Paper original**: Toro-Maureira, S., Reutter, J., Valenzuela, L., Alcatruz, D., & Valenzuela, M. (2025). B-Call: integrating ideological position and voting cohesion in legislative behavior. *Frontiers in Political Science*, 7, 1670089. [doi:10.3389/fpos.2025.1670089](https://doi.org/10.3389/fpos.2025.1670089)


## Contribuciones

¿Encontraste un error o tienes sugerencias? Abre un [issue](https://github.com/Alcatruz/bcall-example/issues) o un pull request.

---

**Nota**: Aunque el análisis automático funciona bien, se recomienda tener conocimiento del contexto político de las votaciones para una interpretación correcta de los resultados.
