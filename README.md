# analise_minuta_vagas_garagem_sp

**Contexto** 

Análise de dados referente à  Nota Técnica sobre a nova proposta de limite de vagas de garagem prevista a minuta de lei da Revisão Intermediária do Plano Diretor Estratégico (PDE) de São Paulo.

Elaborada no âmbito do Projeto Acesso a Oportunidades no Plano Diretor de São Paulo do Laboratório ArqFuturo de Cidades do Insper entre os dias 16/01/2023 e 20/01/2023 

A Nota Técnica completa, com dados e texto, está disponível em: https://www.insper.edu.br/wp-content/uploads/2023/01/NotaTecnica_NovaRegraVagasGaragem_LabCidadesInsper.pdf

**Dados**

Dados EMBRAESP foram enviados pela ABRAINC mediante cooperação para o Projeto Acesso a Oportunidades no Plano Diretor de São Paulo no dia 27/04/2022. A base original não foi compartilhada neste repositório público em função da natureza privada dos dados produzidos pela EMBRAESP. A compra ou solicitação de dados para fins de pesquisa pode ser realizada por meio do contato direto com a EMBRAESP. Mais informações no link <https://embraesp.com.br/>.

Dados complementares extraídos da plataforma GeoSampa e/ou produzidos pela equipe do Projeto.

**Framework**

Toda a análise foi implementada por meio da linguagem R e com a IDE RStudio. Informações sobre a sessão no arquivo "sessionInfo.txt.

O tratamento dos dados EMBRAESP foi elaborado em R e se utiliza de alguns pacotes disponíveis no *CRAN -- Compreensive R Archive Network*, que estão devidamente listados no início dos scripts conforme convenção da comunidade de desenvolvedores. 

Para a construção dos gráficos da nota técnica, foi realizada análise dos dados em RMarkdown e os gráficos foram colocados em documento docx.

A escrita do texto da nota técnica foi feita no Google Docs e a construção de figuras ilustrativas incluídas na nota técnica foi feita no Google Slides.

**Como implementar o projeto?** 

O script "analise_vagas_do.R" implementa a análise, de modo geral, requerendo nos seus procedimentos os scripts "embraesp_tratamento.R" - que faz o tratamento dos dados de lançamentos imobiliários EMBRAESP - e "embraesp_analise_vagas.Rmd" - que faz análise gráfica a partir dos dados tratados e exporta resultados para o documento word presente em "outputs/lancamentos/embraesp_analise_vagas.docx":

      analise_vagas_do.R ➡ embraesp_tratamento.R & embraesp_analise_vagas.Rmd ➡ embraesp_analise_vagas.docx
  
Recomenda-se criar um projeto R para utilizar os scripts. É usada a função here::here para aumento da reprodutibilidade. A função here:here parte do diretório raiz, com o projeto R o diretório raiz passa a ser a pasta atribuída ao projeto.

**Contato**

Em caso de dúvidas e esclarecimentos sobre o Projeto Acesso a Oportunidades no Plano Diretor de São Paulo, enviar email para: adrianoborgescosta@gmail.com

Em caso de dúvidas e esclarecimentos para reprodução ou solicitação de dados, enviar email para: evandroluisalves13@gmail.com ou adrianoborgescosta@gmail.com


