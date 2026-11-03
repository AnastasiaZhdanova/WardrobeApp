import 'package:freezed_annotation/freezed_annotation.dart';

import '../../wardrobe/domain/wardrobe_item.dart';

part 'styling_request.freezed.dart';

@freezed
abstract class StylingRequest with _$StylingRequest {
  const factory StylingRequest({
    /// The client's own words, e.g. "Dinner at the opera, it will be cold".
    required String text,

    /// Where the client is; `null` lets the agent infer it from [text].
    Residence? residence,
  }) = _StylingRequest;
}
