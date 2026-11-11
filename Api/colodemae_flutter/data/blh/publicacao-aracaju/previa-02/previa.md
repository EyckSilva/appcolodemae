# Previa administrativa - Aracaju

**Nenhuma gravacao executada. Autorizacao explicita pendente.**

Projeto: `colo-de-mae-3510f`; colecao: `bancos_leite`.

Hash do plano: `e29e2508df38a84506f96711f457014259dc17ac8c9cec34b4b89f9c6932e1c0`

Os pontos foram fornecidos pelo responsavel, que informou Google Maps como origem. Links de conferencia foram gerados; nao representam certificacao por uma API Google.

## Banco de Leite Humano Marly Sarney

ID existente: `se-blh-marly-sarney`; CNES estabelecimento `0002569`; vinculo `proprio`.

Ponto proposto: `-10.90619346346821, -37.07967947461301`.

Conferencia: **compativel_com_estabelecimento**. Diferenca para a coordenada cadastral DEMAS: **7.13 m** (nao e distancia da usuaria).

Coincidência com o cadastro próprio atual do BLH (tolerância de comparação 25 m, não precisão certificada)

Ressalvas:
- Séries históricas divergentes não foram escolhidas como coordenada atual; a tolerância não é margem de erro GPS.

Fontes:
- https://apidadosabertos.saude.gov.br/cnes/estabelecimentos/0002569

[Conferir ponto no Google Maps](https://www.google.com/maps/search/?api=1&query=-10.90619346346821,-37.07967947461301)

### Mudancas propostas de dados

- **endereco**: "Rua Mato Grosso, s/n, bairro José Conrado de Araújo" -> "Rua Mato Grosso, s/n, José Conrado de Araújo"
- **cep**: null -> "49085220"
- **telefone**: "(79) 3226-6301" -> "(79)32266301"
- **horarioFuncionamento**: null -> "Segunda a sexta\n7h às 19h"
- **descricaoTelefone**: null -> "Recepção do BLH"
- **cnesEstabelecimento**: null -> "0002569"
- **relacaoCnes**: null -> "proprio"

A fonte por campo tambem e atualizada; o estado anterior completo fica preservado no historico. Veja plano.json para o diff integral.

## Posto de Coleta de Leite Humano da Maternidade Municipal Lourdes Nogueira

ID existente: `se-posto-maternidade-lourdes-nogueira`; CNES estabelecimento `4099206`; vinculo `mantenedora`.

Ponto proposto: `-10.999583128695352, -37.100241600455675`.

Conferencia: **compativel_com_estabelecimento**. Diferenca para a coordenada cadastral DEMAS: **55.55 m** (nao e distancia da usuaria).

Ponto dentro do polígono OSM do prédio Maternidade do 17 de Março; conferência do estabelecimento mantenedor

Ressalvas:
- Ponto do estabelecimento mantenedor; não confirma sala, porta ou cadastro CNES exclusivo do posto.
- DEMAS usa s/n e Prefeitura usa nº 64; a referência OSM é Avenida João Batista Costa. Mesmo prédio, divergência de numeração/referência viária mantida no histórico. Não confirma acesso ao posto.

Fontes:
- https://apidadosabertos.saude.gov.br/cnes/estabelecimentos/4099206
- https://api.openstreetmap.org/api/0.6/way/841076721/full.json

[Conferir ponto no Google Maps](https://www.google.com/maps/search/?api=1&query=-10.999583128695352,-37.100241600455675)

### Mudancas propostas de dados

- **endereco**: null -> "Rua Procurador José Costa Cavalcante, s/n, 17 de Março"
- **cep**: null -> "49003247"
- **telefone**: null -> "7931422776"
- **horarioFuncionamento**: null -> "Internadas: atendimento 24h\nDoação externa: confirme por telefone"
- **descricaoTelefone**: null -> "Contato da maternidade"
- **cnesEstabelecimento**: null -> "4099206"
- **relacaoCnes**: null -> "mantenedora"

A fonte por campo tambem e atualizada; o estado anterior completo fica preservado no historico. Veja plano.json para o diff integral.

## Posto de Coleta Dr. Fernando Guedes — Maternidade Santa Isabel

ID existente: `se-posto-fernando-guedes-santa-isabel`; CNES estabelecimento `0002232`; vinculo `mantenedora`.

Ponto proposto: `-10.902491696685145, -37.062623903449044`.

Conferencia: **compativel_com_estabelecimento**. Diferenca para a coordenada cadastral DEMAS: **36957.43 m** (nao e distancia da usuaria).

Ponto dentro do polígono OSM do prédio Hospital Santa Isabel; conferência do estabelecimento mantenedor

Ressalvas:
- Ponto do estabelecimento mantenedor; não confirma sala, porta ou cadastro CNES exclusivo do posto.
- Coordenada DEMAS distante foi rejeitada para esta proposta. O cadastro oficial e a AAB informam Avenida Simeão Sobral, 1312; via OSM próxima é Rua Deodato Maia, sem validação de acesso específico.

Fontes:
- https://apidadosabertos.saude.gov.br/cnes/estabelecimentos/0002232
- https://api.openstreetmap.org/api/0.6/way/292330063/full.json

[Conferir ponto no Google Maps](https://www.google.com/maps/search/?api=1&query=-10.902491696685145,-37.062623903449044)

### Mudancas propostas de dados

- **endereco**: "Avenida Simeão Sobral, s/n, bairro Santo Antônio" -> "Avenida Simeão Sobral, 1312, Dezoito do Forte"
- **cep**: null -> "49072720"
- **telefone**: "(79) 3212-4900" -> "79 32124900"
- **horarioFuncionamento**: null -> "Todos os dias\n8h às 12h e 14h às 18h"
- **descricaoTelefone**: null -> "Contato do hospital"
- **cnesEstabelecimento**: null -> "0002232"
- **relacaoCnes**: null -> "mantenedora"

A fonte por campo tambem e atualizada; o estado anterior completo fica preservado no historico. Veja plano.json para o diff integral.

## Publicacao proposta apos autorizacao

- Atualizar somente os tres documentos existentes, sem criar novos IDs.
- Publicacao documental: ativo/publicado true e data de aprovacao; dados/horarios/contatos revisados do aplicativo.
- Aprovacao geografica separada: latitude/longitude numericas e geohash somente com decisao explicita para cada ponto.
- Os pontos dos dois postos correspondem aos estabelecimentos mantenedores; acesso a sala/porta do posto nao certificado.
- Unidades publicadas sem aprovacao geografica continuam listadas, com Sem estimativa e rota por endereco.
- Preservar criadoEm, campos desconhecidos e historico; rejeitar alteracoes concorrentes ou sobregravacao de coordenadas ja aprovadas.

A autorizacao pendente esta em autorizacao.pendente.json. Todos os campos de autorizacao ainda sao false.
