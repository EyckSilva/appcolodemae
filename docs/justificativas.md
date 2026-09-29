# Justificativas de Interface e Arquitetura — Colo de Mãe

## 1. Cores

A paleta utiliza rosa, lilás, pêssego e creme para transmitir acolhimento, suavidade e tranquilidade, evitando uma aparência excessivamente clínica.

- **Rosa `#D97AAC`**: botões, destaques e progresso.
- **Lilás `#C2A4E8`**: categorias e cartões informativos.
- **Pêssego `#F5B89A`**: conteúdos de amamentação e armazenamento.
- **Creme `#FFF8F5`**: fundo principal das telas.
- **Fundo noturno `#160F22`**: utilizado no modo noturno.

O texto principal utiliza uma cor escura para manter boa legibilidade sobre os fundos claros.

## 2. Tipografia

Foi utilizada a fonte **Nunito**, por apresentar formas arredondadas e uma aparência amigável, adequada ao caráter acolhedor do aplicativo.

A hierarquia de tamanhos diferencia títulos, conteúdos e textos de apoio, facilitando a leitura das informações durante o pós-parto.

## 3. Organização das informações

As informações são organizadas em **categorias, cards e guias passo a passo**, evitando apresentar muitos conteúdos ao mesmo tempo.

Essa organização facilita a busca por orientações sobre **pega, ordenha, armazenamento e doação**, principalmente quando a mãe precisa encontrar uma informação rapidamente.

## 4. Navegação

A navegação principal utiliza uma **barra inferior fixa com quatro áreas**:

**Início · Conteúdos · BLH · Configurações**

A escolha facilita a localização das principais funções e permite acesso rápido às informações durante a rotina com o bebê.

As telas de detalhes possuem botão de voltar, enquanto os conteúdos podem seguir um fluxo passo a passo.

## 5. Componentes

Foram utilizados componentes simples e consistentes, como:

- Cards arredondados
- Botões
- Ícones Lucide
- Toggles
- Modais
- Categorias
- Barra de navegação inferior
- Barra de progresso

A padronização ajuda a mãe a reconhecer os elementos e entender como interagir com o aplicativo.

## 6. Acessibilidade

A interface prioriza **textos legíveis, contraste adequado, elementos fáceis de visualizar e navegação simples**.

Os conteúdos passo a passo utilizam textos maiores e quantidade reduzida de informação por tela, facilitando a leitura.

O **modo noturno** também foi incluído para proporcionar maior conforto visual em ambientes com pouca iluminação.

## 7. Contexto de uso

O aplicativo foi pensado para mães durante o **período pós-parto**, que podem utilizá-lo em casa, durante a rotina com o bebê e também durante a madrugada.

Por isso, foram priorizados:

- Uso com uma mão
- Navegação inferior
- Acesso rápido aos conteúdos
- Leitura simples
- Modo noturno
- Funcionamento offline para conteúdos salvos

Essas decisões consideram situações em que a mãe pode estar cansada, com pouco tempo disponível ou com o bebê no colo.

## 8. Arquitetura do sistema

O aplicativo foi desenvolvido em **Flutter**, utilizando **Dart** e uma estrutura organizada em componentes.

### Principais componentes

- **Telas (`screens`)**: apresentam as áreas do aplicativo, como Início, Conteúdos, BLH e Configurações.
- **Services**: controlam estados e funcionalidades, como dados do bebê, favoritos e modo noturno.
- **Models**: estruturam os dados utilizados pelo aplicativo.
- **Core + Tema**: reúne componentes reutilizáveis e a identidade visual.
- **Navegação**: controla o acesso entre as quatro áreas principais.

### Bibliotecas utilizadas

- **Provider**: gerenciamento de estado.
- **Shared Preferences**: armazenamento local.
- **Geolocator**: localização dos Bancos de Leite Humano.
- **URL Launcher**: abertura de mapas e discador.

A arquitetura foi organizada para manter o aplicativo simples, facilitar a manutenção e permitir a evolução das funcionalidades.