## 1. Testes e Lógica de Faixas de Zoom e Renderização de Marcadores (TDD)

- [x] 1.1 Escrever testes unitários em `frontend/test/view_functions/mapa/mapa_marker_test.dart` para criação de marcadores compactos com truncamento de texto (`createCustomMarkerBitmapWithText` com largura contida e reticências) e verificar que os testes falham inicialmente (Red).
- [x] 1.2 Atualizar `createCustomMarkerBitmapWithText` e `createCustomMarkerBitmap` em `frontend/lib/view_functions/mapa/mapa_marker.dart` suportando dimensões ajustadas, tipografia proporcional e truncamento com reticências para nomes extensos, fazendo os testes passarem (Green).
- [x] 1.3 Escrever testes unitários e de widget em `frontend/test/view_functions/mapa/mapa_global_functions_test.dart` cobrindo a resolução de faixas de zoom (`FaixaZoomMapa`: Macro < 7.0, Regional 7.0 a 11.0, Local >= 11.0), seleção adequada de ícones e ausência de texto nas faixas Macro e Regional (Red).
- [x] 1.4 Implementar `FaixaZoomMapa`, função `obterFaixaZoom` e atualizar `buildMapMarkers` em `frontend/lib/view_functions/mapa/mapa_global_functions.dart` para retornar os marcadores apropriados a cada faixa de zoom, fazendo os testes passarem (Green).

## 2. Integração e Transições Reativas no Mapa Global (TDD)

- [x] 2.1 Escrever testes de widget em `frontend/test/pages/mapa_global_test.dart` validando que `MapaGlobalPage` inicializa os ícones das faixas e que a câmera só atualiza o estado quando transicionar entre as faixas de zoom (Red).
- [x] 2.2 Atualizar `MapaGlobalPage` em `frontend/lib/pages/mapa_global.dart` para armazenar em cache os ícones das faixas (`macroIcon`, `regionalIcon`, `textIcons`) e filtrar as mudanças no `onCameraMove` exclusivamente para fronteiras de faixa, fazendo os testes passarem (Green).

## 3. Verificação, Cobertura 100% e Documentação

- [x] 3.1 Executar a suíte de testes de mapa com `flutter test test/view_functions/mapa/ test/pages/mapa_global_test.dart` garantindo 100% de testes passando e ausência de regressões.
- [x] 3.2 Atualizar documentação e docstrings `///` em português explicando a arquitetura das faixas de zoom e as decisões de desempenho e renderização.
