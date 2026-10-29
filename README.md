# Ejemplo B-Call: Cámara de Diputados Chile 2025

Análisis de votaciones de la Cámara de Diputados de Chile usando el paquete [bcall](https://github.com/bcallr/bcall).

Este repositorio contiene ejemplos prácticos para demostrar el uso del paquete `bcall` en el análisis de comportamiento legislativo.

**📖 [Ver tutorial completo con ejemplos y gráficos →](https://alcatruz.github.io/bcall-example/)**

## Datos

Los datos del ejemplo no están en el repositorio. Los scripts los leen desde una carpeta `data/` con estos archivos:

- `CHL-rollcall-2025.csv` - Matriz de votaciones
- `CHL-clustering-2025.csv` - Clustering manual (con errores para demostrar dependencia)
- `CHL-clustering-2025-CORREGIDO.csv` - Clustering corregido
- `df_wnominate.xlsx` - Datos W-NOMINATE para comparación

## Clonar Repositorio

```bash
git clone https://github.com/Alcatruz/bcall-example.git
cd bcall-example
```

## Uso

Sigue el tutorial completo en: **https://alcatruz.github.io/bcall-example/**

El tutorial incluye:
- Instalación de bcall
- Análisis automático (bcall_auto)
- Análisis manual (bcall) y su dependencia del etiquetado
- Comparación con W-NOMINATE
- Detección de volatilidad legislativa

## Más Información

- **Documentación del paquete**: [https://github.com/bcallr/bcall](https://github.com/bcallr/bcall)
- **Paper original**: Toro-Maureira, S., Reutter, J., Valenzuela, L., Alcatruz, D., & Valenzuela, M. (2025). B-Call: integrating ideological position and voting cohesion in legislative behavior. *Frontiers in Political Science*, 7, 1670089. [doi:10.3389/fpos.2025.1670089](https://doi.org/10.3389/fpos.2025.1670089)


## Contribuciones

¿Encontraste un error o tienes sugerencias? Abre un [issue](https://github.com/Alcatruz/bcall-example/issues) o un pull request.

---

**Nota**: Aunque el análisis automático funciona bien, se recomienda tener conocimiento del contexto político de las votaciones para una interpretación correcta de los resultados.
