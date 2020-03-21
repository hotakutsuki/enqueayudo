import 'dart:convert';

import 'package:enqueayudo/models/AlarmRequest.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomDialog extends StatefulWidget {
  final String coordinates;
  final Function after;

  CustomDialog({
    @required this.coordinates,
    this.after,
  });

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  final _formKey = GlobalKey<FormState>();
  String selection;
  bool hasSelection = true;
  final name_field = TextEditingController();
  final ci_field = TextEditingController();
  final phone_field = TextEditingController();
  final age_field = TextEditingController();
  final detail_field = TextEditingController();

  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0.0,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            Text(
              'Posición:',
            ),
            Text(
              widget.coordinates,
              style: TextStyle(fontSize: 10),
            ),
            Divider(),
            Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Info de emergencia:',
                    style: TextStyle(fontSize: 18),
                  ),
                )),
            TextFormField(
              controller: name_field,
              maxLength: 32,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(0),
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                labelText: 'Nombre y Apellido*',
              ),
              validator: (value) {
                if (value.isEmpty || !value.contains(" ")) {
                  return 'Ingrese su nombre y apellido';
                }
                return null;
              },
            ),
            TextFormField(
              controller: ci_field,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(0),
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                  labelText: 'CI*'),
              validator: (value) {
                if (value.length != 10) {
                  return 'Ingrese cédula valida*';
                }
                return null;
              },
            ),
            TextFormField(
              controller: phone_field,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(0),
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  labelText: 'Teléfono*'),
              validator: (value) {
                if (value.length != 10) {
                  return 'Ingrese su teléfono';
                }
                return null;
              },
            ),
            TextFormField(
              controller: age_field,
              keyboardType: TextInputType.number,
              maxLength: 2,
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(0),
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  labelText: 'Edad*'),
              validator: (value) {
                if (value.length != 2) {
                  return 'Ingrese su edad';
                }
                return null;
              },
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Necesito:',
                )),
            DropdownButton(
              icon: hasSelection
                  ? Icon(Icons.arrow_drop_down)
                  : Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
              hint: Text('¿Qué necesito?'),
              isExpanded: true,
              value: selection,
              onChanged: (value) {
                print(value);
                setState(() {
                  selection = value;
                });
              },
              items: [
                DropdownMenuItem(
                  value: 'ALI',
                  child: Text('Comida'),
                ),
                DropdownMenuItem(
                  value: 'AGU',
                  child: Text('Agua'),
                ),
                DropdownMenuItem(
                  value: 'MED',
                  child: Text('Medicina'),
                ),
              ],
            ),
            TextFormField(
              controller: detail_field,
              keyboardType: TextInputType.multiline,
              maxLines: 2,
              decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'Detalles'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                color: Colors.blueAccent,
                onPressed: () {
                  if (sending)
                    return;
                  setState(() {
                    hasSelection = selection != null;
                  });
                  if (_formKey.currentState.validate() && selection != null) {
                    _formKey.currentState.save();
                    AlarmRequest request = new AlarmRequest(
                        tipo_necesidad: selection,
                        ubicacion_necesidad: widget.coordinates,
                        detalles: detail_field.text,
                        documento: ci_field.text,
                        telefono: phone_field.text);
                    print(request.toJson());
                    sendRequest(request);
                  }
                },
                child: sending
                    ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Enviar',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> sendRequest(AlarmRequest request) async {
    sending = true;
    await http.post('https://api.enqueayudo.org/necesitoEndpoint/',
        body: request.toJson());
    print('done');
    Navigator.pop(context);
    widget.after();
  }
}
