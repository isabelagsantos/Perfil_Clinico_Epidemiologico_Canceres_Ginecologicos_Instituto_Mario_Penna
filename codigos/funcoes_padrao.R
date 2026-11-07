# ==============================================================================
# funcoes_padrao.R
# Tudo que é COMUM aos quatro Rmd (vulva, ccu, endometrio, co) fica aqui:
#   1. Ajustes gerais da análise (janela, prazo da lei, filtro SUS...)
#   2. Rótulos dos códigos do RHC (conforme a Ficha de Registro de Tumor do INCA)
#   3. Visual padrão (cores e tema dos gráficos)
#   4. Funções que evitam repetir código (contar, tabela, gráfico, painel, prazo, sobrevida)
#   5. Exportação: toda tabela, figura e painel é gravado em saidas/<câncer>/
#
# Para mudar algo em TODOS os cânceres de uma vez, mude aqui.
# Para mudar algo de UM câncer, mude no bloco "Configuração deste câncer" do Rmd dele.
# ==============================================================================

library(tidyverse)   # dplyr, ggplot2, stringr, lubridate, readr, readxl...
library(knitr)       # kable(): cria a tabela
library(kableExtra)  # kable_styling(), row_spec(), footnote(): deixa a tabela bonita
library(patchwork)   # junta vários gráficos em um painel
library(survival)    # Kaplan-Meier


# ------------------------------------------------------------------------------
# 1. AJUSTES GERAIS DA ANÁLISE
# ------------------------------------------------------------------------------

pasta_dados       <- "dados"                 # onde ficam os .xlsx do RHC e os CSV de referência
janela_inicio     <- as.Date("2019-01-01")   # diagnóstico E início do tratamento dentro da janela
janela_fim        <- as.Date("2024-12-31")
uf_residencia     <- "MG"
prazo_lei         <- 60                      # Lei 12.732/2012: 60 dias do diagnóstico ao início do tratamento

# Critérios da coorte (TRUE = aplica o filtro; o fluxo no relatório mostra o efeito de cada um)
apenas_sus        <- TRUE    # CUSTRATAMTUMOR = 1 (tratamento custeado pelo SUS). O estudo é sobre pacientes SUS.
apenas_analiticos <- FALSE   # ANALITIC = 1 (caso analítico, critério padrão do INCA). Decisão da equipe.

# Sobrevida: o export do RHC não traz a data do último contato.
# Quem não tem óbito registrado é "censurada" nesta data.
data_corte        <- as.Date("2024-12-31")

# Privacidade (LGPD): contagens de 1 a (min_celula - 1) aparecem como "<5". Use 0 para desligar.
min_celula        <- 5

# Exportação (tudo vai para saidas/<câncer>/). CSV, HTML, figuras e painéis sempre são gravados.
salvar_png_tabelas <- TRUE   # PNG de cada tabela: precisa de webshot2 + Chrome; se falhar, grava só CSV e HTML
salvar_xlsx        <- TRUE   # um Excel por câncer com todas as tabelas (precisa de openxlsx; se faltar, pula)
semente           <- 2024    # para testes com simulação (reprodutível)

# Arquivos de referência (ficam em "dados/")
arq_mesorregioes  <- "municipios_mg_mesorregioes_codigo_ibge_2025.csv"   # município -> mesorregião (IBGE)
arq_dtb           <- "dtb_municipios.csv"                                # nomes oficiais dos municípios (DTB/IBGE)

fonte_dados <- "Fonte: Registro Hospitalar de Câncer (RHC) - Instituto Mário Penna/Hospital Luxemburgo, 2019-2024."


# ------------------------------------------------------------------------------
# 2. RÓTULOS DO RHC
#    Fonte: INCA. Ficha de Registro de Tumor e "Registros Hospitalares de Câncer:
#    planejamento e gestão", 2ª ed., 2010. (o número do item da ficha está ao lado)
# ------------------------------------------------------------------------------

rotulos_raca <- c(                                  # item 10
  "1" = "Branca", "2" = "Preta", "3" = "Amarela", "4" = "Parda", "5" = "Indígena", "9" = "Sem informação")

rotulos_escol <- c(                                 # item 11
  "1" = "Nenhuma", "2" = "Fundamental incompleto", "3" = "Fundamental completo", "4" = "Nível médio",
  "5" = "Nível superior incompleto", "6" = "Nível superior completo", "9" = "Sem informação")

rotulos_diagant <- c(                               # item 23
  "1" = "Sem diagnóstico / sem tratamento", "2" = "Com diagnóstico / sem tratamento",
  "3" = "Com diagnóstico / com tratamento", "4" = "Outros", "9" = "Sem informação")

rotulos_base <- c(                                  # item 24
  "1" = "Clínica", "2" = "Pesquisa clínica", "3" = "Exame por imagem", "4" = "Marcadores tumorais",
  "5" = "Citologia", "6" = "Histologia da metástase", "7" = "Histologia do tumor primário", "9" = "Sem informação")

rotulos_tratamento <- c(                            # item 34
  "1" = "Nenhum", "2" = "Cirurgia", "3" = "Radioterapia", "4" = "Quimioterapia", "5" = "Hormonioterapia",
  "6" = "Transplante de medula óssea", "7" = "Imunoterapia", "8" = "Outras", "9" = "Sem informação")

rotulos_resultado <- c(                             # item 35
  "1" = "Sem evidência da doença (remissão completa)", "2" = "Remissão parcial", "3" = "Doença estável",
  "4" = "Doença em progressão", "5" = "Suporte terapêutico oncológico", "6" = "Óbito",
  "8" = "Não se aplica", "9" = "Sem informação")

# Item 37 (óbito por câncer). Na ficha: 1 = Sim, 2 = Não, 9 = Ignorado.
# No arquivo exportado aparece também o código 0 nas pacientes SEM data de óbito.
rotulos_obito_cancer <- c(
  "0" = "Sem óbito registrado", "1" = "Óbito por câncer", "2" = "Óbito por outra causa", "9" = "Ignorado")

rotulos_estcivil <- c(                              # item 41
  "1" = "Solteira", "2" = "Casada", "3" = "Viúva", "4" = "Separada judicialmente",
  "5" = "União consensual", "9" = "Sem informação")

rotulos_histfam <- c("1" = "Sim", "2" = "Não", "9" = "Sem informação")    # item 43

rotulos_habito <- c(                                # itens 44 (álcool) e 45 (tabaco)
  "1" = "Nunca", "2" = "Ex-consumidor", "3" = "Sim", "4" = "Não avaliado",
  "8" = "Não se aplica", "9" = "Sem informação")

rotulos_origem <- c(                                # item 46
  "1" = "SUS", "2" = "Não SUS", "3" = "Veio por conta própria", "8" = "Não se aplica", "9" = "Sem informação")

rotulos_custeio <- c(                               # itens 52 (diagnóstico) e 53 (tratamento)
  "1" = "Público (SUS)", "2" = "Plano de saúde", "3" = "Particular", "4" = "Outros",
  "8" = "Não se aplica", "9" = "Sem informação")

# Mesorregiões do IBGE em MG: o CSV vem sem acento; aqui voltam com a grafia oficial
rotulos_mesorregiao <- c(
  "Noroeste de Minas"                = "Noroeste de Minas",
  "Norte de Minas"                   = "Norte de Minas",
  "Jequitinhonha"                    = "Jequitinhonha",
  "Vale do Mucuri"                   = "Vale do Mucuri",
  "Triangulo Mineiro Alto Paranaiba" = "Triângulo Mineiro e Alto Paranaíba",
  "Central Mineira"                  = "Central Mineira",
  "Metropolitana de Belo Horizonte"  = "Metropolitana de Belo Horizonte",
  "Vale do Rio Doce"                 = "Vale do Rio Doce",
  "Oeste de Minas"                   = "Oeste de Minas",
  "Sul Sudoeste de Minas"            = "Sul e Sudoeste de Minas",
  "Campo das Vertentes"              = "Campo das Vertentes",
  "Zona da Mata"                     = "Zona da Mata")

texto_nao_mg <- "Não identificada (município fora de MG)"


# ------------------------------------------------------------------------------
# 3. VISUAL PADRÃO (mude as cores aqui e tudo muda)
# ------------------------------------------------------------------------------

cor_principal   <- "#B03060"   # rosa-vinho
cor_secundaria  <- "#2A6F97"   # azul
cor_neutra      <- "#6B7280"   # cinza
cor_texto       <- "#1F2937"
cor_listra      <- "#F7EEF2"   # linhas alternadas das tabelas
paleta          <- c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9", "#D55E00", "#F0E442", "#000000")

tema_artigo <- function(tamanho = 12) {
  theme_minimal(base_size = tamanho) +
    theme(
      plot.title = element_text(face = "bold", color = cor_texto),
      plot.subtitle = element_text(color = cor_neutra),
      plot.caption = element_text(color = cor_neutra, hjust = 0, size = rel(0.8)),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}
theme_set(tema_artigo())

options(knitr.kable.NA = "-")   # valores ausentes aparecem como "-" nas tabelas


# ------------------------------------------------------------------------------
# 4. FUNÇÕES
# ------------------------------------------------------------------------------

# ---- formatação em português (vírgula decimal, ponto de milhar) ----
fmt_n   <- function(x) ifelse(is.na(x), "-", formatC(x, format = "d", big.mark = ".", decimal.mark = ","))
fmt_num <- function(x, casas = 1) ifelse(is.na(x), "-", formatC(x, format = "f", digits = casas, decimal.mark = ","))
fmt_pct <- function(x, casas = 1) ifelse(is.na(x), "-", paste0(fmt_num(x, casas), "%"))
fmt_p   <- function(p) ifelse(is.na(p), "-", ifelse(p < 0.001, "<0,001", fmt_num(p, 3)))

# TRUE quando a contagem deve ser escondida (LGPD)
celula_pequena <- function(n) min_celula > 0 & n > 0 & n < min_celula

# ---- localizar arquivo (procura em dados/ e na pasta atual) ----
# nome: nome exato; padrao: expressão para achar o arquivo se o nome for um pouco diferente
achar_arquivo <- function(nome, padrao = NULL) {
  # Procura em dados/ ao lado do Rmd e também na pasta de cima (caso os Rmd estejam em uma subpasta, ex.: codigos/)
  pastas <- c(pasta_dados, ".", file.path(pasta_dados, "referencia"),
              file.path("..", pasta_dados), "..", file.path("..", pasta_dados, "referencia"))
  for (p in pastas) {
    f <- file.path(p, nome)
    if (file.exists(f)) return(f)
  }
  if (!is.null(padrao)) {
    for (p in pastas) {
      if (dir.exists(p)) {
        achados <- list.files(p, pattern = padrao, full.names = TRUE, ignore.case = TRUE)
        if (length(achados) >= 1) return(achados[1])
      }
    }
  }
  stop("Arquivo não encontrado: ", nome,
       "\nPastas procuradas: ", paste(normalizePath(pastas, mustWork = FALSE), collapse = " | "),
       "\nPasta de trabalho atual: ", getwd(),
       "\nColoque o arquivo em '", pasta_dados, "' (ao lado do Rmd) e rode de novo.", call. = FALSE)
}

# ---- contar: frequência de uma coluna, com rótulos ----
# coluna: nome da coluna (texto). rotulos: vetor nomeado código -> rótulo (ou NULL).
# Retorna: categoria, n, pct. Códigos fora do vetor viram "Não categorizado (x)"; NA vira "Não preenchido".
contar <- function(dados, coluna, rotulos = NULL, ordenar_por_n = FALSE) {
  v <- as.character(dados[[coluna]])
  if (!is.null(rotulos)) {
    v <- ifelse(is.na(v), "Não preenchido",
         ifelse(v %in% names(rotulos), unname(rotulos[v]), paste0("Não categorizado (", v, ")")))
    ordem <- c(unname(rotulos), "Não preenchido")
  } else {
    v <- ifelse(is.na(v), "Não preenchido", v)
    ordem <- if (is.factor(dados[[coluna]])) c(levels(dados[[coluna]]), "Não preenchido") else sort(unique(v))
  }
  ordem <- c(ordem, setdiff(unique(v), ordem))
  res <- tibble(categoria = factor(v, levels = ordem)) %>%
    count(categoria, name = "n") %>%
    mutate(pct = 100 * n / sum(n), categoria = as.character(categoria))
  if (ordenar_por_n) res <- arrange(res, desc(n))
  res
}

# ---- nome do câncer nas saídas ----
# Todo arquivo exportado começa com o id do câncer (ex.: colo_utero_estado_civil.csv) e todo título de tabela
# e de gráfico traz o nome do câncer (ex.: "Estado civil: câncer de colo do útero").
# Na sintese.Rmd (que não tem um câncer só), o prefixo é "sintese" e os títulos ficam como estão.
nome_arquivo <- function(arquivo) paste0(get0("id_cancer", ifnotfound = "sintese"), "_", arquivo)

titulo_cancer <- function(titulo) {
  nome <- get0("nome_cancer", ifnotfound = NULL)
  if (is.null(nome) || grepl("câncer de", titulo, fixed = TRUE)) titulo else paste0(titulo, ": câncer de ", nome)
}

# ---- registro do que foi exportado ----
# Cada tabela, figura e painel gravado é anotado aqui; no fim do Rmd, exportar_tudo() usa esta lista.
.saidas <- new.env()
.saidas$indice  <- tibble(tipo = character(), nome = character(), arquivo = character())
.saidas$tabelas <- list()    # as tabelas (já formatadas) para o Excel
.saidas$avisos  <- character()

registrar_saida <- function(tipo, nome, arquivo) {
  .saidas$indice <- bind_rows(.saidas$indice, tibble(tipo = tipo, nome = nome, arquivo = arquivo))
}

# Mostra a mensagem uma única vez por relatório
avisar_uma_vez <- function(chave, texto) {
  if (!(chave %in% .saidas$avisos)) {
    message(texto)
    .saidas$avisos <- c(.saidas$avisos, chave)
  }
}

# ---- tabelas ----
# Monta a tabela (knitr::kable + kableExtra), mostra no relatório e, se 'arquivo' for informado, grava em
# saidas/<câncer>/tabelas/: .csv (abre no Excel), .html e .png.
#   destacar       = números das linhas a destacar em cor/negrito
#   negrito_ultima = linha de total em negrito
tabela_kable <- function(df_exibir, titulo, arquivo = NULL, subtitulo = NULL, notas = NULL,
                         destacar = NULL, negrito_ultima = FALSE) {
  n_col <- ncol(df_exibir)
  n_lin <- nrow(df_exibir)

  k <- df_exibir %>%
    kable(format = "html", align = c("l", rep("r", n_col - 1)), escape = TRUE) %>%
    kable_styling(bootstrap_options = c("condensed", "hover"), full_width = FALSE, position = "left", font_size = 14) %>%
    row_spec(0, bold = TRUE, color = cor_texto, background = cor_listra,
             extra_css = paste0("border-bottom: 2px solid ", cor_principal, ";"))
  if (n_lin >= 2) k <- row_spec(k, seq(2, n_lin, by = 2), background = cor_listra)     # linhas alternadas
  if (length(destacar) > 0) k <- row_spec(k, destacar, bold = TRUE, color = cor_principal)
  if (negrito_ultima && n_lin > 0) k <- row_spec(k, n_lin, bold = TRUE)

  # título e subtítulo dentro da própria tabela (assim também aparecem no PNG/HTML exportados)
  if (!is.null(subtitulo)) {
    k <- add_header_above(k, setNames(n_col, subtitulo), align = "l", italic = TRUE, color = cor_neutra,
                          line = FALSE, font_size = 13)
  }
  titulo <- titulo_cancer(titulo)
  k <- add_header_above(k, setNames(n_col, titulo), align = "l", bold = TRUE, color = cor_texto,
                        line = FALSE, font_size = 16)
  k <- footnote(k, general = c(notas, fonte_dados), general_title = "", footnote_as_chunk = FALSE)

  if (!is.null(arquivo)) {
    pasta <- file.path(pasta_saida, "tabelas")
    dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
    base <- file.path(pasta, nome_arquivo(arquivo))

    # CSV com ponto e vírgula e acentos corretos (abre direto no Excel em português)
    write_excel_csv2(df_exibir, paste0(base, ".csv"))
    registrar_saida("tabela", titulo, paste0(base, ".csv"))
    .saidas$tabelas[[arquivo]] <- list(titulo = titulo, dados = df_exibir)

    ok_html <- tryCatch({ save_kable(k, paste0(base, ".html")); TRUE }, error = function(e) FALSE)
    if (ok_html) registrar_saida("tabela", titulo, paste0(base, ".html"))
    else avisar_uma_vez("html", "Aviso: o HTML das tabelas não foi gerado (save_kable falhou). Os CSV foram gravados.")

    if (salvar_png_tabelas) {
      ok_png <- tryCatch({ save_kable(k, paste0(base, ".png")); TRUE }, error = function(e) FALSE)
      if (ok_png) registrar_saida("tabela", titulo, paste0(base, ".png"))
      else avisar_uma_vez("png", "Aviso: o PNG das tabelas não foi gerado (precisa de webshot2 e Chrome). CSV e HTML foram gravados.")
    }
  }
  k
}

# Teste de aderência (qui-quadrado): as categorias de UMA variável, dentro do mesmo câncer, têm a mesma frequência?
#   H0: todas as categorias com informação têm a mesma frequência
#   n: contagens de cada categoria com informação (quem chama tira "Sem informação", "Ignorado" e "Não preenchido")
# Com poucas pacientes (esperado menor que 5 por categoria) o p-valor é simulado; com 2 categorias usa-se o teste binomial exato.
p_aderencia <- function(n) {
  n <- n[n > 0]
  k <- length(n)
  if (k < 2) return(list(p = NA_real_, metodo = "sem teste (menos de 2 categorias)"))
  if (k == 2) return(list(p = binom.test(n[1], sum(n), p = 0.5)$p.value, metodo = "binomial exato"))
  if (sum(n) / k < 5) {
    set.seed(semente)
    return(list(p = chisq.test(n, simulate.p.value = TRUE, B = 10000)$p.value, metodo = "qui-quadrado de aderência (p simulado)"))
  }
  list(p = chisq.test(n)$p.value, metodo = "qui-quadrado de aderência")
}

# Tabela de frequência padrão (categoria, N, %, valor de p) com linha de total e supressão de células pequenas
#   df: resultado de contar()
#   teste: TRUE coloca o valor de p do teste de aderência na primeira linha (só faz sentido quando as categorias
#          são excludentes; por isso, por padrão, só tabelas com linha de total são testadas)
tabela_padrao <- function(df, titulo, rotulo = "Categoria", arquivo = NULL, subtitulo = NULL, notas = NULL,
                          total = TRUE, teste = total) {
  exibir <- df %>%
    mutate(
      N = ifelse(celula_pequena(n), paste0("<", min_celula), fmt_n(n)),
      `%` = ifelse(celula_pequena(n), "-", fmt_pct(pct))
    ) %>%
    select(categoria, N, `%`)
  if (total) exibir <- bind_rows(exibir, tibble(categoria = "Total", N = fmt_n(sum(df$n)), `%` = "100,0%"))
  names(exibir)[1] <- rotulo

  if (teste) {
    sem_info <- str_detect(df$categoria, "^(Sem informação|Ignorado|Não preenchido)")   # dado faltante não é uma categoria da variável
    t <- p_aderencia(df$n[!sem_info])   # o teste usa as contagens reais; só o valor de p aparece na tabela
    exibir[["Valor de p"]] <- c(fmt_p(t$p), rep("", nrow(exibir) - 1))
    notas <- c(notas, paste0("Valor de p: ", t$metodo, " entre as categorias com informação (H0: frequências iguais); ",
                             "'Sem informação', 'Ignorado' e 'Não preenchido' ficam fora do teste."))
  }
  tabela_kable(exibir, titulo, arquivo, subtitulo, notas, negrito_ultima = total)
}

# ---- gráficos ----
# Texto de rodapé (nota) dos gráficos: a nota específica do gráfico, se houver, e depois a fonte
nota_grafico <- function(texto = NULL) {
  if (is.null(texto)) fonte_dados else paste0(texto, "\n", fonte_dados)
}

# Grava a figura em saidas/<câncer>/figuras/ como PNG (300 dpi) e PDF (vetorial, bom para o artigo)
salvar_figura <- function(p, arquivo, largura = 8, altura = 5) {
  if (is.null(arquivo)) return(invisible(p))
  pasta <- file.path(pasta_saida, "figuras")
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  base <- file.path(pasta, nome_arquivo(arquivo))

  ggsave(paste0(base, ".png"), p, width = largura, height = altura, dpi = 300, bg = "white")
  registrar_saida("figura", arquivo, paste0(base, ".png"))

  ok_pdf <- tryCatch({ ggsave(paste0(base, ".pdf"), p, width = largura, height = altura, device = cairo_pdf); TRUE },
                     error = function(e) tryCatch({ ggsave(paste0(base, ".pdf"), p, width = largura, height = altura); TRUE },
                                                  error = function(e2) FALSE))
  if (ok_pdf) registrar_saida("figura", arquivo, paste0(base, ".pdf"))
  invisible(p)
}

# Junta vários gráficos em um painel (patchwork) com letras A, B, C... e grava em saidas/<câncer>/paineis/
#   graficos: lista de gráficos, ex.: list(grafico_idade, grafico_meso)
painel <- function(graficos, arquivo, titulo = NULL, subtitulo = NULL, ncol = 2, largura = 13, altura = 6) {
  graficos <- Filter(Negate(is.null), graficos)
  p <- wrap_plots(graficos, ncol = ncol) & labs(caption = NULL)     # a fonte aparece uma vez, no rodapé do painel
  p <- p + plot_annotation(
    title = if (!is.null(titulo)) titulo_cancer(titulo), subtitle = subtitulo, caption = fonte_dados, tag_levels = "A",
    theme = theme(plot.title = element_text(face = "bold", size = 16, color = cor_texto),
                  plot.subtitle = element_text(color = cor_neutra),
                  plot.caption = element_text(color = cor_neutra, hjust = 0, size = 9)))

  pasta <- file.path(pasta_saida, "paineis")
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  base <- file.path(pasta, nome_arquivo(arquivo))
  ggsave(paste0(base, ".png"), p, width = largura, height = altura, dpi = 300, bg = "white")
  registrar_saida("painel", arquivo, paste0(base, ".png"))
  ok_pdf <- tryCatch({ ggsave(paste0(base, ".pdf"), p, width = largura, height = altura, device = cairo_pdf); TRUE },
                     error = function(e) tryCatch({ ggsave(paste0(base, ".pdf"), p, width = largura, height = altura); TRUE },
                                                  error = function(e2) FALSE))
  if (ok_pdf) registrar_saida("painel", arquivo, paste0(base, ".pdf"))
  p
}

# Mapa de Minas Gerais com o número de pacientes por mesorregião (mapa coroplético)
#   contagem:    resultado de contar(coorte, "mesorregiao")
#   mesorregioes: tabela município -> mesorregião (a mesma usada na seção 2 do Rmd)
# Precisa dos pacotes sf e geobr. Na primeira vez baixa a malha dos municípios de MG (internet) e guarda
# em dados/malha_municipios_mg.rds; depois disso funciona sem internet. Se algo falhar, devolve NULL e o relatório segue.
grafico_mapa_mg <- function(contagem, mesorregioes, titulo, arquivo = NULL) {
  if (!requireNamespace("sf", quietly = TRUE) || !requireNamespace("geobr", quietly = TRUE)) {
    message("Aviso: mapa não gerado. Instale os pacotes: install.packages(c('sf', 'geobr'))")
    return(NULL)
  }
  arq_malha <- file.path(dirname(achar_arquivo(arq_mesorregioes, "mesorregi")), "malha_municipios_mg.rds")
  malha <- tryCatch({
    if (file.exists(arq_malha)) {
      readRDS(arq_malha)
    } else {
      m <- geobr::read_municipality(code_muni = "MG", year = 2020, showProgress = FALSE)
      saveRDS(m, arq_malha)
      m
    }
  }, error = function(e) NULL)
  if (is.null(malha)) {
    message("Aviso: mapa não gerado (não foi possível obter a malha municipal de MG; verifique a internet).")
    return(NULL)
  }

  # Junta os municípios em mesorregiões, com a mesma classificação usada no restante da análise
  poligonos <- malha %>%
    mutate(codigo_ibge = as.character(code_muni)) %>%
    left_join(mesorregioes, by = "codigo_ibge") %>%
    filter(!is.na(mesorregiao)) %>%
    group_by(mesorregiao) %>%
    summarise(.groups = "drop") %>%
    left_join(select(contagem, mesorregiao = categoria, n), by = "mesorregiao") %>%
    mutate(n = coalesce(n, 0L), n_cor = ifelse(celula_pequena(n), NA, n))

  pontos <- suppressWarnings(sf::st_point_on_surface(poligonos))
  rotulos <- sf::st_drop_geometry(poligonos) %>%
    mutate(x = sf::st_coordinates(pontos)[, 1], y = sf::st_coordinates(pontos)[, 2],
           rotulo = ifelse(celula_pequena(n), paste0("<", min_celula), fmt_n(n)))

  p <- ggplot(poligonos) +
    geom_sf(aes(fill = n_cor), color = "white", linewidth = 0.4) +
    geom_text(data = rotulos, aes(x = x, y = y, label = rotulo), size = 3.2, color = cor_texto) +
    scale_fill_gradient(low = cor_listra, high = cor_principal, na.value = "#D1D5DB", name = "Pacientes") +
    labs(title = titulo_cancer(titulo),
         caption = nota_grafico(paste0("Número de pacientes atendidas no IMP (não é a incidência na população). ",
                                       "Cinza = menos de ", min_celula, " pacientes."))) +
    theme_void(base_size = 12) +
    theme(plot.title = element_text(face = "bold", color = cor_texto),
          plot.caption = element_text(color = cor_neutra, hjust = 0, size = rel(0.8)),
          plot.title.position = "plot", plot.caption.position = "plot")
  salvar_figura(p, arquivo, largura = 7, altura = 7)
  p
}

# Barras horizontais a partir do resultado de contar()
grafico_barras <- function(df, titulo, arquivo = NULL, subtitulo = NULL, ordenar = TRUE, eixo = "Pacientes") {
  df <- df %>% mutate(
    rotulo = ifelse(celula_pequena(n), paste0("<", min_celula), paste0(fmt_n(n), " (", fmt_pct(pct), ")")))
  df$categoria <- if (ordenar) reorder(df$categoria, df$n) else factor(df$categoria, levels = rev(df$categoria))
  p <- ggplot(df, aes(x = n, y = categoria)) +
    geom_col(fill = cor_principal, width = 0.7) +
    geom_text(aes(label = rotulo), hjust = -0.1, size = 3.4, color = cor_texto) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.3))) +
    labs(title = titulo_cancer(titulo), x = eixo, y = NULL, caption = nota_grafico(subtitulo)) +
    theme(panel.grid.major.y = element_blank())
  salvar_figura(p, arquivo, altura = max(3, 0.45 * nrow(df) + 1.8))
  p
}

# ---- prazo da Lei 12.732/2012 ----
# dias: vetor de dias entre diagnóstico e início do tratamento (COM sinal).
# Intervalo negativo (tratamento antes da data do laudo) conta como dentro do prazo.
resumo_prazo <- function(dias, prazo = prazo_lei, nivel = 0.95) {
  dias <- dias[!is.na(dias)]
  n <- length(dias)
  k <- sum(dias <= prazo)
  ic <- c(NA_real_, NA_real_)
  if (n > 0) ic <- 100 * suppressWarnings(prop.test(k, n, conf.level = nivel, correct = FALSE)$conf.int)  # IC de Wilson
  tibble(
    n = n, k = k, pct = ifelse(n > 0, 100 * k / n, NA_real_), lo = ic[1], hi = ic[2],
    mediana = median(dias), q1 = quantile(dias, 0.25, names = FALSE), q3 = quantile(dias, 0.75, names = FALSE),
    negativos = sum(dias < 0)
  )
}

# Prazo por grupos de uma variável (ou geral, se variavel = NULL)
prazo_por <- function(dados, variavel = NULL) {
  if (is.null(variavel)) {
    return(resumo_prazo(dados$dias_diag_trat) %>% mutate(grupo = "Total", .before = 1))
  }
  res <- dados %>%
    group_by(grupo = as.character(.data[[variavel]])) %>%
    group_modify(~ resumo_prazo(.x$dias_diag_trat)) %>%
    ungroup()
  if (is.factor(dados[[variavel]])) {
    res <- res %>% mutate(grupo = factor(grupo, levels = levels(dados[[variavel]]))) %>%
      arrange(grupo) %>% mutate(grupo = as.character(grupo))
  }
  res
}

# Formata o resultado de prazo_por() para a tabela
formatar_prazo <- function(pz, rotulo) {
  peq <- celula_pequena(pz$n)
  exibir <- tibble(
    grupo = pz$grupo,
    N = ifelse(peq, paste0("<", min_celula), fmt_n(pz$n)),
    `Tratadas em até 60 dias` = ifelse(peq, "-", fmt_n(pz$k)),
    `% (IC 95%)` = ifelse(peq, "-", paste0(fmt_num(pz$pct), "% (", fmt_num(pz$lo), "-", fmt_num(pz$hi), ")")),
    `Mediana de dias [Q1-Q3]` = ifelse(peq, "-", paste0(fmt_num(pz$mediana, 0), " [", fmt_num(pz$q1, 0), "-", fmt_num(pz$q3, 0), "]"))
  )
  names(exibir)[1] <- rotulo
  exibir
}

# Qui-quadrado entre uma variável e o cumprimento do prazo (p simulado se houver frequência esperada < 5)
p_associacao <- function(dados, variavel, resposta = "no_prazo") {
  tb <- table(droplevels(factor(dados[[variavel]])), factor(dados[[resposta]]))
  tb <- tb[rowSums(tb) > 0, colSums(tb) > 0, drop = FALSE]
  if (nrow(tb) < 2 || ncol(tb) < 2) return(tibble(p = NA_real_, metodo = "não aplicável (menos de 2 categorias)"))
  esperado <- suppressWarnings(chisq.test(tb)$expected)
  if (any(esperado < 5)) {
    set.seed(semente)
    tibble(p = chisq.test(tb, simulate.p.value = TRUE, B = 10000)$p.value, metodo = "qui-quadrado (p simulado)")
  } else {
    tibble(p = chisq.test(tb)$p.value, metodo = "qui-quadrado")
  }
}

# ---- sobrevida (Kaplan-Meier) ----
# Sobrevida nos tempos pedidos (meses). NA quando o seguimento máximo é menor que o tempo.
km_tempos <- function(ajuste, tempos) {
  s <- summary(ajuste, times = tempos, extend = FALSE)
  base <- tibble(meses = tempos)
  if (length(s$time) == 0) return(mutate(base, surv = NA_real_, lo = NA_real_, hi = NA_real_, em_risco = NA_integer_))
  achados <- tibble(meses = s$time, surv = s$surv, lo = s$lower, hi = s$upper, em_risco = as.integer(s$n.risk))
  left_join(base, achados, by = "meses")
}

km_mediana <- function(ajuste) {
  m <- unname(summary(ajuste)$table["median"])
  if (length(m) == 0) NA_real_ else m
}

# Seguimento mediano pelo Kaplan-Meier reverso (o "evento" passa a ser a censura)
seguimento_mediano <- function(dados) {
  d <- dados %>% filter(tempo_meses >= 0) %>% mutate(censura = 1L - evento_obito)
  if (sum(d$censura) == 0) return(NA_real_)
  km_mediana(survfit(Surv(tempo_meses, censura) ~ 1, data = d))
}

grafico_km <- function(ajuste, titulo, arquivo = NULL, subtitulo = NULL, eixo_y = "Sobrevida global") {
  if (is.null(ajuste$strata)) {
    grupo <- rep("Todas", length(ajuste$time))
  } else {
    grupo <- sub("^grupo=", "", rep(names(ajuste$strata), ajuste$strata))
  }
  curva <- tibble(grupo = grupo, meses = ajuste$time, surv = ajuste$surv, lo = ajuste$lower, hi = ajuste$upper)
  inicio <- tibble(grupo = unique(grupo), meses = 0, surv = 1, lo = 1, hi = 1)
  curva <- bind_rows(inicio, curva) %>% arrange(grupo, meses)
  estratificado <- length(unique(grupo)) > 1
  nota_km <- paste0(if (!is.null(subtitulo)) paste0(subtitulo, "\n"),
                    "Censura administrativa em ", format(data_corte, "%d/%m/%Y"), " (sem data de último contato).")
  p <- ggplot(curva, aes(x = meses, y = surv, color = grupo, fill = grupo)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.12, color = NA) +
    geom_step(linewidth = 0.9) +
    scale_y_continuous(limits = c(0, 1), labels = function(x) paste0(100 * x, "%")) +
    scale_x_continuous(breaks = seq(0, 72, 12)) +
    labs(title = titulo_cancer(titulo), x = "Meses desde o diagnóstico", y = eixo_y,
         color = NULL, fill = NULL, caption = nota_grafico(nota_km))
  if (estratificado) {
    p <- p + scale_color_manual(values = paleta) + scale_fill_manual(values = paleta)
  } else {
    p <- p + scale_color_manual(values = cor_principal) + scale_fill_manual(values = cor_principal) +
      theme(legend.position = "none")
  }
  salvar_figura(p, arquivo, altura = 5.5)
  p
}

# ---- verificação de qualidade ----
chk <- function(verificacao, n_problemas, detalhe, info = FALSE) {
  tibble(`Verificação` = verificacao, Resultado = detalhe,
         Status = ifelse(info, "INFO", ifelse(n_problemas == 0, "OK", "ATENÇÃO")))
}

# Tabela de sobrevida em 12, 36 e 60 meses (texto pronto para exibir)
formatar_km <- function(ajuste, tempos = c(12, 36, 60)) {
  k <- km_tempos(ajuste, tempos)
  tibble(
    `Tempo (meses)` = as.character(k$meses),
    `Em risco` = ifelse(is.na(k$em_risco), "-", ifelse(celula_pequena(k$em_risco), paste0("<", min_celula), fmt_n(k$em_risco))),
    `Sobrevida (IC 95%)` = ifelse(is.na(k$surv), "Seguimento insuficiente",
                                  paste0(fmt_pct(100 * k$surv), " (", fmt_num(100 * k$lo), "-", fmt_num(100 * k$hi), ")"))
  )
}


# ---- exportação final ----
# Chame no fim de cada Rmd: grava o Excel com todas as tabelas, a sessão do R e o índice de tudo que foi exportado.
# Devolve um resumo (pasta, tipo, quantidade) para mostrar no relatório. Nenhum dado individual é exportado.
exportar_tudo <- function() {
  pasta <- pasta_saida
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  nome <- basename(pasta)

  # 1) Excel com todas as tabelas (uma aba por tabela, mais um índice)
  if (salvar_xlsx && length(.saidas$tabelas) > 0) {
    if (requireNamespace("openxlsx", quietly = TRUE)) {
      wb <- openxlsx::createWorkbook()
      cab <- openxlsx::createStyle(textDecoration = "bold", fgFill = cor_listra, border = "bottom", borderColour = cor_principal)
      abas <- substr(names(.saidas$tabelas), 1, 31)
      indice_abas <- tibble(Aba = abas, Tabela = map_chr(.saidas$tabelas, "titulo"))
      openxlsx::addWorksheet(wb, "Indice")
      openxlsx::writeData(wb, "Indice", indice_abas, headerStyle = cab)
      openxlsx::setColWidths(wb, "Indice", cols = 1:2, widths = c(32, 80))
      for (i in seq_along(.saidas$tabelas)) {
        openxlsx::addWorksheet(wb, abas[i])
        openxlsx::writeData(wb, abas[i], .saidas$tabelas[[i]]$dados, headerStyle = cab)
        openxlsx::setColWidths(wb, abas[i], cols = seq_len(ncol(.saidas$tabelas[[i]]$dados)), widths = "auto")
      }
      arq_xlsx <- file.path(pasta, paste0("tabelas_", nome, ".xlsx"))
      openxlsx::saveWorkbook(wb, arq_xlsx, overwrite = TRUE)
      registrar_saida("excel", "Todas as tabelas", arq_xlsx)
    } else {
      avisar_uma_vez("xlsx", "Aviso: o Excel com todas as tabelas não foi gerado (instale o pacote openxlsx). Os CSV foram gravados.")
    }
  }

  # 2) Versões dos pacotes (reprodutibilidade)
  arq_sessao <- file.path(pasta, paste0("sessionInfo_", nome, ".txt"))
  writeLines(capture.output(sessionInfo()), arq_sessao)
  registrar_saida("sessao", "Versões do R e dos pacotes", arq_sessao)

  # 3) Índice de tudo que foi exportado
  arq_indice <- file.path(pasta, paste0("indice_saidas_", nome, ".csv"))
  registrar_saida("indice", "Lista de arquivos exportados", arq_indice)
  write_excel_csv2(.saidas$indice, arq_indice)

  .saidas$indice %>%
    mutate(Pasta = dirname(arquivo), Formato = tools::file_ext(arquivo)) %>%
    count(Pasta, tipo, Formato, name = "Arquivos") %>%
    rename(Tipo = tipo)
}
