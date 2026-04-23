import os
import sys
import tempfile
import unittest
from unittest.mock import patch

import importlib.util

# Localiza o build.py desta pasta para evitar conflito com o build.py da raiz
_build_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build.py")
_spec = importlib.util.spec_from_file_location("kmon_api_build", _build_path)
build = importlib.util.module_from_spec(_spec)
# Adiciona o módulo ao sys.modules para que as patches de string "@patch('build...')" continuem funcionando
sys.modules["build"] = build
_spec.loader.exec_module(build)

class TestBuild(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.proto_dir = os.path.join(self.temp_dir.name, "proto")
        self.generated_dir = os.path.join(self.proto_dir, "generated")
        os.makedirs(self.proto_dir)
        
        # Cria um arquivo .proto dummy
        self.dummy_proto = os.path.join(self.proto_dir, "dummy.proto")
        with open(self.dummy_proto, "w") as f:
            f.write('syntax = "proto3";\nmessage Dummy { string id = 1; }\n')

    def tearDown(self):
        self.temp_dir.cleanup()

    @patch('build.protoc.main')
    @patch('build.os.path.abspath')
    def test_successful_build(self, mock_abspath, mock_protoc):
        # Configura o mock do abspath para apontar para o diretório temporário
        mock_abspath.return_value = os.path.join(self.temp_dir.name, "build.py")
        mock_protoc.return_value = 0 # Simula sucesso
        
        # 1ª Execução: não existe .protos_hash nem generated_dir, deve executar normalmente
        try:
            # Passamos argv=[] para evitar que o parser leia os argumentos do pytest (sys.argv)
            build.generate_protos(argv=[])
        except SystemExit:
            self.fail("generate_protos() chamou sys.exit() de forma inesperada na 1ª execução")
            
        mock_protoc.assert_called_once()
        self.assertTrue(os.path.exists(os.path.join(self.generated_dir, ".protos_hash")))
        
        # Simula a criação do output pelo protoc
        with open(os.path.join(self.generated_dir, "dummy_pb2.py"), "w") as f:
            f.write("# dummy")
            
        # 2ª Execução: o proto não mudou, o hash deve ser igual e ter os arquivos gerados
        # Portanto, o protoc não deve ser chamado novamente
        build.generate_protos(argv=[])
        self.assertEqual(mock_protoc.call_count, 1)

        # 3ª Execução: o proto muda, deve invalidar o hash e recompilar
        with open(self.dummy_proto, "a") as f:
            f.write('// Edição\n')
            
        build.generate_protos(argv=[])
        self.assertEqual(mock_protoc.call_count, 2)

    @patch('build.protoc.main')
    @patch('build.os.path.abspath')
    def test_force_flag(self, mock_abspath, mock_protoc):
        mock_abspath.return_value = os.path.join(self.temp_dir.name, "build.py")
        mock_protoc.return_value = 0
        
        # 1. Execução normal
        build.generate_protos(argv=[])
        self.assertEqual(mock_protoc.call_count, 1)
        
        # Simula a criação do output
        with open(os.path.join(self.generated_dir, "dummy_pb2.py"), "w") as f:
            f.write("# dummy")
            
        # 2. Execução sem mudanças (deve pular)
        build.generate_protos(argv=[])
        self.assertEqual(mock_protoc.call_count, 1)
        
        # 3. Execução com -f (deve forçar mesmo sem mudanças)
        build.generate_protos(argv=['-f'])
        self.assertEqual(mock_protoc.call_count, 2)
        
        # 4. Execução com --force (deve forçar mesmo sem mudanças)
        build.generate_protos(argv=['--force'])
        self.assertEqual(mock_protoc.call_count, 3)

    @patch('build.os.path.abspath')
    def test_no_proto_files(self, mock_abspath):
        mock_abspath.return_value = os.path.join(self.temp_dir.name, "build.py")
        
        # Remove o dummy.proto
        os.remove(self.dummy_proto)
        
        with self.assertRaises(SystemExit) as cm:
            build.generate_protos(argv=[])
        self.assertEqual(cm.exception.code, 1)

    @patch('build.protoc.main', return_value=1) # Simula falha no protoc
    @patch('build.os.path.abspath')
    def test_protoc_failure(self, mock_abspath, mock_protoc):
        mock_abspath.return_value = os.path.join(self.temp_dir.name, "build.py")
        
        with self.assertRaises(SystemExit) as cm:
            build.generate_protos(argv=[])
        self.assertEqual(cm.exception.code, 1)

if __name__ == '__main__':
    unittest.main()
