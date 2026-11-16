**Conforme a Portaria CNPq nº 2.664/2026:**

- Declare em um arquivo específico o uso, ou a ausência de uso, de ferramentas de Inteligência Artificial (IA) generativa neste trabalho.
- Se utilizou alguma ferramenta, informe:
  - **(i)** o nome da ferramenta e, se aplicável, a versão ou modelo;
  - **(ii)** a etapa do trabalho em que foi empregada;
  - **(iii)** a finalidade específica de uso em cada etapa.
- Caso nenhuma ferramenta de IA generativa tenha sido utilizada, declare expressamente essa ausência de uso, esta seção não pode ser omitida.

# Registro de Uso de IA — Colo de Mãe

**Integrantes:** Eyck Cainã, João Pedro Alves Seixas e Enderson Silva.

## Declaração de uso

No projeto **Colo de Mãe**, foi utilizada Inteligência Artificial Generativa como apoio ao desenvolvimento. Este registro concentra os usos relacionados à **revisão de código, diagnóstico de erros, ajustes de interface, verificação das integrações e esclarecimento sobre bibliotecas**.

- **Ferramenta:** Codex, assistente de IA da OpenAI utilizado no ambiente de desenvolvimento.
- **Modelo ou versão:** identificador específico não registrado na atividade.
- **Etapas:** revisão da autenticação e dos dados; ajustes visuais; diagnóstico do ambiente Android; verificação de segurança e dos dados dos BLHs.
- **Finalidade:** auxiliar na identificação das causas dos problemas, sugerir correções e apoiar a conferência das soluções.


## 1. Eyck Cainã — Desenvolvimento e revisão das integrações do aplicativo

**Responsabilidade no projeto:** desenvolvimento e integração do aplicativo Flutter, implementação da autenticação com Firebase Authentication, configuração e gerenciamento do Cloud Firestore, integração com a API DEMAS do Ministério da Saúde, geolocalização e consulta dos Bancos de Leite Humano, cálculo de distâncias, integração com mapas e publicação no Firebase Hosting.

**Uso da IA nesta frente:** apoio à revisão dessas integrações, ao diagnóstico de erros e à conferência das correções.

### Prompts de revisão utilizados

**Prompt 1 — Conferência da integração com o Firebase**

> Dá uma olhada no login e nos dados das contas para ver se está tudo certo com o Firebase. Cada pessoa precisa acessar só os próprios dados, sem mudar as telas.

**Objetivo:** revisar a identificação da usuária e o acesso aos seus dados, evitando documentos duplicados ou associados à conta errada.

**Resultado da revisão:** conferência do uso de `usuarios/{uid}`, da sessão autenticada e das verificações de propriedade realizadas pelos serviços.

**Prompt 2 — Tratamento de falhas no cadastro e no perfil**

> Confere o que acontece se a conta for criada, mas os dados do perfil não forem salvos. Quero poder tentar de novo sem criar outra conta nem perder os dados.

**Objetivo:** corrigir a interpretação dos erros quando a autenticação tem sucesso, mas a sincronização do perfil não é concluída.

**Resultado da revisão:** separação entre a conta autenticada e a gravação do perfil, com mensagem específica e possibilidade de nova tentativa da sincronização.

**Prompt 3 — Conferência das coordenadas e da distância**

> Confere se a localização dos bancos de leite está certa antes de mostrar a distância. Se ainda não tiver certeza, deixa “Sem estimativa”, mas mantém a unidade na lista.

**Objetivo:** revisar a confiabilidade das informações geográficas antes de utilizá-las no aplicativo.

**Resultado:** separação entre coordenadas candidatas e aprovadas, uso de pontos autorizados e manutenção de “Sem estimativa” quando não há dados suficientes para calcular a distância.

### Erros e ajustes analisados

| Erro ou situação | Como foi tratado no projeto |

| Uma falha de perfil poderia levar a uma nova tentativa de cadastrar uma conta já existente. | A revisão passou a distinguir falha de autenticação e falha de sincronização. A tentativa seguinte atua apenas sobre o perfil. Trata-se de um caso de falha previsto no código, não de uma afirmação de ocorrência em produção. |
| A proposta de código administrativo feita com apoio da IA usava `SERVER_TIMESTAMP` dentro de um array de histórico, o que não é aceito pelo Firestore. | O problema foi identificado antes da publicação. O item do histórico passou a usar a data explícita da autorização, mantendo timestamps de servidor nos campos suportados. Um teste de serialização com o SDK real passou a cobrir esse caso. |

### Justificativa das bibliotecas

| Biblioteca | Justificativa no aplicativo |

| `firebase_core` | Inicializar o Firebase com a configuração correspondente ao projeto. |
| `firebase_auth` | Gerenciar autenticação, recuperação de senha e alterações de sessão. |
| `cloud_firestore` | Consultar e persistir os dados, utilizando transações para evitar sobrescritas e duplicações. |
| `provider` | Compartilhar serviços e controladores entre as telas, acompanhando mudanças nos dados e na sessão. |
| `geolocator` | Obter localização com permissão e calcular a distância até os BLHs com coordenadas verificadas. |
| `url_launcher` | Integrar os botões do aplicativo ao discador e ao aplicativo de mapas. |
| `firebase-admin` | Realizar operações administrativas autorizadas fora do Flutter, sem incluir credenciais administrativas no aplicativo. |

## 2. João Pedro Alves Seixas — Revisão da interface e dos textos

**Participação nesta frente:** apoio à revisão visual, à organização dos textos e à legibilidade das informações apresentadas nas telas.

### Prompts de revisão utilizados

**Prompt 4 — Sublinhados na abertura do aplicativo**

> Quando abro o app, aparecem umas linhas amarelas embaixo dos textos. Consegue corrigir sem mudar o visual?

**Objetivo:** investigar um problema visual relatado na abertura do app sem alterar a identidade visual.

**Aspecto conferido na revisão:** os textos da apresentação ficaram em um contexto `Material`, com estilos definidos. Esse ajuste trata a apresentação do texto no Flutter sem substituir a tela por outro layout.

**Prompt 5 — Organização das informações dos BLHs**

> As informações dos bancos de leite estão muito amontoadas. Deixa só o nome, a rua e o bairro nos cards e organiza os detalhes e os telefones para ficar mais fácil de ler.

**Objetivo:** revisar a legibilidade e a formatação dos dados, sem redesenhar os cards ou a tela de detalhes.

**Resultado do ajuste:** distinção entre o endereço resumido do card e o endereço completo dos detalhes, além da formatação de telefone e da organização das informações disponíveis.

### Erros e ajustes analisados

| Erro ou situação | Como foi tratado no projeto |

| Textos da apresentação exibiam sublinhados amarelos indesejados. | Foi ajustado o contexto de apresentação dos textos com `Material` e estilos explícitos, preservando os elementos visuais. |
| Endereços extensos e telefones sem padronização prejudicavam a leitura dos BLHs. | A apresentação passou a usar resumo de rua e bairro no card e dados completos nos detalhes, com formatação de telefone. |
| Remover somente o botão “Buscar por cidade e estado” deixaria mensagens orientando o uso de uma opção indisponível. | A revisão da remoção incluiu os textos e os testes relacionados, mantendo orientações compatíveis com o fluxo de localização. |

Os ajustes de legibilidade e de mensagens foram refinamentos solicitados durante a revisão. Eles não foram classificados automaticamente como defeitos causados pela IA.

### Justificativa das bibliotecas

| Biblioteca | Justificativa no aplicativo |

| `google_fonts` | Manter a tipografia definida no tema do app. |
| `lucide_icons_flutter` | Preservar o conjunto de ícones utilizado nos componentes existentes. |
| `flutter_localizations` | Apresentar componentes, como o seletor de data, em português brasileiro. |
| `shared_preferences` | Guardar preferências simples do dispositivo, como modo noturno e favoritos. Dados privados de perfil continuam no Firestore. |

## 3. Enderson Silva — Apoio à revisão técnica e à validação

**Participação nesta frente:** apoio ao diagnóstico do ambiente Android, à análise dos alertas de segurança e à verificação das correções, em conjunto com o responsável pelo desenvolvimento.

### Prompts de revisão utilizados

**Prompt 6 — Java, Gradle e assinatura Debug**

> Não estou conseguindo compilar o app para Android e está dando erro de Java. Pode conferir o que está faltando e tentar rodar de novo sem mexer nas configurações do aplicativo?

**Objetivo:** diagnosticar falhas do ambiente e obter uma compilação Android válida para conferir a assinatura de depuração.

**Resultado da conferência:** o diagnóstico identificou o Java incompleto. Após a correção do ambiente, foram conferidos a compilação Debug, o Package Name e a assinatura do APK.

**Prompt 7 — Revisão dos alertas de segurança**

> O GitHub mostrou uns alertas de segurança sobre as chaves do projeto. Dá uma olhada para ver se tem algo exposto e o que precisa corrigir, sem mostrar as chaves.

**Objetivo:** revisar a finalidade das chaves e evitar decisões baseadas somente no tipo do alerta.

**Resultado da revisão:** identificação dos pontos que precisavam de correção, incluindo a cópia externa e a lógica do detector de credenciais. A conferência também distinguiu a remoção de uma chave no arquivo atual de sua permanência no histórico Git.

### Erros e ajustes analisados

| Erro ou situação | Como foi tratado no projeto |

| A tentativa assistida de reutilizar o Java da extensão do editor falhou porque essa instalação não possuía `jlink`. | Foi instalado e conferido um JDK Temurin completo. Após os ajustes do Java usado pelo Flutter e pelo usuário, o APK Debug foi compilado com sucesso. Era um problema do ambiente, não da lógica da interface. |
| O detector inicial classificava marcadores PEM presentes no próprio código como candidatos a chave privada. | A lógica passou a distinguir o marcador textual do material de uma chave completa, com testes usando valores artificiais. |
| Três testes comparavam `firebase.json` com um hash anterior à configuração Hosting já commitada. | O conteúdo existente foi conferido e preservado, e o validador passou a reconhecer aquele hash exato, mantendo os registros históricos. |

### Justificativa das bibliotecas

| Biblioteca | Justificativa no aplicativo e na validação |

| `flutter_test` | Verificar cenários como permissão negada, falha de conexão e apresentação dos componentes. |
| `flutter_lints` | Apoiar a análise estática e a consistência do código Dart. |
