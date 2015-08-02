library cork.test.mirrors.graph_test;

import 'package:cork/src/api/annotations.dart';
import 'package:cork/src/mirrors/graph.dart';
import 'package:cork/src/testing/matchers.dart';
import 'package:test/test.dart';

void main() {
  group('MirrorsObjectGraph', () {
    test('should resolve to create an Injector', () {
      var injector = const MirrorsObjectGraph<CarModule>().resolve();
      Car car = injector.get(Car);
      expect(car.fuel, const isInstanceOf<Fuel>());
      expect(() => injector.get(Engine), throwsNoProviderFoundError);
    });

    test('should verify the graph aggressively', () {
      expect(
          () => const MirrorsObjectGraph<MissingModule>().resolve(),
          throwsNoProviderFoundError);
    });
  });
}

class Fuel {}

@Module(bindings: const [
  const Binding(Fuel)
])
class FuelModule {
  @Provide()
  Fuel getFuel() => new Fuel();
}

@Inject()
class Car {
  final Fuel fuel;

  @Provide()
  Car(this.fuel);
}

@Module(
  bindings: const [
    const Binding(Car)
  ],
  includes: const [FuelModule]
)
class CarModule {}

@Inject()
class Engine {
  @Provide()
  Engine(Piston piston) {
    assert(piston != null);
  }
}

class Piston {}

@Module(
  bindings: const [
    const Binding(Engine)
  ]
)
class MissingModule {}
