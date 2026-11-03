import 'result.dart';

/// The text a screen shows for an error held in provider state.
String errorMessage(Object error) =>
    error is AppFailure ? error.message : 'Something went wrong.';
