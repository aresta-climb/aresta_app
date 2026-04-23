import os
import sys
import glob
import hashlib
import argparse
from grpc_tools import protoc

def get_protos_hash(proto_files):
    """Calcula um hash único de todos os arquivos .proto para detectar mudanças."""
    hasher = hashlib.sha256()
    # Ordena para garantir que a ordem dos arquivos não afete o hash
    for f in sorted(proto_files):
        with open(f, 'rb') as fp:
            hasher.update(fp.read())
    return hasher.hexdigest()

def generate_protos(argv=None):
    """
    Gera arquivos do Protobuf para Python e Dart.
    argv: Lista de argumentos (ex: ['-f']). Se None, usa sys.argv[1:].
    """
    parser = argparse.ArgumentParser(description="Gera arquivos do Protobuf para Python e Dart.")
    parser.add_argument("-f", "--force", action="store_true", help="Força a re-geração dos arquivos, ignorando o cache de hash.")
    args = parser.parse_args(argv)

    root_dir = os.path.dirname(os.path.abspath(__file__))
    proto_dir = os.path.join(root_dir, "proto")
    generated_dir = os.path.join(proto_dir, "generated")
    hash_file = os.path.join(generated_dir, ".protos_hash")
    
    # Garante que o diretório gerado ("generated") exista
    os.makedirs(generated_dir, exist_ok=True)
    
    # Encontra todos os arquivos .proto
    proto_files = glob.glob(os.path.join(proto_dir, "*.proto"))
    if not proto_files:
        print("Nenhum arquivo .proto encontrado em", proto_dir)
        sys.exit(1)

    # Computa o hash atual dos protos
    current_hash = get_protos_hash(proto_files)

    # Verifica se precisa refazer o build (se não for forçado)
    if not args.force and os.path.exists(hash_file):
        with open(hash_file, "r") as f:
            saved_hash = f.read().strip()
        
        # Além de bater o hash, vamos garantir que existe pelo menos algum arquivo gerado além do __init__.py e .protos_hash
        gerados = [f for f in os.listdir(generated_dir) if f.endswith('_pb2.py') or f.endswith('.pb.dart')]
        
        if current_hash == saved_hash and gerados:
            print("Nenhuma alteração nos arquivos .proto. Compilação pulada.")
            # Garante o __init__.py se tiver sido removido acidentalmente
            init_path = os.path.join(generated_dir, "__init__.py")
            if not os.path.exists(init_path):
                with open(init_path, "w") as f:
                    f.write("")
            return

    # Cria o arquivo __init__.py para que o Python trate a pasta "generated" como um módulo
    init_path = os.path.join(generated_dir, "__init__.py")
    if not os.path.exists(init_path):
        with open(init_path, "w") as f:
            f.write("")

    print(f"Foram encontrados {len(proto_files)} arquivos .proto. Gerando os arquivos...")

    # Geração dos arquivos Python e Dart em uma única chamada usando grpc_tools.protoc
    protoc_args = [
        "grpc_tools.protoc",
        f"-I{proto_dir}",
        f"--python_out={generated_dir}",
        f"--dart_out={generated_dir}"
    ] + proto_files

    print("Executando o protoc para Python e Dart...")
    exit_code = protoc.main(protoc_args)
    if exit_code != 0:
        print("Erro ao gerar os arquivos do Protobuf.", file=sys.stderr)
        sys.exit(exit_code)
    else:
        print("Arquivos do Python e Dart gerados com sucesso.")
        # Salva o arquivo de hash
        with open(hash_file, "w") as f:
            f.write(current_hash)

def main():
    generate_protos()

if __name__ == "__main__":
    main()
