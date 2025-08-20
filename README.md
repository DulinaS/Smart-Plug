# 🔌 Smart Plug Flutter App

A comprehensive IoT smart plug control and energy monitoring application built with Flutter, featuring real-time device control, energy analytics, scheduling, and Sri Lankan CEB tariff integration.

## 📱 Features

### ✅ Core Functionality

- **User Authentication & Profiles** - Secure login/registration with AWS Cognito
- **Device Management** - Add, configure, and control smart plugs
- **Real-time Control** - ON/OFF control with instant feedback
- **Manual Button Sync** - Physical button state syncs with app
- **Live Monitoring** - Real-time voltage, current, power, and energy readings
- **Energy Analytics** - Daily, weekly, monthly consumption charts
- **Cost Calculation** - Automatic bill calculation using Sri Lankan CEB tariffs
- **Smart Scheduling** - Automated ON/OFF based on time/conditions
- **Safety Alerts** - Overcurrent, overvoltage, and offline notifications
- **Multi-language** - English, Sinhala, Tamil support
- **Dark/Light Theme** - Modern UI with theme switching
- **Offline Mode** - Manual button works without internet

### 🏗️ Architecture

- **Clean Architecture** with feature-first folder structure
- **Riverpod** for state management
- **Go Router** for navigation
- **Repository Pattern** for data access
- **MQTT** for real-time communication
- **REST API** for CRUD operations

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.10.0+
- Dart SDK 3.0.0+
- Android Studio / VS Code
- AWS Account (for backend services)
- Firebase Project (for notifications)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/smart-plug-app.git
   cd smart-plug-app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code**

   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure environment**

   - Copy `assets/data/config.example.json` to `assets/data/config.json`
   - Update configuration values:

   ```json
   {
     "BASE_URL": "https://your-api-gateway-url.com",
     "AWS_REGION": "ap-south-1",
     "COGNITO_USER_POOL_ID": "your-user-pool-id",
     "COGNITO_CLIENT_ID": "your-client-id",
     "IOT_ENDPOINT": "your-iot-endpoint.iot.ap-south-1.amazonaws.com",
     "MQTT_BROKER_URL": "wss://your-iot-endpoint.iot.ap-south-1.amazonaws.com/mqtt"
   }
   ```

5. **Setup Firebase**

   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Configure Firebase Messaging for push notifications

6. **Run the app**
   ```bash
   flutter run
   ```

## 🏭 Backend Setup

### AWS Services Required

1. **API Gateway** - REST API endpoints
2. **Lambda Functions** - Business logic
3. **DynamoDB** - Data storage
4. **IoT Core** - MQTT broker for real-time communication
5. **Cognito** - User authentication
6. **SNS** - Push notifications

### Lambda Functions Needed

- `auth-service` - User authentication
- `device-service` - Device CRUD operations
- `telemetry-service` - Handle sensor data
- `schedule-service` - Manage device schedules
- `billing-service` - Calculate energy costs

### DynamoDB Tables

- `Users` - User profiles and preferences
- `Devices` - Device information and settings
- `Telemetry` - Time-series sensor data
- `Schedules` - Device automation rules
- `Notifications` - User notifications

## 📱 App Structure

```
lib/
├── app/                    # App configuration
│   ├── app.dart           # Main app widget
│   ├── router.dart        # Navigation routes
│   └── theme.dart         # UI theme
├── core/                   # Shared functionality
│   ├── config/            # Environment configuration
│   ├── services/          # Core services (HTTP, MQTT, etc.)
│   ├── utils/             # Utilities and validators
│   └── widgets/           # Reusable UI components
├── data/                   # Data layer
│   ├── models/            # Data models
│   ├── sources/           # API clients
│   └── repositories/      # Data repositories
└── features/              # Feature modules
    ├── auth/              # Authentication
    ├── dashboard/         # Main dashboard
    ├── device_detail/     # Device monitoring
    ├── onboarding/        # Device setup
    ├── schedules/         # Automation
    ├── analytics/         # Energy reports
    └── settings/          # App settings
```

## 🎨 UI Components

### Key Screens

- **Login/Register** - User authentication
- **Dashboard** - Device overview and quick controls
- **Device Detail** - Live monitoring with real-time charts
- **Device Onboarding** - WiFi provisioning wizard
- **Schedules** - Automation management
- **Energy Analytics** - Usage reports and cost breakdown
- **Settings** - User preferences and tariff configuration

### Custom Widgets

- `DeviceStatusCard` - Device status display
- `PowerDisplayWidget` - Real-time telemetry
- `LoadingButton` - Async action button
- `CustomTextField` - Styled input field
- `EmptyStateWidget` - No data placeholder

## 📊 Energy Monitoring

### Sri Lankan CEB Tariffs (2024)

```dart
// Domestic tariff slabs
0-30 kWh:    LKR 7.85/kWh
31-60 kWh:   LKR 10.85/kWh
61-90 kWh:   LKR 27.75/kWh
91-120 kWh:  LKR 32.00/kWh
121-180 kWh: LKR 37.00/kWh
180+ kWh:    LKR 45.00/kWh
Fixed Charge: LKR 240/month
```

### Real-time Monitoring

- Voltage (V) - 200-250V range
- Current (A) - Up to 13A safely
- Power (W) - Instantaneous consumption
- Energy (kWh) - Cumulative usage
- Power Factor - Efficiency indicator

## 🔄 MQTT Topics

### Device → Cloud

```
iot/plug/{deviceId}/data    # Telemetry data
iot/plug/{deviceId}/state   # ON/OFF status
iot/plug/{deviceId}/alert   # Safety alerts
```

### Cloud → Device

```
iot/plug/{deviceId}/cmd     # Control commands
iot/plug/{deviceId}/config  # Configuration updates
```

## 📱 Device Provisioning

### Supported Methods

1. **SoftAP** - Device creates WiFi hotspot
2. **BLE** - Bluetooth Low Energy pairing
3. **Manual** - Manual configuration via app

### Provisioning Flow

1. Put device in pairing mode
2. Connect to device hotspot/BLE
3. Send WiFi credentials
4. Device connects to WiFi
5. Device registers with cloud
6. App receives confirmation

## 🔔 Notifications

### Notification Types

- **Device Status** - ON/OFF state changes
- **Safety Alerts** - Overcurrent, overvoltage warnings
- **Device Offline** - Connection lost
- **Energy Alerts** - High usage warnings
- **Schedule Execution** - Automation confirmations
- **Monthly Reports** - Usage summaries

### Delivery Methods

- **Push Notifications** - Firebase Cloud Messaging
- **Local Notifications** - Device-based alerts
- **In-app Notifications** - Activity feed

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Widget Tests

```bash
flutter test test/widget_test/
```

## 📦 Building for Production

### Android

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ipa --release
```

## 🔐 Security Features

- JWT token authentication
- Secure storage for sensitive data
- HTTPS/WSS encrypted communication
- Device-specific MQTT credentials
- Input validation and sanitization
- Rate limiting on API endpoints
- Biometric authentication support

## 🐛 Troubleshooting

### Common Issues

**Device won't connect to WiFi**

- Check WiFi password is correct
- Ensure 2.4GHz network (not 5GHz)
- Router should support WPA2/WPA3
- Check signal strength

**Real-time data not updating**

- Verify device is online
- Check MQTT connection status
- Ensure IoT Core permissions are correct
- Check device firmware version

**High energy readings**

- Verify current sensor calibration
- Check for electrical issues
- Compare with external meter
- Contact support if readings seem incorrect

**App crashes on startup**

- Clear app cache and data
- Check internet connection
- Verify AWS credentials
- Update to latest app version

### Debug Mode

Enable debug logging in `config.json`:

```json
{
  "ENABLE_DEBUG_LOGS": true
}
```

## 🔄 Updates & Maintenance

### Over-the-Air Updates

- Firmware updates via AWS IoT Jobs
- App updates via Play Store/App Store
- Configuration updates via remote config

### Monitoring

- AWS CloudWatch for backend metrics
- Firebase Analytics for app usage
- Custom metrics for energy data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Flutter/Dart style guidelines
- Use meaningful variable names
- Add comments for complex logic
- Write tests for new features

### Pull Request Guidelines

- Include description of changes
- Add screenshots for UI changes
- Ensure all tests pass
- Update documentation if needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [AWS IoT Core Guide](https://docs.aws.amazon.com/iot/)
- [Firebase Documentation](https://firebase.google.com/docs)

### Getting Help

- Create an issue for bug reports
- Join our Discord community
- Email support: support@smartplug.lk
- Check FAQ section

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- AWS for robust cloud services
- Firebase for easy mobile backend
- Sri Lankan developers community
- CEB for providing tariff data

## 📈 Roadmap

### v1.1 (Next Release)

- [ ] Voice control integration (Google Assistant/Alexa)
- [ ] Advanced scheduling with sunrise/sunset
- [ ] Energy usage predictions
- [ ] Device grouping and scenes
- [ ] Export data to CSV/PDF

### v1.2 (Future)

- [ ] Smart home integration (HomeKit, SmartThings)
- [ ] Machine learning for usage optimization
- [ ] Social features (share energy savings)
- [ ] Integration with solar panels
- [ ] Multi-tenant support for businesses

### v2.0 (Long-term)

- [ ] Support for other smart devices
- [ ] Advanced automation with sensors
- [ ] Energy trading marketplace
- [ ] Carbon footprint tracking
- [ ] Integration with utility billing systems

## 🔬 Technical Details

### Performance Optimizations

- Lazy loading of device data
- Efficient state management with Riverpod
- Image caching and compression
- Background sync with limited frequency
- Memory-efficient chart rendering

### Scalability

- Horizontal scaling with load balancers
- Database sharding for telemetry data
- CDN for static assets
- Caching layers (Redis/ElastiCache)
- Auto-scaling Lambda functions

### Privacy

- Data encryption at rest and in transit
- GDPR compliance features
- User data export/deletion
- Anonymized analytics
- Local data processing where possible

## 📊 Analytics & Metrics

### User Metrics

- Daily/Monthly active users
- Device adoption rates
- Feature usage statistics
- Energy savings achieved
- User retention rates

### System Metrics

- API response times
- MQTT message throughput
- Device online/offline rates
- Error rates and alerts
- Infrastructure costs

## 🌍 Internationalization

### Supported Languages

- **English** - Default language
- **සිංහල (Sinhala)** - Sri Lankan official language
- **தமிழ் (Tamil)** - Sri Lankan official language

### Adding New Languages

1. Create ARB file in `lib/l10n/`
2. Add translations for all keys
3. Update supported locales in `app.dart`
4. Test RTL support if applicable

## 🏗️ Development Workflow

### Git Workflow

- `main` - Production releases
- `develop` - Development integration
- `feature/*` - Feature development
- `hotfix/*` - Critical bug fixes
- `release/*` - Release preparation

### CI/CD Pipeline

1. **Code Commit** → Trigger pipeline
2. **Unit Tests** → Run automated tests
3. **Code Analysis** → Static analysis
4. **Build** → Create app bundles
5. **Integration Tests** → Run on devices
6. **Deploy** → Release to stores

### Environment Setup

```bash
# Development
flutter run --flavor dev

# Staging
flutter run --flavor staging

# Production
flutter run --flavor prod
```

## 📱 Device Compatibility

### Minimum Requirements

- **Android** 6.0 (API level 23)
- **iOS** 11.0
- **RAM** 2GB recommended
- **Storage** 100MB app size

### Tested Devices

- Samsung Galaxy series
- Google Pixel series
- OnePlus devices
- iPhone 8 and newer
- iPad (all models with iOS 11+)

### Hardware Features Used

- WiFi connectivity
- Bluetooth Low Energy
- Camera (QR code scanning)
- Biometric sensors
- Push notification support

---

**Made with ❤️ for Sri Lankan smart home enthusiasts**

🌟 **Star this repo if you found it helpful!** 🌟
