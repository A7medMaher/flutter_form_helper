# Flutter Form Helper
Creates simple forms very quickly.

## Problem Statement
Creating forms is annoying, especially for quick mock ups.

I just want to say what my form is and have it just work.

## Solution

Flutter Form Helper

From an array of field names (Strings only, no Validation)

     ["Name", "Title", "Address"].buildSimpleForm(
                      onFormSubmitted: resultsCallback,
                      onFormChanged: onChanged)


## Reading Results

  Register onFormSubmitted and onFormChanged callbacks that will send a Map<String, String> for you to work with. Required fields and Validations must pass for these callbacks to be triggered. However you can disable validations from FormBuilder if necessary to trigger these methods every time they are pressed.

## Form Spec

The form is defined as a list of <Field> objects. They specify the type and validators used by the field. This list can be fed to FormBuilder to build the form.

Example: https://github.com/ahammer/flutter_form_helper/blob/master/example/lib/src/sample_form.dart

    const Field(
          {@required this.name,         // Name of this field
          this.validators = const [],   // A list of validators
          this.mandatory = false,       // Is this field mandatory?
          this.obscureText = false,     // Password Field
          this.value = "",              // Default Value
          this.group,                   // Group (for Radio)
          this.type = FieldType.text,   // FieldType (text/radio/checkbox)
          this.label                    // Label to be displayed as hint
          });

## Building your form

Extension Syntax
              
                  sampleForm.buildSimpleForm(                      
                      onFormSubmitted: resultsCallback,
                      onFormChanged: (map) => setChangedString(map.toString()),
                      uiBuilder: customFormBuilder),
                      

Widget Syntax

                  FormBuilder(
                      uiBuilder: customFormBuilder
                      form: sampleForm,
                      onFormSubmitted: resultsCallback,
                      onFormChanged: (map) => setChangedString(map.toString())),


You can provide a UI Builder, or use the Built in one that will just build a form in a scrollable view with a bottom below.

To build a Custom Form layout, provide a UI Builder which can use helper.getWidget(name) to add the widgets where you want and customize the layout however you want. E.g. Use "submit" name to create a submit button. E.g. helper.getWidget("submit")

Example: https://github.com/ahammer/flutter_form_helper/blob/master/example/lib/src/custom_form_builder.dart

