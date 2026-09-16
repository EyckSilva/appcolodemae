## 1. Objetivo

Definir as principais funcionalidades e requisitos do APP Colo de Mãe, considerando as necessidades das mães no pós-parto identificadas nas atividades anteriores.

## 2. O que fazer

### 2.1 Funcionalidades

#### 1. Perfil do bebê
**Descrição:** Permite cadastrar o nome e a data de nascimento do bebê.  
**Necessidade:** Facilitar a personalização das informações.  
**Justificativa:** É utilizado para identificar a fase do bebê dentro do aplicativo.

#### 2. Fase do bebê
**Descrição:** O aplicativo identifica a fase do bebê de acordo com sua data de nascimento.  
**Necessidade:** Receber informações de acordo com o momento vivido.  
**Justificativa:** Ajuda a apresentar conteúdos mais adequados para cada período.

#### 3. Dica do dia
**Descrição:** Apresenta uma dica relacionada à rotina de amamentação e cuidados com o bebê.  
**Necessidade:** Ter acesso rápido a uma orientação.  
**Justificativa:** Facilita o acesso a informações durante a rotina.

#### 4. Pega correta
**Descrição:** Disponibiliza conteúdo sobre a pega correta durante a amamentação.  
**Necessidade:** Entender como realizar a pega adequadamente.  
**Justificativa:** É uma das principais dúvidas identificadas no projeto.

#### 5. Ordenha
**Descrição:** Apresenta informações sobre a ordenha do leite materno.  
**Necessidade:** Orientar mães que precisam retirar o leite.  
**Justificativa:** É importante para mães que precisam retirar o leite em determinados momentos.

#### 6. Armazenamento
**Descrição:** Apresenta informações sobre o armazenamento do leite materno.  
**Necessidade:** Saber como armazenar o leite corretamente.  
**Justificativa:** Complementa as informações sobre a ordenha.

#### 7. Conteúdos por categorias
**Descrição:** Organiza os conteúdos do aplicativo em diferentes categorias.  
**Necessidade:** Encontrar informações específicas com facilidade.  
**Justificativa:** Facilita a busca pelas informações necessárias.

#### 8. Favoritos
**Descrição:** Permite salvar conteúdos para consultar posteriormente.  
**Necessidade:** Guardar informações importantes.  
**Justificativa:** Facilita o acesso a conteúdos que podem ser consultados novamente.

#### 9. Bancos de Leite Humano
**Descrição:** Apresenta informações sobre Bancos de Leite Humano.  
**Necessidade:** Encontrar informações relacionadas aos serviços disponíveis.  
**Justificativa:** Aproxima a usuária dos serviços relacionados ao leite humano.

#### 10. Doação de leite
**Descrição:** Apresenta informações sobre a doação de leite humano.  
**Necessidade:** Entender como funciona a doação.  
**Justificativa:** Faz parte da proposta do aplicativo.

#### 11. Modo noturno
**Descrição:** Permite utilizar o aplicativo com uma interface adaptada para ambientes com pouca iluminação.  
**Necessidade:** Utilizar o aplicativo com maior conforto durante a noite.  
**Justificativa:** A rotina de cuidados com o bebê também acontece durante a madrugada.

#### 12. Configurações
**Descrição:** Reúne opções relacionadas ao perfil, aparência e preferências do aplicativo.  
**Necessidade:** Personalizar a experiência de uso.  
**Justificativa:** Permite adaptar o aplicativo às preferências da usuária.

### 2.2 Requisitos funcionais

**RF01 — Cadastro do bebê:** O sistema deve permitir cadastrar o nome e a data de nascimento do bebê.

**RF02 — Edição do perfil:** O sistema deve permitir editar as informações cadastradas do bebê.

**RF03 — Identificação da fase:** O sistema deve calcular a fase do bebê utilizando a data de nascimento cadastrada.

**RF04 — Dica do dia:** O sistema deve apresentar uma dica do dia na tela inicial.

**RF05 — Pega correta:** O sistema deve permitir acessar conteúdos sobre pega correta.

**RF06 — Ordenha:** O sistema deve permitir acessar conteúdos sobre ordenha.

**RF07 — Armazenamento:** O sistema deve permitir acessar conteúdos sobre armazenamento do leite materno.

**RF08 — Categorias:** O sistema deve organizar os conteúdos disponíveis por categorias.

**RF09 — Favoritos:** O sistema deve permitir adicionar conteúdos aos favoritos.

**RF10 — Remoção dos favoritos:** O sistema deve permitir remover conteúdos da lista de favoritos.

**RF11 — Bancos de Leite:** O sistema deve apresentar uma área com informações sobre Bancos de Leite Humano.

**RF12 — Detalhes dos Bancos:** O sistema deve permitir consultar informações detalhadas dos Bancos de Leite apresentados.

**RF13 — Doação:** O sistema deve apresentar informações relacionadas à doação de leite humano.

**RF14 — Modo noturno:** O sistema deve permitir alternar entre o modo claro e o modo noturno.

**RF15 — Configurações:** O sistema deve disponibilizar opções para configuração do perfil, aparência e preferências.

### 2.3 Requisitos não funcionais

**RNF01 — Usabilidade:** A interface deve permitir que a usuária encontre as principais funcionalidades de forma simples.

**RNF02 — Acessibilidade:** Os textos, botões e elementos da interface devem possuir tamanho e organização adequados para facilitar a leitura e a interação.

**RNF03 — Responsividade:** O aplicativo deve se adaptar aos diferentes tamanhos de tela dos dispositivos móveis.

**RNF04 — Desempenho:** As telas e conteúdos devem ser carregados de forma rápida, evitando esperas desnecessárias.

**RNF05 — Privacidade:** As informações cadastradas pela usuária devem ser tratadas de acordo com princípios de privacidade e proteção de dados.

**RNF06 — Compatibilidade:** O aplicativo deve funcionar em dispositivos móveis compatíveis com Flutter.

**RNF07 — Navegação:** A navegação entre as principais áreas deve ser simples e consistente.

**RNF08 — Conforto visual:** O aplicativo deve disponibilizar modo noturno para utilização em ambientes com pouca iluminação.

### 2.4 CRUD

No Colo de Mãe, o CRUD se aplica principalmente ao perfil do bebê e aos conteúdos favoritos.

| **C — Criar** | Cadastrar o perfil do bebê e adicionar conteúdos aos favoritos. |
| **R — Consultar** | Consultar os dados do bebê e os conteúdos favoritos. |
| **U — Atualizar** | Alterar o nome ou a data de nascimento do bebê. |
| **D — Excluir** | Remover conteúdos da lista de favoritos. |

As informações dos conteúdos e dos Bancos de Leite são principalmente consultadas, pois fazem parte do conteúdo disponibilizado pelo aplicativo.

### 2.5 Priorização

#### Essenciais
- Pega correta;
- Ordenha;
- Armazenamento;
- Conteúdos por categorias;
- Bancos de Leite Humano;
- Doação de leite;

São indispensáveis porque estão diretamente relacionadas à proposta principal do Colo de Mãe.

#### Importantes
- Perfil do bebê;
- Fase do bebê;
- Favoritos;
- Modo noturno;
- Dica do dia;

Essas funcionalidades melhoram a experiência e facilitam o acesso às informações.

#### Secundárias
- Configurações e personalizações adicionais

Podem receber novas opções em versões futuras sem comprometer a proposta principal do aplicativo. 