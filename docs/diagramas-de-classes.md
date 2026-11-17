# Diagramas de classes — Colo de Mãe

Diagramas gerados a partir do código real do app Flutter (`Api/colodemae_flutter/lib`) com a ferramenta `dcdg` e revisados manualmente. Para manter a leitura, o projeto foi dividido por camada e os widgets visuais de baixo nível, as classes privadas e os utilitários foram omitidos.

**Legenda:** `*--` composição, `-->` associação, `..>` dependência/uso, `<|--` herança.

## Modelos

Entidades de domínio do app: dados do bebê, catálogo de conteúdos e bancos de leite. As coleções globais (`articles`, `milkBanks` e `babyPhaseInfo`) são indicadas em notas para não poluir o diagrama.

`BabyPhase`, `ArticleCategory` e `ConnectionStatus` são enumerações.

```mermaid
classDiagram
    class BabyPhase {
        newborn
        firstMonth
        growing
    }

    class BabyPhaseInfo {
        +String label
        +String emoji
        +String message
    }

    class Baby {
        +String name
        +DateTime birthDate
        +int daysSinceBirth
        +BabyPhase phase
        +copyWith(name, birthDate) Baby
        +toJson() Map
        +fromJson(json) Baby$
    }

    class ArticleCategory {
        pega
        ordenha
        amamentacao
        sono
    }

    class ArticleStep {
        +IconData icon
        +String title
        +String text
    }

    class Article {
        +String id
        +ArticleCategory category
        +String title
        +String description
        +List~ArticleStep~ steps
    }

    class MilkBank {
        +String name
        +String distance
        +String address
        +String hours
        +String phone
        +List~String~ tags
        +double latitude
        +double longitude
    }

    class ConnectionStatus {
        online
        offline
        syncing
    }

    Baby ..> BabyPhase : phase
    BabyPhase ..> BabyPhaseInfo : babyPhaseInfo
    Article --> ArticleCategory : category
    Article *-- ArticleStep : steps

    note for BabyPhase "Map global babyPhaseInfo associa cada fase a um BabyPhaseInfo"
    note for ArticleCategory "Extension ArticleCategoryLabel fornece label e icon"
    note for Article "Lista global articles"
    note for MilkBank "Lista global milkBanks"
    note for ConnectionStatus "Usado pelo ConnectivityBadge na HomeScreen"
```

## Serviços e estado

Controladores que estendem `ChangeNotifier` e concentram o estado global do app. Cada um persiste sua preferência com `SharedPreferences` e notifica a UI por `notifyListeners()`.

`ChangeNotifier` é uma classe abstrata do Flutter.

```mermaid
classDiagram
    class ChangeNotifier

    class Baby {
        +String name
        +DateTime birthDate
    }

    class BabyController {
        +Baby baby
        +update(baby) Future~void~
    }

    class FavoritesController {
        +isFavorite(id) bool
        +toggle(id) Future~void~
    }

    class ThemeController {
        +bool isDark
        +ThemeMode themeMode
        +toggleDark() Future~void~
    }

    ChangeNotifier <|-- BabyController
    ChangeNotifier <|-- FavoritesController
    ChangeNotifier <|-- ThemeController
    BabyController --> Baby : baby

    note for ChangeNotifier "Classe do Flutter/provider; base para os controladores"
    note for BabyController "Persiste nome e data de nascimento via SharedPreferences"
    note for FavoritesController "Persiste IDs favoritos; simula disponibilidade offline"
    note for ThemeController "Persiste a preferência de modo escuro"
    note for Baby "Modelo detalhado em diagrama-models.md"
```

## Telas principais

Telas de navegação do app e a casca `RootShell`, que mantém uma pilha de navegação por aba. Widgets visuais auxiliares e telas secundárias foram omitidos para manter o diagrama legível.

```mermaid
classDiagram
    class RootShell {
        +build(context) Widget
    }

    class SplashScreen {
        +VoidCallback onDone
    }

    class HomeScreen {
        +onNavigateToTab Function
    }

    class ContentScreen

    class BlhScreen

    class SettingsScreen

    class BankDetailScreen {
        +MilkBank bank
    }

    RootShell ..> HomeScreen : aba Início
    RootShell ..> ContentScreen : aba Conteúdos
    RootShell ..> BlhScreen : aba BLH
    RootShell ..> SettingsScreen : aba Config.
    BlhScreen ..> BankDetailScreen : abre detalhes

    note for RootShell "Mantém uma pilha de navegação independente por aba"
    note for SplashScreen "Exibida antes de RootShell por _AppRoot (app.dart)"
    note for HomeScreen "Consome BabyController e FavoritesController via Provider"
    note for ContentScreen "Consome FavoritesController; artigos agrupados por categoria"
    note for SettingsScreen "Consome BabyController e ThemeController"
    note for BankDetailScreen "Recebe o MilkBank selecionado pela BlhScreen"
```
