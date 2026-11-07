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

## Decisões de método (base: manual e ficha do INCA)

- **Procedência por mesorregião do IBGE**, no lugar de "RMBH x demais municípios".
- **Coorte:** `DIAGANT` 1 ou 2 (chegou sem tratamento anterior), tratamento iniciado no hospital, residência em MG, diagnóstico e início do tratamento entre 01/01/2019 e 31/12/2024, e **tratamento custeado pelo SUS** (`CUSTRATAMTUMOR = 1`). O fluxo com a contagem de cada etapa está no relatório.
- **Lei 12.732/2012:** 60 dias do diagnóstico (laudo) ao início do tratamento. Intervalo calculado com sinal; tratamento antes do laudo conta como dentro do prazo.
- **Sobrevida:** Kaplan-Meier a partir da data do diagnóstico. O export não traz o último contato; quem não tem óbito é censurada em 31/12/2024.
- **LGPD:** contagens de 1 a 4 pacientes aparecem como "<5".

## Referências

- INSTITUTO NACIONAL DE CÂNCER (INCA). **Registros hospitalares de câncer: planejamento e gestão**. 2. ed. Rio de Janeiro: INCA, 2010.
- INSTITUTO NACIONAL DE CÂNCER (INCA). **Ficha de Registro de Tumor** (RHC).
- BRASIL. **Lei nº 12.732, de 22 de novembro de 2012**. <https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2012/lei/l12732.htm>
- IBGE. **Divisão territorial brasileira**; **Códigos dos municípios**. <https://www.ibge.gov.br>
- ORGANIZAÇÃO MUNDIAL DA SAÚDE. **CID-O**. 3. ed. São Paulo: Fundação Oncocentro de São Paulo; Faculdade de Saúde Pública da USP, 2005. ISBN 85-314-0372-3.
- POSIT TEAM. **RStudio: Integrated Development Environment for R**. Boston, MA: Posit Software, PBC, 2026. <http://www.posit.co/>

## Mapa de Minas Gerais

O mapa mostra o **número de pacientes** por mesorregião de residência (as mesorregiões são montadas juntando os municípios, com a mesma classificação do restante da análise). **Não é incidência na população**: para taxas por 100 mil mulheres seria preciso a população feminina de cada mesorregião (IBGE). Regiões com 1 a 4 pacientes aparecem em cinza ("<5").
