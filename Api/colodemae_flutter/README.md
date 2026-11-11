# Colo de Mãe — Como Executar o Projeto

## 1. Clonar o repositório

```bash
git clone URL_DO_REPOSITORIO
```

## 2. Entrar na pasta do projeto

```bash
cd colodemae_flutter
```

## 3. Instalar as dependências

```bash
flutter pub get
```

## 4. Verificar o ambiente Flutter

```bash
flutter doctor
```

## 5. Executar o projeto

**Web (Google Chrome):**

```bash
flutter run -d chrome
```

**Android (emulador ou dispositivo conectado):**

```bash
flutter devices
flutter run
```

## 6. Gerar a versão Web

```bash
flutter build web --release
```

## 7. Publicar no Firebase Hosting

```bash
firebase login
firebase deploy --only hosting
```

## 8. Atualizar o projeto pelo GitHub

```bash
git pull origin main
flutter pub get
flutter run -d chrome
```

---

**Observação:** o projeto utiliza Firebase Authentication e Cloud Firestore. É necessário ter a configuração do Firebase disponível no ambiente para executar as funcionalidades integradas.