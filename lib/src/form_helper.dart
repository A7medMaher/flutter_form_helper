import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../form_helper.dart';
import 'validators.dart';

enum FieldType { Text, Radio, Checkbox }

/// Metadata to define a field
class FieldSpec {
  /// Build a FieldSpec
  const FieldSpec(
      {@required this.name,
      this.validators = const [],
      this.mandatory = false,
      this.value = "",
      this.group,
      this.type = FieldType.Text,
      this.label});

  /// The name of this field
  final String name;

  /// The group (for RadioGroups)
  final String group;

  /// The type of the field
  final FieldType type;

  /// The label for this field (name is default)
  final String label;

  /// Is the field Required
  final bool mandatory;

  final String value;

  /// The Validator for this field
  /// Null if OK
  /// Text if Error
  final List<validator> validators;
}

/// Specifies a Form
class FormHelper extends ChangeNotifier {
  /// Construct a FormHelper
  factory FormHelper(List<FieldSpec> spec) => FormHelper._(
      controllers: spec.fold(
          <String, TextEditingController>{},
          (p, v) => <String, TextEditingController>{}
            ..addAll(p)
            ..putIfAbsent(v.name, () => TextEditingController())),
      focusNodes: spec.fold(
          <String, FocusNode>{},
          (p, v) => <String, FocusNode>{}
            ..addAll(p)
            ..putIfAbsent(v.name, () => FocusNode())),
      fields: spec);

  /// Private Constructor - Init from Factory
  FormHelper._(
      {@required this.fields,
      @required this.controllers,
      @required this.focusNodes});

  /// We'll dump values in here
  final valueMap = <String, String>{};

  /// All the fields
  final List<FieldSpec> fields;

  /// All the controllers
  final Map<String, TextEditingController> controllers;

  /// All the focus nodes
  final Map<String, FocusNode> focusNodes;

  /// All the values
  final Map<String, String> values = {};

  /// Gets a field spec
  FieldSpec _getFieldSpec(String name) =>
      fields.firstWhere((element) => element.name == name);

  /// Gets a field spec
  int _getFieldSpecIndex(FieldSpec fieldSpec) => fields.indexOf(fieldSpec);

  /// Get a focus node for a named field
  FocusNode _getFocusNode(String name) => focusNodes[name];

  /// Get a text editting controller for a name
  TextEditingController _getTextEditingController(String name) =>
      controllers[name];

  int submissions = 0;

  String _getText(String name) => _getTextEditingController(name).text;

  /// A count of validation errors
  int get validationErrors => fields.fold(
      0,
      (sum, field) =>
          compositeValidator(field.validators, _getText(field.name)) == null
              ? sum
              : sum + 1);

  /// A count of how many fields are still required
  int get stillRequired => fields.fold(
      0,
      (sum, field) => field.mandatory
          ? _getTextEditingController(field.name).text.isEmpty ? sum + 1 : sum
          : sum);

  String get submissionButtonText {
    if (stillRequired > 0) {
      return "$stillRequired fields remaining";
    }

    if (validationErrors > 0) {
      return "$validationErrors field doesn't validate";
    }
    return "Submit Form";
  }

  void _focusOnFirstRemaining() {
    final field = fields
        .firstWhere((field) => field.mandatory && _getText(field.name).isEmpty);
    if (field != null) {
      _getFocusNode(field.name).requestFocus();
    }
  }

  @override
  void dispose() {
    this
      ..controllers.forEach((key, value) => value.dispose())
      ..focusNodes.forEach((key, value) => value.dispose());
    super.dispose();
  }

  /// Dispose this form

  void _onChange(String name, String value) {
    values[name] = value;
    notifyListeners();
  }

  /// Gets a list of TextFields for this form
  List<Widget> getTextFields() => fields
      .map((fs) => FormHelperTextField._(formHelper: this, name: fs.name))
      .toList();

  /// Build the form
  Widget buildForm({FormUiBuilder builder = scrollableSimpleForm}) =>
      builder(this, _buildWidgets());

  void _onSubmit(String name) {
    final idx = _getFieldSpecIndex(_getFieldSpec(name));
    if (idx + 1 < fields.length) {
      final nextField = fields[idx + 1];
      _getFocusNode(nextField.name).requestFocus();
    } else {
      _getFocusNode(name).unfocus();
    }
  }

  /// Called when the form is submitted
  void onFormSubmit() {
    if (stillRequired > 0) {
      _focusOnFirstRemaining();
    }
    notifyListeners();
  }

  Map<String, Widget> _buildWidgets() => fields.fold(
      Map<String, Widget>(),
      (map, field) => <String, Widget>{
            field.name: field.type == FieldType.Text
                ? FormHelperTextField._(formHelper: this, name: field.name)
                : field.type == FieldType.Radio
                    ? FormHelperRadio(formHelper: this, name: field.name)
                    : field.type == FieldType.Checkbox
                        ? FormHelperCheckbox(formHelper: this, name: field.name)
                        : ("${field.name} can't inflate ${field.type}")
          }..addAll(map));

  String _getValue(String name) {
    final field = _getFieldSpec(name);
    switch (field.type) {
      case FieldType.Text:
        return _getTextEditingController(name).text;
      case FieldType.Radio:
        if (!values.containsKey(field.group)) {
          return _getRadioDefaultValue(field.group);
        }
        return values[field.group];
      case FieldType.Checkbox:
        return "";
    }
    return "";
  }

  String _getRadioDefaultValue(String group) =>
      fields.firstWhere((element) => element.group == group).value;

  void _applyRadioValue(String name, value) {
    final field = _getFieldSpec(name);
    values[field.group] = value;
    notifyListeners();
  }

  void _toggleCheckbox(String name) {
    if (values.containsKey(name)) {
      values.remove(name);
    } else {
      values[name] = _getFieldSpec(name).value;
    }
    notifyListeners();
  }

  bool _isChecked(String name) => values.containsKey(name);
}

typedef FormUiBuilder = Widget Function(
    FormHelper helper, Map<String, Widget> widgets);

/// A TextFormField, but with FormHelper bindings
class FormHelperTextField extends StatelessWidget {
  /// Construct a text form helper
  const FormHelperTextField._(
      {@required this.formHelper, @required this.name, Key key})
      : super(key: key);

  /// The Form Helper
  final FormHelper formHelper;

  /// The name of the field
  final String name;

  @override
  Widget build(BuildContext context) {
    final fieldSpec = formHelper._getFieldSpec(name);
    final label = fieldSpec.label ?? name;

    return TextFormField(
        onChanged: (value) => formHelper._onChange(name, value),
        onFieldSubmitted: (value) => formHelper._onSubmit(name),
        focusNode: formHelper._getFocusNode(name),
        controller: formHelper._getTextEditingController(name),
        decoration: InputDecoration(
            labelText: fieldSpec.mandatory ? "* $label" : label,
            errorText: compositeValidator(fieldSpec.validators,
                formHelper._getTextEditingController(name).text)));
  }
}

class FormHelperRadio extends StatelessWidget {
  const FormHelperRadio({Key key, this.formHelper, this.name})
      : super(key: key);

  /// The Form Helper
  final FormHelper formHelper;

  /// The name of the field
  final String name;

  @override
  Widget build(BuildContext context) => Radio(
      groupValue: formHelper._getFieldSpec(name).value,
      value: formHelper._getValue(name),
      focusNode: formHelper._getFocusNode(name),
      onChanged: (value) => formHelper._applyRadioValue(
          name, formHelper._getFieldSpec(name).value));
}

class FormHelperCheckbox extends StatelessWidget {
  const FormHelperCheckbox({Key key, this.formHelper, this.name})
      : super(key: key);

  /// The Form Helper
  final FormHelper formHelper;

  /// The name of the field
  final String name;

  @override
  Widget build(BuildContext context) => Checkbox(
    focusNode: formHelper._getFocusNode(name),  
      value: formHelper._isChecked(name),
      onChanged: (value) => formHelper._toggleCheckbox(name));
}
