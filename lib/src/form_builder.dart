import 'package:flutter/material.dart';
import '../form_helper.dart';

/// Builds a form
///
///
/// By default you can just provide it a form spec
/// It'll wire it all up for you
///
/// Optionally you can provide uiBuilder to build a specific form UI
///
class FormBuilder extends StatefulWidget {
  /// Construct a form
  ///
  /// form = List of fields
  /// uiBuilder = builds the ui
  const FormBuilder(
      {@required this.form,
      Key key,
      this.uiBuilder = scrollableSimpleForm,
      this.onFormChanged,
      this.onFormSubmitted})
      : super(key: key);

  /// The list of fields in order of focus/drawing
  final List<FieldSpec> form;

  /// A builder for the UI, scrollable SimpleForm to start
  final FormUiBuilder uiBuilder;

  final FormResultsCallback onFormChanged;
  final FormResultsCallback onFormSubmitted;

  @override
  _FormBuilderState createState() => _FormBuilderState();
}

class _FormBuilderState extends State<FormBuilder> {
  FormHelper helper;

  @override
  void initState() {
    helper = FormHelper(
        spec: widget.form,
        onChanged: widget.onFormChanged,
        onSubmitted: widget.onFormSubmitted)
      ..addListener(_refresh);
    super.initState();
  }

  @override
  void dispose() {
    helper
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) =>
      helper.buildForm(builder: widget.uiBuilder);
}

///
/// This is the default "debug" form
///
/// It can be used to rapidly generate a form.
///
Widget scrollableSimpleForm(FormHelper helper) =>
    Column(
      children: <Widget>[
        Expanded(
          child: Card(
            elevation: 0.25,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: helper.fields.map((f) {
                      if (f.type != FieldType.Text) {
                        return Row(children: <Widget>[
                          Text("${f.value}:${f.group ?? ""}"),
                          helper.getWidget(f.name)
                        ]);
                      } else {
                        return helper.getWidget(f.name);
                      }
                    }).toList()),
              ),
            ),
          ),
        ),
        RaisedButton(
            child: Text(helper.submissionButtonText),
            onPressed: helper.submitForm),
      ],
    );
