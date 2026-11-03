import 'package:dio/dio.dart';
import 'package:gif_loop/core/config/giphy_config.dart';

Dio createGiphyDio({required String apiKey}) => Dio(
  BaseOptions(
    baseUrl: GiphyConfig.baseUrl,
    connectTimeout: GiphyConfig.connectTimeout,
    receiveTimeout: GiphyConfig.receiveTimeout,
    queryParameters: {'api_key': apiKey},
  ),
);
