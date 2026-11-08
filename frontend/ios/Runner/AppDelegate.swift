import Flutter
import UIKit
import AuthenticationServices
import CryptoKit
import Security
import GoogleMaps
#if canImport(workmanager_apple)
import workmanager_apple
#elseif canImport(workmanager)
import workmanager
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  private var resultadoPendenteFoto: FlutterResult?
  private var resultadoPendenteApple: FlutterResult?
  private var nonceBrutoAppleAtual: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Chave oficial iOS do projeto app-escalada-croquis (mesma de GoogleService-Info.plist, com Maps SDK for iOS ativo)
    GMSServices.provideAPIKey("AIzaSyBEN0WNF_d3mo1NSNyz1INq_YDedDDIhpo")
#if canImport(workmanager_apple)
    WorkmanagerPlugin.registerLaunchHandlers()
#elseif canImport(workmanager)
    WorkmanagerPlugin.registerLaunchHandlers()
#endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let canalMidia = FlutterMethodChannel(
      name: "app.escalada.croquis/seletor_midia",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canalMidia.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(nil)
        return
      }
      if call.method == "selecionarFotoPerfil" {
        self.apresentarSeletorFoto(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let canalAutenticacao = FlutterMethodChannel(
      name: "app.escalada.croquis/autenticacao_nativa",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canalAutenticacao.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "solicitarIdTokenApple":
        self.iniciarLoginNativoApple(result: result)
      case "solicitarIdTokenGoogle":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func iniciarLoginNativoApple(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      self.resultadoPendenteApple?(nil)
      self.resultadoPendenteApple = result
      let nonceBruto = self.gerarNonceAleatorio()
      self.nonceBrutoAppleAtual = nonceBruto

      let provedor = ASAuthorizationAppleIDProvider()
      let requisicao = provedor.createRequest()
      requisicao.requestedScopes = [.fullName, .email]
      requisicao.nonce = self.sha256Hex(nonceBruto)

      let controlador = ASAuthorizationController(authorizationRequests: [requisicao])
      controlador.delegate = self
      controlador.presentationContextProvider = self
      controlador.performRequests()
    }
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.window ?? UIWindow()
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    let callback = resultadoPendenteApple
    let nonce = nonceBrutoAppleAtual
    resultadoPendenteApple = nil
    nonceBrutoAppleAtual = nil

    guard let credencial = authorization.credential as? ASAuthorizationAppleIDCredential,
          let dadosToken = credencial.identityToken,
          let idToken = String(data: dadosToken, encoding: .utf8) else {
      callback?(nil)
      return
    }

    var partesNome: [String] = []
    if let nome = credencial.fullName?.givenName, !nome.isEmpty {
      partesNome.append(nome)
    }
    if let sobrenome = credencial.fullName?.familyName, !sobrenome.isEmpty {
      partesNome.append(sobrenome)
    }
    let nomeCompleto = partesNome.isEmpty ? nil : partesNome.joined(separator: " ")

    callback?([
      "idToken": idToken,
      "nonce": nonce as Any,
      "nomeExibicao": nomeCompleto as Any,
      "cancelado": false
    ])
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    let callback = resultadoPendenteApple
    resultadoPendenteApple = nil
    nonceBrutoAppleAtual = nil

    if let erroAuth = error as? ASAuthorizationError, erroAuth.code == .canceled {
      callback?(["cancelado": true])
    } else {
      callback?(nil)
    }
  }

  private func gerarNonceAleatorio(tamanho: Int = 32) -> String {
    let caracteres = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var resultado = ""
    var bytesRestantes = tamanho
    while bytesRestantes > 0 {
      var aleatorios = [UInt8](repeating: 0, count: 16)
      let status = SecRandomCopyBytes(kSecRandomDefault, aleatorios.count, &aleatorios)
      if status != errSecSuccess {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
      }
      for byte in aleatorios where bytesRestantes > 0 {
        if Int(byte) < caracteres.count {
          resultado.append(caracteres[Int(byte)])
          bytesRestantes -= 1
        }
      }
    }
    return resultado
  }

  private func sha256Hex(_ texto: String) -> String {
    let dados = Data(texto.utf8)
    let resumo = SHA256.hash(data: dados)
    return resumo.compactMap { String(format: "%02x", $0) }.joined()
  }

  private func apresentarSeletorFoto(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let rootVC = self.window?.rootViewController,
            UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
        result(nil)
        return
      }
      self.resultadoPendenteFoto?(nil)
      self.resultadoPendenteFoto = result
      let picker = UIImagePickerController()
      picker.sourceType = .photoLibrary
      picker.allowsEditing = true
      picker.delegate = self
      rootVC.present(picker, animated: true)
    }
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    let callback = resultadoPendenteFoto
    resultadoPendenteFoto = nil
    picker.dismiss(animated: true)
    let imagem = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
    guard let img = imagem else {
      callback?(nil)
      return
    }
    let tamanho = CGSize(width: 256, height: 256)
    UIGraphicsBeginImageContextWithOptions(tamanho, true, 1.0)
    img.draw(in: CGRect(origin: .zero, size: tamanho))
    let redimensionada = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    if let dados = redimensionada?.jpegData(compressionQuality: 0.82) {
      callback?(FlutterStandardTypedData(bytes: dados))
    } else {
      callback?(nil)
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    let callback = resultadoPendenteFoto
    resultadoPendenteFoto = nil
    picker.dismiss(animated: true)
    callback?(nil)
  }
}
