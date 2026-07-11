# flutter_nearby_connections_plus

This is a maintained fork of the original flutter_nearby_connections package with bug fixes and improvements.

## Credits
- **Original package**: [flutter_nearby_connections](https://pub.dev/packages/flutter_nearby_connections) by Nankai
- **Additional fixes from**: [champeauxr's fork](https://github.com/champeauxr/flutter_nearby_connections)
- **Maintained by**: [Edgar Ladeira](https://github.com/edgarladeira)

#### Plugin: [https://pub.dev/packages/flutter_nearby_connections_plus](https://pub.dev/packages/flutter_nearby_connections)

## Original License
This package is based on the original work by Nankai, licensed under BSD 2-Clause License.

## ✅ Tested Environment

This package has been thoroughly tested and confirmed working with:
- **Flutter**: 3.22.0 (revision 5dcb86f68f)
- **Dart**: 3.4.0
- **Engine**: f6344b75dc
- **DevTools**: 2.34.3

> **Note**: While this package should work with other Flutter versions, the above configuration is verified to work correctly with all features.


## Installation
```yaml
dependencies:
  flutter_nearby_connections_plus: ^1.2.2
```

### Flutter plugin supports peer-to-peer connectivity and discovers nearby devices for Android and IOS
The flutter_nearby_connections plugin supports the discovery of services provided by nearby devices.
Moreover, the flutter_nearby_connections plugin also supports communicating with those services through message-based data, streaming data, and resources (such as files). The framework uses infrastructure Wi-Fi networks, peer-to-peer Wi-Fi and Bluetooth Personal Area Networks (PAN) for the underlying transport over UDP.
The project is based on

#### Android

[Nearby Connections API](https://developers.google.com/nearby/connections/overview) (Bluetooth & hotspot) Support [Strategy](https://pub.dev/documentation/flutter_nearby_connections/latest/flutter_nearby_connections/Strategy-class.html): ***Strategy.P2P_CLUSTER***, ***Strategy.P2P_STAR***, ***Strategy.P2P_POINT_TO_POINT***

[Wi-Fi P2P](https://developer.android.com/guide/topics/connectivity/wifip2p) (only wifi hotspot no internet) Support [Strategy](https://pub.dev/documentation/flutter_nearby_connections/latest/flutter_nearby_connections/Strategy-class.html): ***Strategy.Wi_Fi_P2P***

#### IOS

[Multipeer Connectivity](https://developer.apple.com/documentation/multipeerconnectivity)

We use the NearbyConnections API, but Flutter methods are based on the concept of [Multipeer Connectivity IOS](https://developer.apple.com/documentation/multipeerconnectivity).

Methods provided:

startAdvertisingPeer, startBrowsingForPeers, stopAdvertisingPeer

We separate the dependencies of the MCNearbyServiceAdvertiser, MCNearbyServiceBrowser and MCSession classes.  All of the methods will be implemented in the NearbyService class.

### Noted

* ##### Android doesn't support emulator only support real devices

* ##### On iOS 14, need to define in Info.plist

``` xml
    <key>NSBonjourServices</key>
    <array>
        <string>_{YOUR_SERVICE_TYPE}._tcp</string>
    </array>
    <key>UIRequiresPersistentWiFi</key>
    <true/>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>{YOUR_DESCRIPTION}</string>
```

in this case, YOUR_SERVICE_TYPE is 'mp-connection' (you can define it)

``` dart
nearbyService.init(
        serviceType: 'mp-connection',
        strategy: Strategy.P2P_CLUSTER,
```

#### Test on IOS device

![The example app running in IOS](https://github.com/VNAPNIC/flutter_nearby_connections/blob/master/screen.gif?raw=true)

#### Test on Android device

![The example app running in Android](https://github.com/VNAPNIC/flutter_nearby_connections/blob/master/android-screen.gif?raw=true)

## 🐛 Issues
If you encounter any issues, please file them in the [issue tracker](https://github.com/edgarladeira/flutter_nearby_connections_plus/issues).

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request