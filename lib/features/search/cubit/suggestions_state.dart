import 'package:equatable/equatable.dart';

class SuggestionsState extends Equatable {
  const new({this.query = '', this.suggestions = const []});

  final String query;
  final List<String> suggestions;

  @override
  List<Object?> get props => [query, suggestions];
}
