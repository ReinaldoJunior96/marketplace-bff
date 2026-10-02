# TerraShop (flutter_marketplace_bff)

App Flutter cliente do monorepo `marketplace-bff` (o BFF e os serviços ficam em `../apps` e `../packages`).

## Comandos

- `flutter pub get` — instalar dependências
- `flutter analyze` — lint/análise estática
- `flutter test` — rodar testes
- `flutter run` — rodar o app
- `dart run build_runner build --delete-conflicting-outputs` — gerar código (quando houver freezed/json_serializable/mockito)

## Skills (em `.claude/skills/`, oficiais de flutter/agent-plugins)

Use a skill correspondente sempre que a tarefa se encaixar — ela tem prioridade sobre conhecimento genérico:

| Tarefa | Skill |
|---|---|
| Nova feature, estruturar/refatorar camadas | `flutter-apply-architecture-best-practices` |
| Chamar a API do BFF (REST) | `flutter-use-http-package` |
| Models com `fromJson`/`toJson` | `flutter-implement-json-serialization` |
| Navegação / rotas / deep link | `flutter-setup-declarative-routing` |
| Layout para celular + tablet/desktop | `flutter-build-responsive-layout` |
| Erros de layout (RenderFlex overflow, unbounded) | `flutter-fix-layout-issues` |
| Erro em runtime com stack trace | `dart-fix-runtime-errors` |
| Testes de widget | `flutter-add-widget-test` |
| Testes unitários (ViewModel, Repository) | `dart-add-unit-test` + `dart-generate-test-mocks` |
| Fluxos ponta a ponta | `flutter-add-integration-test` |
| Preview de widget novo | `flutter-add-widget-preview` |
| i18n | `flutter-setup-localization` |
| `pub get` falhando por conflito de versão | `dart-resolve-package-conflicts` |
| Antes de concluir qualquer mudança | `dart-run-static-analysis` |
| Parsing de JSON polimórfico, sealed classes | `dart-use-pattern-matching` |
| Doc comments `///` | `dart-write-documentation` |

`flutter-fix-layout-issues`, `dart-fix-runtime-errors` e `flutter-add-integration-test` usam o Dart MCP server (`.mcp.json`).

## Arquitetura

Seguir `flutter-apply-architecture-best-practices` (MVVM em camadas):

```
lib/
├── data/{models,repositories,services}/
├── domain/{models,use_cases}/      # use_cases só se a lógica for complexa/reutilizada
└── ui/
    ├── core/                        # widgets compartilhados, tema
    └── features/<feature>/{view_models,views}/
```

- Views sem lógica de negócio; estado em ViewModels (`ChangeNotifier`) injetados com Repositories.
- Toda chamada à API passa por Service → Repository. Widgets nunca chamam HTTP direto.
- Um widget público por arquivo; widgets privados com prefixo `_`.
- Valores monetários como inteiro em centavos, nunca `double`.

## Integração com o BFF

- Contratos mobile (fonte: `../apps/bff/src/modules/mobile/`):
  - `GET /api/mobile/home` → `{products: [{id, name, price, thumbnail}]}`
  - `GET /api/mobile/products/:id` → detalhe com `description`, `category`, `stock`
  - `POST /api/mobile/orders` (com `x-correlation-id`) e `GET /api/mobile/orders` (`itemsCount` = linhas do pedido, não unidades; a lista não filtra por cliente)
  - `GET /api/mobile/orders/:id/timeline` e `GET /api/mobile/notifications?customerId=` — montados a partir do Audit Service; viram listas vazias se o Audit cair
- Cliente fixo `BffConfig.demoCustomerId` (não há login). Pagamento é simulado no app; só a criação do pedido é real.
- Erros seguem `{statusCode, error, message, correlationId}` → viram `BffException` em `BffApiClient`.
- `price` chega em reais (`double`) e é convertido para centavos no Repository.
- Base URL em `lib/config/bff_config.dart`: emulador Android usa `10.0.2.2`, demais `localhost`; aparelho físico: `--dart-define=BFF_BASE_URL=http://<ip>:3000`.
- Subir o backend: `docker compose up --build` na raiz do monorepo.

## Padrões já estabelecidos

- Estado de tela como `sealed class` (`HomeLoading`/`HomeLoaded`/`HomeFailure`) + `switch` exaustivo na View.
- Injeção manual: repositórios criados em `main.dart`; estado global (carrinho, notificações, aba atual, navigator) exposto pelo `AppScope` (`InheritedWidget`) em `lib/ui/core/app_scope.dart`. ViewModels de tela são criados no `didChangeDependencies` da tela e descartados no `dispose`.
- Navegação: `AppPageRoute` (padrão), `CircularRevealRoute` (splash → app, pagamento → confirmação), Hero da foto com `productHeroTag(id)`. `AppScope.goToTab` volta à raiz e troca a aba.
- Animações de entrada com `FadeSlideIn` + `AppMotion` (ela espera a transição da rota terminar); loops (`Shimmer`, indicadores) respeitam "reduzir movimento".
- Ícones só do Font Awesome (`FaIcon`); ilustrações via `Illustration(AppIllustration.x)` (unDraw recolorido em `assets/illustrations/`); fontes Fraunces (títulos) e DM Sans (texto).
- Tema e tokens em `lib/ui/core/theme/` (`AppColors`, `AppSpacing`, `AppTheme`) — paleta terrosa + pastel; não usar cores soltas nas Views.
- Testes: `MockClient` de `package:http/testing.dart` para HTTP e fakes em `test/helpers/` para repositórios (sem mockito). Respostas mockadas com acento usam `http.Response.bytes(utf8.encode(...))`.
- Testes de tela usam `createTestDependencies().app(...)` (`test/helpers/test_app.dart`) para ter `AppScope`.
- Layout: não usar `Spacer` ao lado de `Text` em `Row` — use `Expanded`/`Flexible` no texto (os testes rodam com fonte mais larga e pegam o overflow).
- Jornada E2E contra o BFF real: `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/shopping_journey_test.dart -d <device>`; screenshots em `screenshots/` (ignorado), seleção do README em `docs/screenshots/`.
- Widget tests: Finders reutilizados devem ser getters (finders cacheiam resultado); chamar `tester.pump()` após `scrollUntilVisible`; cobrir fonte grande (`textScaleFactorTestValue`) em telas novas.

## Regras

- Não adicionar pacotes (state management, DI, etc.) sem aprovação do usuário.
- Nunca editar `*.g.dart` / `*.freezed.dart` / `*.mocks.dart` à mão — rodar build_runner.
- Uma tarefa só está pronta quando `flutter analyze` não tem issues e `flutter test` passa.
- Commits em Conventional Commits: `type(scope): resumo no imperativo` (padrão do monorepo).
