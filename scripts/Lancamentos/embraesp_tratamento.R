library(here)
library(sf)
library(tidyverse)
library(tidylog)
library(janitor)
library(lubridate)
library(readxl)
library(deflateBR)
library(ggthemes)
library(sfarrow)
library(Hmisc)
library(beepr)

#
options(error = beep)

# Recomenda-se criar um projeto R para utilizar este script
# É usada a função here::here para aumento da reprodutibilidade
# A função here:here parte do diretório raiz
# Com o projeto R o diretório raiz passa a ser a pasta atribuída ao projeto

# 1. Importa -------------------------------------------------------------------

#
embraesp_raw <- st_read(here("inputs", "Lancamentos", "Embraesp", "Individualizados",
                            "2022_04_27_embraesp_lancamentos.shp")) %>%
  st_transform(crs = 4674) %>%
  mutate(key = as.character(geometry), # Chave para agrupar empreendimentos por geoloc
         endereco = str_to_upper(endereco)) %>%
  group_by(key) %>%
  mutate(id_empreendimento = cur_group_id(),
         endereco_duplicado = if_else(n_distinct(endereco) >= 2, TRUE, FALSE)
         # Alguns geolocs possuem mais de 1 endereço --> 20 empreendimentos e 116 lançamentos
  ) %>%
  ungroup() %>%
  select(-key) %>%
  select(id_empreendimento, id, endereco_duplicado, everything())

# Importa tipologia de zoneamento e agrega informações por empreendimento
ZonasLeiZoneamento <- st_read(here("inputs", "Complementares", "Zoneamento", 
                                   "ZonasLeiZoneamento", "ZoningSPL_Clean_Class.shp")) %>%
  select(Zone) %>%
  st_transform(crs = st_crs(embraesp_raw)) %>%
  # st_make_valid(.) %>%
  filter(st_is_valid(.) == TRUE) %>%
  filter(!is.na(Zone)) %>%
  left_join(read_excel(here("inputs", "Complementares", "Zoneamento", 
                            "ZonasLeiZoneamento", "Class_Join.xls")), # tipologia nossa
            by = "Zone") %>%
  transmute(
    zoneamento_ajust = as.factor(Zone),
    zoneamento_grupo = 
      fct_relevel(ZoneGroup, 
                  c("ZCs&ZMs", "EETU", "EETU Futuros", 
                    "ZEIS Aglomerado", "ZEIS Vazio",  
                    "ZPI&DE", "ZE&P", "ZE&PR", "ZCOR")) %>%
      fct_other(drop = c("ZPI&DE", "ZE&P", "ZE&PR", "ZCOR"), 
                other_level = "Outros"),
    solo_uso = as.factor(case_when(Use == "mixed use" ~ "misto",
                                   Use == "unique use" ~ "único",
                                   TRUE ~ NA_character_)),
    ca_maximo = as.factor(FARmax))

# Sistema de coordenadas Geográficas de referência SIRGAS 
CRS <- "+proj=utm +zone=23 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

# Importando informações sobre o perímetro de São Paulo
subprefeituras <- st_read(
  here("inputs", "Complementares", "Subprefeituras", "SubprefectureMSP_SIRGAS.shp"),
  crs = CRS) %>%
  st_transform(st_crs(embraesp_raw)) %>%
  transmute(id_regional = sp_id,
            regional = sp_nome)

# Importando informações sobre o perímetro de São Paulo
distritos <- st_read(
  here("inputs", "Complementares", "Distritos", "DistrictsMSP_SIRGAS.shp")) %>%
  st_transform(st_crs(embraesp_raw)) %>%
  transmute(id_distrito = ds_codigo,
            distrito = ds_nome)

#
Macroareas <- st_read(here("inputs", "Complementares", "Macroareas",
                           "SIRGAS_SHP_MACROAREAS.shp")) %>%
  transmute(macroarea = as_factor(mc_sigla)) %>%
  st_transform(crs = st_crs(embraesp_raw))

#
eixos <- st_read(here("inputs", "Eixos", "ArquivosTratados",
                      "Eixos.shp")) %>%
  set_names(as_vector(read_csv(here("inputs", "Eixos", "ArquivosTratados",
                                    "EixosLabels.csv"), show_col_types = FALSE))) %>%
  select(id_Eixo, NomeTransp, TipoTransp, ) %>%
  st_transform(4674)

# 2. Cria dado desagregado -----------------------------------------------------

# Chave relacional com id e geometria
embraesp_key <- embraesp_raw %>%
  select(id, geometry)


# Abstrai geometria e aplica deflator
embraesp_no_geometry <- embraesp_raw %>%
  st_drop_geometry() %>%
  mutate(preco_deflacionado = deflate(nominal_values = preco_unid,
                                      nominal_dates = data_lanca,
                                      real_date = "12/2021",
                                      index = "igpm"))

# Adiciona informações de zoneamento ao dado desagregado
embraesp <- embraesp_key %>%
  inner_join(embraesp_no_geometry, by = "id") %>%
  mutate(ano = year(data_lanca),
         fx_area_util = case_when(area_util < 35 ~ "Menos que 35m²",
                                  area_util >= 35 ~ "Mais que 35m²")) %>%
  st_join(ZonasLeiZoneamento, join = st_nearest_feature)


# 3. Cria dado agregado --------------------------------------------------------

# Chave relacional com id e geometria por empreendimento
embraesp_por_empreendimento_key <- embraesp_raw %>%
  select(id_empreendimento, geometry) %>%
  filter(!duplicated(id_empreendimento))

# Abstrai geometria e estima variáveis por empreendimento
embraesp_por_empreendimento_no_geometry <- embraesp_no_geometry %>%
  filter(origem == "RESIDENCIAL") %>% # Tomando somente empreendimentos residenciais
  group_by(id_empreendimento) %>%
  dplyr::summarise(
    empreendimento = first(nome_empre),
    endereco = first(endereco),
    agente = first(na.omit(agente)),
    agente_ajust = fct_rev(if_else(str_detect(agente, "CEF"), "CEF", "SFH/SBPE")),
    data_lancamento = min(data_lanca),
    data_lancamento_ult = max(data_lanca),
    ano = year(data_lancamento_ult), # ano = f(ultima data de lancamento)
    n_unidades = sum(num_total_),
    n_unidades_menos_35m2 = sum(num_total_[which(0.95*area_util < 35)]),
    n_unidades_media = mean(num_total_),
    vagas_menos_35m2 = sum(vagas[which(0.95*area_util < 35)]*num_total_[which(0.95*area_util < 35)]),
    vagas = sum(vagas*num_total_),
    area_terreno = sum(area_terre),
    area_util_dp = sqrt(wtd.var(area_util, num_total_)),
    area_util_media = weighted.mean(area_util, num_total_),
    area_util_acima_35m2 = sum(area_util[which(0.95*area_util < 35)]*num_total_[which(0.95*area_util < 35)]),
    area_util = sum(area_util*num_total_),
    area_total = sum(area_total*num_total_),
    cota_parte = area_terreno/n_unidades,
    vgv = sum(num_total_*preco_unid), 
    preco_m2 = vgv/area_util,
    vgv_deflacionado = sum(num_total_*preco_deflacionado),
    preco_m2_deflacionado = vgv_deflacionado/area_util,
    porte = case_when(between(n_unidades, 0, 49) ~ "Até 50 UH's",
                      between(n_unidades, 50, 199) ~ "Entre 50 e 200 UH's",
                      n_unidades >= 200 ~ "Mais que 200 UH's",
                      TRUE ~ "Sem informação"),
    fx_area_terreno = fct_reorder(case_when(between(area_terreno, 0, 4999.999) ~ "0 a 5000 m²",
                                            between(area_terreno, 5000, 9999.999) ~ "5000 a 10000 m²",
                                            between(area_terreno, 10000, 19999.999) ~ "10000 a 20000m²",
                                            area_terreno >= 20000 ~ "Mais que 20000 m2",
                                            TRUE ~ "Sem informação"), area_terreno),
    fx_cota_parte = fct_reorder(case_when(between(cota_parte, 0, 49.999) ~ "0 a 50 m² por UH",
                                          between(cota_parte, 50, 99.999) ~ "50 a 100 m² por UH",
                                          between(cota_parte, 100, 999.999) ~ "100 a 1000 m² por UH",
                                          cota_parte >= 1000 ~ "Mais que 1000 m² por UH",
                                          TRUE ~ "Sem informação"), cota_parte))


#
embraesp_por_empreendimento <- embraesp_por_empreendimento_key %>%
  inner_join(embraesp_por_empreendimento_no_geometry, by = "id_empreendimento") %>%
  select(id_empreendimento, empreendimento:fx_cota_parte, everything()) %>%
  st_join(eixos, join = st_intersects) %>%
  st_join(ZonasLeiZoneamento, join = st_nearest_feature) %>%
  st_join(distritos, join = st_within) %>%
  st_join(subprefeituras, join = st_within) %>%
  st_join(Macroareas, join = st_within, largest = TRUE) # 1 empreendimento em duas Macroareas


# Duplicados | Pode ser ajustado com parâmetro "largest"
# st_drop_geometry(embraesp_por_empreendimento) %>% 
#   filter(duplicated(.)) %>% 
#   unique() %>%
#   view("embraesp_duplicados")

# Exlui duplicados e reposiciona variáveis
embraesp_por_empreendimento <- embraesp_por_empreendimento_key %>%
  inner_join(st_drop_geometry(embraesp_por_empreendimento) %>% 
               filter(!duplicated(.)), by = "id_empreendimento") %>%
  select(id_empreendimento, empreendimento:macroarea, geometry) # reposiciona

# 4. Exporta -------------------------------------------------------------------

# Exporta dados desagregados em formato parquet
sfarrow::st_write_parquet(embraesp, here("inputs", "Lancamentos", 
                                         "Embraesp", "ArquivosTratados",
                                         "embraesp.parquet"))

# Exporta dados agregados em formato parquet
sfarrow::st_write_parquet(embraesp_por_empreendimento, here("inputs", "Lancamentos", 
                                                  "Embraesp", "ArquivosTratados",
                                                  "embraesp_por_empreendimento.parquet"))

# Exporta dados agregados em formato shapefile
st_write(embraesp_por_empreendimento, here("inputs", "Lancamentos", "Embraesp", "ArquivosTratados"),
         layer="embraesp_por_empreendimento", delete_layer = TRUE, driver="ESRI Shapefile")

# Adiciona labels da Base Tratada
write_csv(data.frame(labels = names(embraesp_por_empreendimento)), 
          here("inputs", "Lancamentos", "Embraesp", "ArquivosTratados",
               "embraesp_por_empreendimentoLabels.csv"))

