# Compara os resumos gerados pelos Rmd (saidas/<câncer>/resumo_<câncer>.csv)
# com os valores calculados em Python (conferencia/valores_esperados.csv).
# Rode na pasta do projeto depois de knitar os 4 Rmd:   source("conferencia/comparar.R")
library(tidyverse)

esperado <- read_csv("conferencia/valores_esperados.csv", show_col_types = FALSE)
obtido <- map_dfr(esperado$cancer, function(id) {
  arquivo <- file.path("saidas", id, paste0("resumo_", id, ".csv"))
  if (!file.exists(arquivo)) stop("Não encontrado: ", arquivo, ". Knite o Rmd desse câncer antes.")
  read_csv(arquivo, show_col_types = FALSE)
})

colunas <- setdiff(intersect(names(esperado), names(obtido)), "cancer")
tolerancia <- if_else(colunas %in% c("s12", "s36", "s60"), 0.0015,
              if_else(colunas %in% c("pct_ate60", "km_mediana_meses", "maxfu_meses"), 0.11, 0))
names(tolerancia) <- colunas

comparacao <- full_join(
  esperado %>% select(cancer, all_of(colunas)) %>% pivot_longer(-cancer, names_to = "indicador", values_to = "python"),
  obtido   %>% select(cancer, all_of(colunas)) %>% pivot_longer(-cancer, names_to = "indicador", values_to = "r"),
  by = c("cancer", "indicador")
) %>%
  mutate(diferenca = r - python,
         ok = (is.na(python) & is.na(r)) | (!is.na(diferenca) & abs(diferenca) <= tolerancia[indicador] + 1e-9))

divergencias <- filter(comparacao, !ok)
cat(nrow(comparacao), "indicadores comparados;", nrow(divergencias), "divergência(s).\n")
if (nrow(divergencias) > 0) print(divergencias, n = Inf) else cat("R e Python concordam em todos os indicadores.\n")
