# Requisitos e Personas — Colo de Mãe

## Seção A — Contexto e Justificativa

### 1. O problema

O período pós-parto é marcado por mudanças físicas, emocionais e sociais que podem aumentar a necessidade de orientação e suporte. A puérpera pode enfrentar dificuldades relacionadas à amamentação, como insegurança quanto à pega correta, ordenha, armazenamento e identificação de serviços especializados.

Nesse contexto, a falta de informações acessíveis, organizadas e disponíveis no momento da necessidade pode dificultar a tomada de decisões e aumentar a sensação de insegurança, especialmente durante os primeiros dias após o parto e em situações envolvendo recém-nascidos prematuros ou de risco.

### 2. A solução proposta

O **Colo de Mãe** é um aplicativo de apoio à puérpera centrado em informações sobre amamentação, ordenha, armazenamento de leite humano e acesso à Rede de Bancos de Leite Humano.

A proposta é reunir conteúdos de consulta rápida, biblioteca de informações, recursos para acompanhamento da fase do bebê e informações sobre Bancos de Leite Humano (BLHs), proporcionando uma experiência simples, acolhedora e adequada ao uso em dispositivos móveis.

O aplicativo não substitui o acompanhamento de profissionais de saúde. Seu objetivo é facilitar o acesso a informações e serviços de apoio relacionados à amamentação e à doação de leite humano.

### 3. Pesquisa e fontes da Rede Brasileira de Bancos de Leite Humano

As decisões de conteúdo relacionadas à doação, processamento e distribuição de leite humano foram orientadas por informações da **Rede Brasileira de Bancos de Leite Humano (rBLH), vinculada à Fiocruz**.

Entre os pontos considerados na pesquisa estão:

* **Protocolo REDEBLH-BR:** referência para procedimentos e critérios relacionados à doação, processamento, pasteurização, controle de qualidade e distribuição do leite humano.
* **Cobertura da rede:** dados disponibilizados pela rBLH indicam a existência de aproximadamente 230 Bancos de Leite Humano em funcionamento no Brasil no período de referência utilizado pelo projeto.
* **Elegibilidade para doação:** a doadora deve atender aos critérios estabelecidos pela rede, considerando condições de saúde, uso de medicamentos e outros fatores que possam interferir na segurança do leite doado.
* **Leite humano pasteurizado:** o leite humano doado e processado pelos Bancos de Leite Humano possui importância especialmente para recém-nascidos prematuros e/ou de risco que necessitam desse suporte nutricional.

**Fontes de referência:** Rede Brasileira de Bancos de Leite Humano (rBLH/Fiocruz), protocolos técnicos e materiais institucionais utilizados como base para o desenvolvimento do projeto.

---

# Seção B — Personas

## Persona 1 — Carla, 28 anos

**Perfil:** Primípara em pós-parto imediato (0–7 dias).

**Contexto:**
Carla recebeu alta hospitalar recentemente e está enfrentando as primeiras experiências com a amamentação. Sente insegurança em relação à pega correta e acorda diversas vezes durante a noite para cuidar do bebê.

**Necessidades:**

* Respostas rápidas e objetivas;
* Orientações sobre pega e amamentação;
* Conteúdo que não exija leitura extensa;
* Modo noturno para utilização durante a madrugada;
* Navegação simples e acessível com uma mão.

**Dispositivo:**
Celular Android, utilizado frequentemente com uma das mãos enquanto cuida do bebê.

---

## Persona 2 — Renata, 34 anos

**Perfil:** Mãe de prematuro internado em UTI neonatal.

**Contexto:**
O bebê de Renata ainda não consegue realizar a amamentação diretamente. Ela precisa realizar a ordenha e busca informações sobre armazenamento e doação de leite humano, além de procurar um Banco de Leite Humano próximo.

**Necessidades:**

* Localizar Bancos de Leite Humano;
* Entender como funciona o processo de doação;
* Consultar orientações sobre ordenha e armazenamento;
* Acessar informações mesmo com conexão de internet instável.

**Dispositivo:**
iPhone, com acesso intermitente ao Wi-Fi durante a permanência no hospital.

---

## Persona 3 — Ana, 41 anos

**Perfil:** Mãe de segundo filho, com mais de 30 dias de pós-parto.

**Contexto:**
Ana possui experiência anterior com amamentação e procura informações mais aprofundadas para situações específicas. Costuma salvar conteúdos para consultar posteriormente e utiliza o aplicativo principalmente durante a madrugada.

**Necessidades:**

* Biblioteca de conteúdos organizada;
* Informações mais aprofundadas;
* Sistema de favoritos;
* Possibilidade de consultar conteúdos disponíveis offline;
* Organização dos conteúdos de acordo com a fase do bebê.

**Dispositivo:**
Celular Android, utilizado principalmente durante a madrugada.

---

# Seção C — Requisitos Funcionais

Os requisitos funcionais abaixo foram definidos a partir das funcionalidades presentes no protótipo desenvolvido para o **Colo de Mãe**.

| ID       | Requisito Funcional                 | Descrição                                                                                                                                                        |
| -------- | ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RF01** | Splash screen                       | Exibir tela inicial de boas-vindas durante o carregamento da aplicação, com duração planejada de até 3 segundos.                                                 |
| **RF02** | Perfil do bebê                      | Permitir cadastrar e editar o nome e a data de nascimento do bebê.                                                                                               |
| **RF03** | Cálculo da fase                     | Calcular automaticamente a fase do bebê com base na data de nascimento, considerando as faixas **0–7 dias, 8–30 dias e 31+ dias**.                               |
| **RF04** | Dica do dia                         | Exibir uma dica diária que pode ser expandida ou recolhida pelo usuário, sem utilização de ícone associado à IA.                                                 |
| **RF05** | Acesso rápido                       | Disponibilizar acesso às áreas de **Pega, Ordenha e Armazenamento**, utilizando ícones SVG e priorizando acesso em até três interações.                          |
| **RF06** | Biblioteca de conteúdos             | Disponibilizar uma biblioteca organizada por quatro categorias, contendo os 11 artigos previstos no protótipo.                                                   |
| **RF07** | Favoritos e disponibilidade offline | Permitir marcar conteúdos como favoritos e indicar visualmente quais conteúdos estão disponíveis para consulta offline no protótipo.                             |
| **RF08** | Localização de BLHs                 | Apresentar um mapa em formato placeholder e uma lista com quatro Bancos de Leite Humano de exemplo para demonstrar a funcionalidade de localização.              |
| **RF09** | Detalhes do BLH                     | Apresentar informações do Banco de Leite Humano selecionado, incluindo endereço, horário, telefone e orientações relacionadas à doação.                          |
| **RF10** | Modo noturno                        | Disponibilizar modo noturno para proporcionar maior conforto visual durante o uso em ambientes com pouca iluminação, especialmente durante mamadas na madrugada. |
| **RF11** | Conectividade                       | Exibir um indicador visual de estado de conexão, representando os estados **online, offline e sincronizando** no protótipo.                                      |
| **RF12** | Configurações                       | Disponibilizar configurações relacionadas ao perfil do bebê, aparência, notificações e privacidade.                                                              |

### Observação sobre o escopo do protótipo

Algumas funcionalidades são apresentadas como **demonstração visual no protótipo**, não representando necessariamente uma integração real com serviços externos. Isso se aplica especialmente ao mapa e à localização de Bancos de Leite Humano, ao estado de conectividade e às funcionalidades de disponibilidade offline.

A implementação futura dessas funcionalidades deverá considerar fontes oficiais, atualização dos dados e requisitos técnicos de segurança e privacidade.
