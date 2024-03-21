import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jrx_flutter/jrx_flutter.dart';

abstract class StreamedQueryApi<T> extends BaseApi<List<T>> {
  final Bindable<List<T>> streamData = Bindable([]);
  bool isStreaming = false;
  StreamSubscription<QuerySnapshot>? _querySubscription;

  Query getQuery();

  T parseData(QueryDocumentSnapshot snapshot);

  @override
  Future<AsyncResponse<List<T>>> requestInternal() async {
    final query = getQuery();
    final results = await query.get();
    List<T> values = results.docs.map(parseData).toList();
    postprocessData(values);
    return AsyncResponse.success(values);
  }

  void startStream([Function(List<T>)? onData]) {
    stopStream();
    
    _querySubscription = getQuery().snapshots().listen((event) {
      final parsedData = event.docs.map((e) => parseData(e)).toList();
      postprocessData(parsedData);
      if(onData != null) {
        onData(parsedData);
      }
      
      streamData.value = parsedData;
    });
  }

  void stopStream() {
    if(_querySubscription != null) {
      _querySubscription!.cancel();
      _querySubscription = null;
    }
    streamData.value = [];
  }

  void postprocessData(List<T> data) {}
}