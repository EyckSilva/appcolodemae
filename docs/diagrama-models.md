# Diagrama de classes — Modelos

Entidades de domínio do app: dados do bebê, catálogo de conteúdos e bancos de leite. As coleções globais (`articles`, `milkBanks` e `babyPhaseInfo`) são indicadas em notas para não poluir o diagrama.

```mermaid
classDiagram
    class BabyPhase {
        <<enumeration>>
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
        +toJson() Map~String, dynamic~
        +fromJson(json) Baby$
    }

    class ArticleCategory {
        <<enumeration>>
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
        <<enumeration>>
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
