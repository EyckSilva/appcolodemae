# Diagrama de classes — Telas principais

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
