---
title: "Scrapping_Ibex_35"
output: html_document
---

Scrapping ibex35 invertia.com y limpieza de datos

## Carga de datos

```{r message=FALSE, warning=FALSE, results=FALSE}
library(XML)
library(lubridate)
```

Url
```{r}
url <- 'http://www.invertia.com/mercados/bolsa/indices/ibex-35/acciones-ib011ibex35/1a'
```

Carga HTML de la url
```{r}
HTMLpage <- htmlTreeParse(url, useInternalNodes = T, encoding = "UTF-8")
```

Seleccionamos el nodo de la tabla de cotizaciones - clase HTML es "tb_fichas"
```{r}
table_node <- getNodeSet(HTMLpage, path = '//table[@class="tb_fichas"]')
```

Cargamos la tabla de cotizaciones
```{r}
ibex <- readHTMLTable(table_node[[1]], header = TRUE, as.data.frame = TRUE, stringsAsFactors = FALSE)
```

## Limpieza de datos

Eliminamos la columna 5 de barras del div. % y cambiamos los names del data.frame
```{r}
ibex[,5] <- NULL
names(ibex) <- c('Ticker', 'Ultimo', 'Dif', 'Dif_Porcentaje', 'Max',
                 'Min', 'Volumen', 'Capital', 'Yield_Porcentaje', 'PER', 'Fecha_Hora')
```

Ponemos NA en los valores n.a y n.d en caso de que los haya
```{r}
ibex[,2:ncol(ibex)] <- sapply(ibex[,2:ncol(ibex)], gsub, pattern='n\\.[a|d]', replacement = NA)
```

Eliminamos % del Yield
```{r}
ibex$Yield_Porcentaje <- gsub(ibex$Yield_Porcentaje, pattern = '%', replacement = '')
```

Cambiamos comas por puntos en los valores numéricos (excepto volumen que es un integer largo)
```{r}
valores_numericos <- !(colnames(ibex) %in% c('Ticker', 'Volumen', 'Fecha_Hora'))
ibex[, valores_numericos] <- sapply(ibex[, valores_numericos], gsub, pattern = ',', replacement = '.')
```

Cambiamos los tipos de los valores numéricos
```{r}
ibex[, valores_numericos] <- sapply(ibex[, valores_numericos], as.double)
```

Eliminamos los puntos de Volumen y cambiamos el tipo a integer
```{r}
ibex$Volumen <- as.integer(gsub(ibex$Volumen, pattern = '\\.', replacement = ''))
```

Obtenemos la fecha (Suponemos la fecha del PC local) para determinar si estamos en mercado o no

Los horarios del mercado español son: L-V De 9:00 h a 17:30 h
```{r}
fecha_hoy <- ymd_hms(Sys.time(), tz = "Europe/Madrid")

inicio_cotizacion <- fecha_hoy
hour(inicio_cotizacion) <- 9
minute(inicio_cotizacion) <- 0
second(inicio_cotizacion) <- 0

fin_cotizacion <- fecha_hoy
hour(fin_cotizacion) <- 17
minute(fin_cotizacion) <- 30
second(fin_cotizacion) <- 0
```

Condición para saber si está o no en mercado

*la función wday considera el día 1 como Domingo*

```{r}
if (wday(fecha_hoy) %in% c(2:6)){
  if (fecha_hoy  %within% interval(inicio_cotizacion, fin_cotizacion)){
    #En mercado - entre semana - Convertimos la fecha a formato dd/mm/aaaa hh:mm
    fecha_hoy <- format(fecha_hoy, "%d/%m/%Y")
    ibex$Fecha_Hora <- sapply(fecha_hoy, paste, ibex$Fecha, sep = ' ')
    
  } else { 
    #Fuera mercado - entre semana - Convertimos la fecha a formato dd/mm/aaaa   
    ibex$Fecha_Hora <- format(fecha_hoy, "%d/%m/%Y")
  }
  
  #Fuera mercado - fin de semana - dejamos la columna tal y como viene con formato dd/mm/aaaa

}
```

Ibex 35

```{r}
ibex
```

### Bibliografía:

* https://stackoverflow.com/questions/8965520/readhtmltable-and-utf-8-encoding
* https://stackoverflow.com/questions/6427061/parsing-html-tables-using-the-xml-rcurl-r-packages-without-using-the-readhtml
* http://www.endmemo.com/program/R/gsub.php
* https://stackoverflow.com/questions/8898501/grepl-search-within-a-string-that-does-not-contain-a-pattern
* http://www.endmemo.com/program/R/replace.php
* https://stackoverflow.com/questions/6987478/convert-a-month-abbreviation-to-a-numeric-month-in-r
* https://stackoverflow.com/questions/908550/python-getting-date-online
