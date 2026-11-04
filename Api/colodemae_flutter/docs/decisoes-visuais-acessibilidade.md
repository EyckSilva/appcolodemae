## 1. Paleta de cores

**Cores principais:**

* Pêssego: `#F5B89A`
* Lilás: `#C2A4E8`
* Rosa: `#D97AAC`
* Creme: `#FFF8F5`

**Justificativa:**
A paleta foi escolhida com o objetivo de transmitir acolhimento, suavidade e tranquilidade, características importantes para uma aplicação voltada ao apoio à puérpera. Os tons suaves também contribuem para uma identidade visual amigável e menos agressiva visualmente, especialmente durante o uso em ambientes com pouca iluminação.

O creme (`#FFF8F5`) foi utilizado como alternativa ao branco puro em determinadas superfícies, contribuindo para uma aparência mais suave e coerente com a identidade visual.

A combinação de cores deve ser utilizada de forma a preservar contraste suficiente entre textos, ícones e seus respectivos fundos, priorizando a legibilidade.

---

## 2. Tipografia — Nunito

A família tipográfica **Nunito** foi escolhida por apresentar formas arredondadas e uma aparência visual amigável, contribuindo para uma comunicação mais acolhedora.

Foram priorizados pesos entre **600 e 900** em títulos, botões e informações de maior destaque, enquanto pesos menores podem ser utilizados em textos corridos quando necessário.

A escolha também considera a boa disponibilidade da fonte em diferentes dispositivos e sua distribuição gratuita por meio do Google Fonts.

---

## 3. Modo noturno

No modo noturno, foi utilizado o background `#160F22`, um tom escuro com componente lilás, em vez do preto absoluto (`#000000`).

**Justificativa:**
A escolha mantém a identidade visual do aplicativo durante o uso noturno e evita uma mudança visual excessivamente brusca entre a identidade principal e o modo escuro.

O fundo escuro também reduz a luminosidade geral da interface, proporcionando uma experiência mais confortável em ambientes com pouca iluminação. Elementos de texto e interação permanecem com contraste adequado para preservar a legibilidade.

---

## 4. Uso com uma mão

Os principais botões foram desenvolvidos com áreas de toque amplas, utilizando classes como `py-4` e `py-5`, buscando manter aproximadamente **48 px ou mais de altura** nos principais elementos interativos.

A interface também utiliza uma **navegação inferior fixa**, posicionando ações recorrentes em uma região de fácil acesso no uso com uma mão.

Foi utilizado um **grid de três colunas** para atalhos rápidos, permitindo organizar as principais funcionalidades de forma compacta e reduzindo a necessidade de deslocamentos excessivos pela interface.

Essas decisões têm como objetivo facilitar a interação em dispositivos móveis, especialmente durante situações em que a usuária esteja utilizando o aplicativo com apenas uma das mãos.

---

## 5. Ícones SVG customizados

Foram utilizados ícones em **SVG**, permitindo maior controle sobre tamanho, espessura do traço e adaptação aos diferentes temas da aplicação.

Os ícones principais de navegação utilizam aproximadamente `stroke-width: 2.2`, proporcionando maior presença visual e facilitando sua identificação em telas pequenas ou com menor luminosidade.

As cores dos ícones são controladas por variáveis CSS (`var(--*)`), permitindo que os elementos se adaptem automaticamente às diferentes configurações de tema.

A utilização de SVGs próprios também reduz a dependência de bibliotecas externas de ícones e mantém maior consistência visual entre os elementos da aplicação.

---

## 6. Princípios de acolhimento

Além dos aspectos técnicos de acessibilidade, as decisões visuais foram orientadas pela necessidade de criar uma experiência acolhedora para a puérpera.

Foram priorizados:

* Linguagem visual suave e não excessivamente clínica;
* Hierarquia visual clara;
* Botões e áreas de toque amplas;
* Textos com boa legibilidade;
* Navegação simples e previsível;
* Uso de cores suaves;
* Organização das informações em blocos e cartões;
* Redução da quantidade de informações apresentadas simultaneamente.

O objetivo é fazer com que a interface seja percebida como um espaço de apoio e orientação, evitando uma experiência visual excessivamente complexa ou impessoal.
