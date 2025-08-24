import 'package:hydracat/core/config/flavor_config.dart';
import 'package:hydracat/main.dart' as main_app;

void main() {
  FlavorConfig.flavor = Flavor.development;
  main_app.main();
}
