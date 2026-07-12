## 1. Atualização de Constantes

- [x] 1.1 Atualizar `kDataVersion` para `4` no arquivo `frontend/lib/constants/network_constants.dart`.

## 2. Adaptação do Mapa Interativo

- [x] 2.1 Renomear uso de `.circular` para `.circulo` no `switch` de `AreaHelper.getAreaInfo` (`frontend/lib/pages/mapa_interativo.dart`).
- [x] 2.2 Renomear uso de `.box` para `.retangulo` no mesmo `switch`.
- [x] 2.3 Renomear uso de `.areaLivre` para `.poligono` no mesmo `switch`.
- [x] 2.4 Adicionar um novo `case` para `Mapa_PontoDeInteresse_TipoArea.quadrado` em `AreaHelper.getAreaInfo`, lendo `ponto.quadrado` (x, y, lado) e montando a geometria correspondente.
