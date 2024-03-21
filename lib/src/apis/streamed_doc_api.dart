import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jrx_flutter/jrx_flutter.dart';

abstract class StreamedDocApi<T> extends BaseApi<T> {
  final Bindable<T?> curData = Bindable(null);
  StreamSubscription<DocumentSnapshot>? _docSubscription;

  DocumentReference getReference();

  T parseData(DocumentSnapshot snapshot);

  @override
  Future<AsyncResponse<T>> requestInternal() async {
    final ref = getReference();
    final result = await ref.get();
    return AsyncResponse.success(_parseDataInternal(result));
  }

  void startStream([Function(T?)? onData]) {
    stopStream();

    _docSubscription = getReference().snapshots().listen((event) {
      final parsedData = _parseDataInternal(event);
      if (onData != null) {
        onData(parsedData);
      }

      curData.value = parsedData;
    });
  }

  void stopStream() {
    if (_docSubscription != null) {
      _docSubscription!.cancel();
      _docSubscription = null;
    }
    curData.value = null;
  }

  void postprocessData(T data) {}

  T? _parseDataInternal(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      return null;
    }
    final value = parseData(snapshot);
    postprocessData(value);
    return value;
  }
}
