
# 0. Setup ----------------------------------------------------------------

# Recomenda-se criar um projeto R para utilizar este script
# É usada a função here::here para aumento da reprodutibilidade
# A função here:here parte do diretório raiz
# Com o projeto R o diretório raiz passa a ser a pasta atribuída ao projeto

# Informações da seção R geradora da análise no arquivo sessionInfo.txt
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")

# Pacotes R requeridos pelos scripts:
# install.packages(
#   "here", "sf", "sfarrow", "tidyverse", "tidylog","lubridate", "janitor", 
#   "readxl", "Hmisc", "deflateBR", "ggthemes", "patchwork", "ggthemes", 
#   "ggtext", "ggrepel", "beepr", "rmarkdown",
# )

# Arquivos de dados requeridos pelos scripts:
#
dados_requeridos <- c(
  "2022_04_27_embraesp_lancamentos.shp", "ZoningSPL_Clean_Class.shp",
  "SubprefectureMSP_SIRGAS.shp", "DistrictsMSP_SIRGAS.shp", "SIRGAS_SHP_MACROAREAS.shp",
  "Eixos.shp", "EixosLabels.csv")

#
dados_disponiveis <- purrr::map(list.dirs(here::here("inputs")),
                                ~ list.files(.x)) |>
  purrr::flatten() |>
  as.character()

# Todos os dados requeridos estão disponíveis no diretório do projeto?
dados_requeridos %in% dados_disponiveis

# PRESSUPOSTO: arquivos estão organizados na estrutura de pastas descritas no projeto GitHub
# Em caso de dúvida para reprodução ou solicitação de dados, enviar email para:
# evandroluisalves13@gmail.com | adrianoborgescosta@gmail.com


# 1. Do -------------------------------------------------------------------

# Faz tratamento dos dados da EMBRAESP
source(here::here("scripts", "Lancamentos", "embraesp_tratamento.R"))

# Gráficos da Nota técnica Vagas 
# A análise dos dados foi feita em RMarkdown e os gráficos colocados em documento docx
# A escrita do texto da nota técnica foi feita no Google Docs
# A construção de figuras ilustrativas incluídas na nota técnica foi feita no Google Slides

# Faz análise dos dados em formato word
rmarkdown::render(
  here::here("scripts", "Lancamentos", "embraesp_analise_vagas.Rmd"),
  output_format = "word_document",
  output_dir = here::here("outputs", "Lancamentos"),
  output_file = 'embraesp_analise_vagas', 
  output_options = list(toc = TRUE,
                        reference_docx = here::here("inputs", "Complementares", "Insper",
                                                    "papel-timbrado-insper.docx")
  ))

#
beepr::beep(8)