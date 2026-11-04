import Flutter
import UIKit
import GoogleMaps
#if canImport(workmanager_apple)
import workmanager_apple
#elseif canImport(workmanager)
import workmanager
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private var resultadoPendenteFoto: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyA2wcm3xW9ImUYiIRGgPPrGzcwhnAN7HLU")
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
