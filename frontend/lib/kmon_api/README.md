# kmon-format
Formato de dado para a database de croquis KMon.

## Build

Após qualquer modificação em algum arquivo .proto, é necessário gerar os arquivos Python e Dart.

Para isso, primeiro instale as dependências python:

```bash
pip install -r requirements.txt
```

Após isso, instale o executável do Dart na sua máquina, e o plugin para o protoc. Instruções [aqui](https://pub.dev/packages/protoc_plugin), mas basicamente rode:

```bash
dart pub global activate protoc_plugin
```

Por fim, rode o build para atualizar os arquivos gerados:

```bash
python build.py
```
