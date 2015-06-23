library cork.generated.SingleModuleEntrypoint;

import 'package:cork/src/binding/runtime.dart';
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;

class SingleModuleEntrypointInjector {
  import_1.Foo _1;
  import_1.Bar _2;
  import_1.Foo get1() {
    if (_1 == null) {
      _1 = new import_1.Foo();
    }
    return _1;
  }

  import_1.Bar get2() {
    if (_2 == null) {
      _2 = new import_1.Bar(get1());
    }
    return _2;
  }
}
