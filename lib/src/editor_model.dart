import 'package:mobx/mobx.dart';

part 'editor_model.g.dart';

class EditorModel = EditorModelBase with _$EditorModel;

abstract class EditorModelBase with Store {}
