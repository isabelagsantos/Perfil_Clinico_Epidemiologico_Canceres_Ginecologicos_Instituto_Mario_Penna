# Perfil clínico-epidemiológico dos cânceres ginecológicos - IMP/Hospital Luxemburgo

Estudo descritivo e analítico, com dados do Registro Hospitalar de Câncer (RHC), sobre a contribuição do Instituto Mário Penna (IMP)/Hospital Luxemburgo (CACON) ao diagnóstico e tratamento dos cânceres de **vulva, colo do útero, endométrio e ovário** em pacientes atendidas pelo SUS, 2019-2024.

## Arquivos

| Arquivo | O que é |
|---|---|
| `codigos/vulva.Rmd`, `ccu.Rmd` (colo do útero), `endometrio.Rmd`, `co.Rmd` (ovário) | Uma análise por câncer. Têm exatamente a mesma estrutura; só o primeiro bloco (identificação, arquivo e rótulos do câncer) muda |
| `codigos/funcoes_padrao.R` | Ajustes gerais, rótulos do INCA, visual padrão (cores, tabelas, gráficos, painéis, mapa), exportação e funções comuns |
| `codigos/sintese.Rmd` | Compara os quatro cânceres (rode depois dos quatro Rmd) |
| `dados/` | Onde ficam os `.xlsx` do RHC e as tabelas de referência (município -> mesorregião) |
| `saidas/` | Criada ao rodar (na raiz do projeto): todos os resultados de cada câncer (veja "O que é exportado") |
| `conferencia/` | Opcional: conferência dos números em Python |

## Como rodar

1. Copie os 4 `.xlsx` do RHC para `dados/`.
2. Abra o projeto no RStudio (`perfil_clinico_epidemiologico.Rproj`) e abra os Rmd que estão em `codigos/`. Ao clicar em Knit, o R trabalha dentro de `codigos/` e acha `dados/` e `saidas/` na pasta de cima.
3. Pacotes: `install.packages(c("tidyverse", "knitr", "kableExtra", "patchwork", "readxl"))` (o `survival` já vem com o R). Para o mapa de Minas Gerais: `install.packages(c("sf", "geobr"))`. Opcionais: `openxlsx` (Excel com todas as tabelas) e `webshot2` + Chrome (PNG de cada tabela). Sem os opcionais, o resto é gravado normalmente.
4. Na primeira vez, o mapa baixa a malha municipal de MG (precisa de internet) e a guarda em `dados/malha_municipios_mg.rds`; nas próximas vezes não precisa de internet. Se o mapa não puder ser feito, o relatório avisa e segue sem ele.
5. Abra cada Rmd e clique em **Knit** (ordem: `vulva`, `ccu`, `endometrio`, `co`, depois `sintese`).

## O que é exportado

Ao knitar cada Rmd, tudo o que aparece no relatório é gravado em `saidas/<câncer>/` (a síntese grava em `saidas/sintese/`):

| Pasta/arquivo | Conteúdo |
|---|---|
| `tabelas/` | Cada tabela em **CSV** (ponto e vírgula, abre direto no Excel), **HTML** e **PNG** |
| `tabelas_<câncer>.xlsx` | Todas as tabelas em um único Excel, uma aba por tabela |
| `figuras/` | Cada gráfico, incluindo o mapa, em **PNG** (300 dpi) e **PDF** (vetorial) |
| `paineis/` | Painéis com vários gráficos juntos (patchwork, letras A, B, C...) em PNG e PDF |
| `resumo_<câncer>.csv` | Números-chave usados pela síntese (não vai para o GitHub) |
| `indice_saidas_<câncer>.csv` | Lista de todos os arquivos exportados |
| `sessionInfo.txt` | Versões do R e dos pacotes |

O último item de cada relatório ("Arquivos exportados") mostra quantos arquivos de cada tipo foram gravados. **Nenhum dado individual de paciente é exportado**, e as contagens de 1 a 4 saem como "<5".

## Onde mudar as coisas

- **Critérios da coorte, prazo da lei, filtro SUS, data de censura, ocultar células pequenas:** seção 1 de `codigos/funcoes_padrao.R`.
- **Cores e estilo:** seção 3 de `codigos/funcoes_padrao.R`. **Exportar ou não o PNG das tabelas / o Excel:** `salvar_png_tabelas` e `salvar_xlsx`, seção 1.
- **Rótulos de localização, histologia e causa de óbito:** primeiro bloco de código de cada Rmd.

## Decisões de método (base: manual e ficha do INCA)

- **Procedência por mesorregião do IBGE**, no lugar de "RMBH x demais municípios".
- **Coorte:** `DIAGANT` 1 ou 2 (chegou sem tratamento anterior), tratamento iniciado no hospital, residência em MG, diagnóstico e início do tratamento entre 01/01/2019 e 31/12/2024, e **tratamento custeado pelo SUS** (`CUSTRATAMTUMOR = 1`). O fluxo com a contagem de cada etapa está no relatório.
- **Lei 12.732/2012:** 60 dias do diagnóstico (laudo) ao início do tratamento. Intervalo calculado com sinal; tratamento antes do laudo conta como dentro do prazo.
- **Sobrevida:** Kaplan-Meier a partir da data do diagnóstico. O export não traz o último contato; quem não tem óbito é censurada em 31/12/2024.
- **LGPD:** contagens de 1 a 4 pacientes aparecem como "<5".

## Correções em relação aos Rmd anteriores

- `DTINITRT = 88/88/8888` significa que a paciente **não tratou no hospital** (INCA, item 32). O comentário antigo dizia "tratou em outra instituição".
- `OBITOPORCANCER`: 1 = sim, 2 = **não** (óbito por outra causa), 9 = ignorado; 0 = sem óbito. Antes, 0 estava como "Não" e 2 como "Ignorado".
- O tempo entre diagnóstico e tratamento não usa mais `abs()`.
- `DIAGANT = 9` não passa mais pelo filtro (antes `!= "3"` deixava passar).
- Estadiamento: 0 (in situ), 88 (não estadiável) e 99 (sem informação) deixaram de ser descartados; todas as pacientes entram no denominador.
- Idade: é a da **primeira consulta** (item 8), não a do diagnóstico.
- Seções que ficavam fora de chunk (histórico familiar, custeio do diagnóstico) voltaram a rodar.
- Nomes trocados pelo "localizar e substituir" (`raca_vulr`, `historivul_*`) e títulos de ovário/colo corrigidos.
- Série mensal (seção 8): passou a existir nos quatro Rmd (antes só em `ccu` e `co`). No `ccu` o título dizia "Ovário". A ACF estava rotulada em "meses", mas a defasagem do `ts` vem em **anos**; agora está em meses, com os limites de 95%.
- Rótulos de histologia, localização e causa de óbito: antes variavam entre os arquivos (ex.: 8070/3 aparecia como "escamoso" e "escamocelular"; no `co`, C56 estava com texto de colo do útero). Agora cada código tem um único rótulo, no padrão da CID-O/CID-10.
- O qui-quadrado de aderência (contagens iguais entre categorias) foi retirado das tabelas descritivas; no lugar entram testes de associação com o cumprimento do prazo.

## Pontos a conferir antes de publicar

- Rótulos de histologia contra a CID-O impressa (`rotulos_hist` em cada Rmd): foram unificados e **não conferi com o livro**.
- Vulva: códigos 8151/3 (insulinoma) e 8170/3 (carcinoma hepatocelular) são incomuns; conferir no prontuário.
- Endométrio: o arquivo só tem C54.1; confirmar se C54.x/C55 foram todos exportados.
- Decisão da equipe: manter o filtro SUS ligado (`apenas_sus`) e se deve restringir a casos analíticos (`apenas_analiticos`).

## Referências

- INSTITUTO NACIONAL DE CÂNCER (INCA). **Registros hospitalares de câncer: planejamento e gestão**. 2. ed. Rio de Janeiro: INCA, 2010.
- INSTITUTO NACIONAL DE CÂNCER (INCA). **Ficha de Registro de Tumor** (RHC).
- BRASIL. **Lei nº 12.732, de 22 de novembro de 2012**. <https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2012/lei/l12732.htm>
- IBGE. **Divisão territorial brasileira**; **Códigos dos municípios**. <https://www.ibge.gov.br>
- ORGANIZAÇÃO MUNDIAL DA SAÚDE. **CID-O**. 3. ed. São Paulo: Fundação Oncocentro de São Paulo; Faculdade de Saúde Pública da USP, 2005. ISBN 85-314-0372-3.
- POSIT TEAM. **RStudio: Integrated Development Environment for R**. Boston, MA: Posit Software, PBC, 2026. <http://www.posit.co/>

## Mapa de Minas Gerais

O mapa mostra o **número de pacientes** por mesorregião de residência (as mesorregiões são montadas juntando os municípios, com a mesma classificação do restante da análise). **Não é incidência na população**: para taxas por 100 mil mulheres seria preciso a população feminina de cada mesorregião (IBGE). Regiões com 1 a 4 pacientes aparecem em cinza ("<5").
"# Perfil_Clinico_Epidemiologico_Canceres_Ginecologicos_Instituto_Mario_Penna" 
