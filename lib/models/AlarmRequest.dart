class AlarmRequest {
  String tipo_necesidad;
  String ubicacion_necesidad;
  String detalles;
  String documento;
  String telefono;
  double lat;
  double lng;

  AlarmRequest(
      {this.tipo_necesidad,
      this.ubicacion_necesidad,
      this.detalles,
      this.documento,
      this.telefono});

  factory AlarmRequest.fromJson(Map<String, dynamic> jsonResponse) {
    return AlarmRequest(
        tipo_necesidad: jsonResponse['tipo_necesidad'],
        ubicacion_necesidad: jsonResponse['ubicacion_necesidad'],
        detalles: jsonResponse['detalles'],
        documento: jsonResponse['documento'],
        telefono: jsonResponse['telefono']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tipo_necesidad'] = this.tipo_necesidad;
    data['ubicacion_necesidad'] = this.ubicacion_necesidad;
    data['detalles'] = this.detalles;
    data['documento'] = this.documento;
    data['telefono'] = this.telefono;
    return data;
  }

}
