import Flutter
import UIKit
import AuthenticationServices
import CryptoKit
import Security
#if canImport(workmanager_apple)
import workmanager_apple
#elseif canImport(workmanager)
import workmanager
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, ASWebAuthenticationPresentationContextProviding {
  private var resultadoPendenteFoto: FlutterResult?
  private var resultadoPendenteApple: FlutterResult?
  private var nonceBrutoAppleAtual: String?
  private var sessaoWebAuthGoogle: ASWebAuthenticationSession?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "solicitarIdTokenApple":
#if targetEnvironment(simulator)
        if let cfgSmoke = self.obterConfiguracaoSmokeSimulator() {
          self.solicitarIdTokenLoopbackSmoke(
            servidorUrl: cfgSmoke.servidorUrl,
            webClientId: "smoke-apple-client",
            result: result
          )
          return
        }
#endif
        self.iniciarLoginNativoApple(result: result)
      case "solicitarIdTokenGoogle":
#if targetEnvironment(simulator)
        if let cfgSmoke = self.obterConfiguracaoSmokeSimulator() {
          self.solicitarIdTokenLoopbackSmoke(
            servidorUrl: cfgSmoke.servidorUrl,
            webClientId: (args?["webClientId"] as? String) ?? "smoke-google-client",
            result: result
          )
          return
        }
#endif
        let urlAutorizacao = (args?["urlAutorizacaoPkce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let esquemaCallback = (args?["esquemaCallback"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "aresta"
        self.iniciarSessaoWebGooglePkce(
          urlAutorizacao: urlAutorizacao,
          esquemaCallback: esquemaCallback,
          result: result
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }

#if targetEnvironment(simulator)
    let canalSmokeCi = FlutterMethodChannel(
      name: "app.escalada.croquis/smoke_ci",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canalSmokeCi.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(["ativo": false])
        return
      }
      if call.method == "obterConfiguracaoSmoke" {
        if let cfg = self.obterConfiguracaoSmokeSimulator() {
          result([
            "ativo": true,
            "servidorUrl": cfg.servidorUrl,
            "token": cfg.token
          ])
        } else {
          result(["ativo": false])
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
#endif
  }

#if targetEnvironment(simulator)
  private func obterConfiguracaoSmokeSimulator() -> (servidorUrl: String, token: String)? {
    let env = ProcessInfo.processInfo.environment
    let srvBruto = (env["ARESTA_SMOKE_SERVER"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let tokBruto = (env["ARESTA_SMOKE_TOKEN"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !srvBruto.isEmpty, !tokBruto.isEmpty,
          let comps = URLComponents(string: srvBruto),
          comps.scheme == "http",
          let host = comps.host?.lowercased(),
          let port = comps.port, port > 0 else {
      return nil
    }
    let permitidos: Set<String> = ["127.0.0.1", "localhost", "10.0.2.2"]
    guard permitidos.contains(host) else {
      return nil
    }
    return ("http://\(host):\(port)", tokBruto)
  }

  private func solicitarIdTokenLoopbackSmoke(
    servidorUrl: String,
    webClientId: String,
    result: @escaping FlutterResult
  ) {
    guard let url = URL(string: "\(servidorUrl)/__smoke__/oidc-token") else {
      result(["erro": "URL inválida do servidor smoke."])
      return
    }
    let rawNonce = gerarNonceAleatorio()
    let nonceHash = sha256Hex(rawNonce)
    var requisicao = URLRequest(url: url)
    requisicao.httpMethod = "POST"
    requisicao.timeoutInterval = 10
    requisicao.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let payload: [String: Any] = [
      "rawNonce": rawNonce,
      "nonceHash": nonceHash,
      "webClientId": webClientId
    ]
    requisicao.httpBody = try? JSONSerialization.data(withJSONObject: payload)

    URLSession.shared.dataTask(with: requisicao) { dados, resposta, erro in
      DispatchQueue.main.async {
        if let erro = erro {
          result(["erro": erro.localizedDescription])
          return
        }
        guard let http = resposta as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let dados = dados,
              let json = (try? JSONSerialization.jsonObject(with: dados)) as? [String: Any],
              let idToken = json["idToken"] as? String else {
          result(["erro": "Falha ao obter idToken do servidor local de smoke."])
          return
        }
        result([
          "idToken": idToken,
          "nonce": rawNonce,
          "nomeExibicao": (json["nomeExibicao"] as? String) ?? "Escalador Smoke CI",
          "cancelado": false
        ])
      }
    }.resume()
  }
#endif

  private func iniciarSessaoWebGooglePkce(
    urlAutorizacao: String,
    esquemaCallback: String,
    result: @escaping FlutterResult
  ) {
    guard !urlAutorizacao.isEmpty,
          let urlAuth = URL(string: urlAutorizacao),
          !esquemaCallback.isEmpty else {
      result(["erro": "URL de autorização PKCE ausente ou inválida."])
      return
    }

    DispatchQueue.main.async {
      self.sessaoWebAuthGoogle?.cancel()
      let sessao = ASWebAuthenticationSession(
        url: urlAuth,
        callbackURLScheme: esquemaCallback
      ) { [weak self] callbackURL, error in
        self?.sessaoWebAuthGoogle = nil
        if let erroSessao = error as? ASWebAuthenticationSessionError,
           erroSessao.code == .canceledLogin {
          result(["cancelado": true])
          return
        }
        if let error = error {
          result(["erro": error.localizedDescription])
          return
        }
        guard let callbackURL = callbackURL else {
          result(["erro": "Retorno vazio na sessão web de autenticação."])
          return
        }
        result([
          "callbackUrl": callbackURL.absoluteString,
          "cancelado": false
        ])
      }
      sessao.presentationContextProvider = self
      sessao.prefersEphemeralWebBrowserSession = false
      self.sessaoWebAuthGoogle = sessao
      if !sessao.start() {
        self.sessaoWebAuthGoogle = nil
        result(["erro": "Não foi possível iniciar ASWebAuthenticationSession."])
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

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
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
      callback?(["erro": "Credencial Apple sem identityToken válido."])
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
      callback?(["erro": error.localizedDescription])
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
    let largura = img.size.width
    let altura = img.size.height
    let lado = min(largura, altura)
    guard lado > 0 else {
      callback?(nil)
      return
    }
    let origemX = (largura - lado) / 2.0
    let origemY = (altura - lado) / 2.0
    let escala = 256.0 / lado
    let tamanho = CGSize(width: 256, height: 256)
    UIGraphicsBeginImageContextWithOptions(tamanho, true, 1.0)
    img.draw(
      in: CGRect(
        x: -origemX * escala,
        y: -origemY * escala,
        width: largura * escala,
        height: altura * escala
      )
    )
    let redimensionada = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    if let dados = redimensionada?.jpegData(compressionQuality: 0.88) {
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
