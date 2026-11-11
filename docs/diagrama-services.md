# Diagrama de classes — Serviços e estado

Controladores que estendem `ChangeNotifier` e concentram o estado global do app. Cada um persiste sua preferência com `SharedPreferences` e notifica a UI por `notifyListeners()`.

```mermaid
classDiagram
    class ChangeNotifier {
        <<abstract>>
    }

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
