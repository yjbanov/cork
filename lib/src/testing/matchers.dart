library cork.src.testing.matchers;

import 'package:cork/src/api/errors.dart';
import 'package:test/test.dart';

const isInvalidConfigurationError = const isInstanceOf<InvalidConfigurationError>();
const isInvalidTypeError = const isInstanceOf<InvalidTypeError>();
const isNoAnnotationFoundError = const isInstanceOf<NoAnnotationFoundError>();
const isNoDynamicInjectionError = const isInstanceOf<NoDynamicInjectionError>();
const isNoProviderFoundError = const isInstanceOf<NoProviderFoundError>();

const throwsInvalidConfigurationError = const Throws(isInvalidConfigurationError);
const throwsInvalidTypeError = const Throws(isInvalidTypeError);
const throwsNoAnnotationFoundError = const Throws(isNoAnnotationFoundError);
const throwsNoDynamicInjectionError = const Throws(isNoDynamicInjectionError);
const throwsNoProviderFoundError = const Throws(isNoProviderFoundError);
