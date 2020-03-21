import 'dart:async';
import 'dart:convert';
import 'package:enqueayudo/models/AlarmRequest.dart';
import 'package:enqueayudo/widgets/CustomDialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class PrimaryMap extends StatefulWidget {
  PrimaryMap({Key key}) : super(key: key);

  @override
  _PrimaryMapState createState() => _PrimaryMapState();
}

class _PrimaryMapState extends State<PrimaryMap> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GoogleMapController _controller;
  CameraPosition cameraPosition;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  int _markerIdCounter = 1;
  MarkerId selectedMarker;
  bool loadedData = false;
  bool addingMark = false;

  Location location = new Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  BitmapDescriptor drop;
  BitmapDescriptor fork;
  BitmapDescriptor pill;

  static final CameraPosition _kHome = CameraPosition(
    target: LatLng(-0.196, -78.48),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    loadedData = false;
    createIcons();
    getMyGpsLocation();
    bringGpsPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!addingMark) getMyGpsLocation();
          setState(() {
            addingMark = !addingMark;
          });
        },
        child: addingMark ? Icon(Icons.clear) : Icon(Icons.add),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            initialCameraPosition: _kHome,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            markers: Set<Marker>.of(markers.values),
            onCameraMove: ((_position) => cameraPosition = _position),
          ),
          addingMark
              ? Center(child: AddNewMarkWidget(showEmergencyDialog))
              : SizedBox(),
          Positioned(
            bottom: 10,
            left: 10,
            child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    loadedData = false;
                    bringGpsPoints();
                  });
                },
                child: loadedData
                    ? Icon(Icons.replay)
                    : Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              backgroundColor: Colors.white,
                            )))),
          ),
        ],
      ),
    );
  }

  bool checkGps(AlarmRequest req) {
    print(req.ubicacion_necesidad);
    bool available = req.ubicacion_necesidad.contains("(") &&
        req.ubicacion_necesidad.contains(".") &&
        req.ubicacion_necesidad.contains(")") &&
        req.ubicacion_necesidad.contains(",") &&
        !req.ubicacion_necesidad.contains("[a-zA-Z]+");
    print(available.toString());
    return available;
  }

  AlarmRequest addLatLng(AlarmRequest req) {
    var split = req.ubicacion_necesidad
        .replaceAll("(", "")
        .replaceAll(")", "")
        .split(',');
    req.lat = double.parse(split[1]);
    req.lng = double.parse(split[0]);
    return req;
  }

  addMarker(AlarmRequest ob) {
    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    final MarkerId markerId = MarkerId(markerIdVal);

    BitmapDescriptor icon;
    print('asdasd' + ob.tipo_necesidad);
    switch (ob.tipo_necesidad) {
      case 'AGU':
        icon = drop;
        break;
      case 'ALI':
        icon = fork;
        break;
      case 'MED':
        icon = pill;
        break;
      default:
        icon = null;
        break;
    }

    final Marker marker = Marker(
      markerId: markerId,
      icon: icon,
      position: LatLng(ob.lat, ob.lng),
      infoWindow: InfoWindow(
          title: ob.tipo_necesidad + " / Tap para ayudar",
          snippet: ob.detalles,
          onTap: () {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('TODO: implementar ayudar'),
              duration: Duration(seconds: 3),
            ));
          }),
      onTap: () {
        _onMarkerTapped(markerId);
      },
    );
    markers[markerId] = marker;
    setState(() {
      markers[markerId] = marker;
    });
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        selectedMarker = markerId;
      });
    }
  }

  Future<void> bringGpsPoints() async {
    markers.clear();
    var snapshot =
        await http.get('https://api.enqueayudo.org/necesitoEndpoint/');
    setState(() {
      loadedData = true;
    });

    List<dynamic> l = json.decode(snapshot.body);
    List<AlarmRequest> requestsList =
        l.map((ob) => (AlarmRequest.fromJson(ob))).toList();
    print(requestsList.length);
    requestsList = requestsList.where((req) => checkGps(req)).toList();
    print(requestsList.length);
    requestsList.map((ob) => ob = addLatLng(ob)).toList();
    requestsList.forEach((ob) => addMarker(ob));
  }

  Future<void> getMyGpsLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.DENIED) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.GRANTED) {
        return;
      }
    }

    _locationData = await location.getLocation();
    tryCenterMap(_locationData);
  }

  void tryCenterMap(LocationData location) {
    CameraPosition position = new CameraPosition(
        target: LatLng(location.latitude, location.longitude), zoom: 16);
    _controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  void createIcons() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(1, 1)), 'assets/drop.png')
        .then((image) {
      drop = image;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(16, 16)), 'assets/fork.png')
        .then((image) {
      fork = image;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(4, 4)), 'assets/pill.png')
        .then((image) {
      pill = image;
    });
  }

  showEmergencyDialog() {
    String coordinates = "(" +
        cameraPosition.target.longitude.toString() +
        "," +
        cameraPosition.target.latitude.toString() +
        ")";
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            CustomDialog(coordinates: coordinates, after: reloadAfterDialog));
  }

  reloadAfterDialog() {
    print('asdasd');
    setState(() {
      loadedData = false;
      addingMark = false;
      bringGpsPoints();
    });
  }
}

class AddNewMarkWidget extends StatelessWidget {
  var showEmergencyDialog;

  AddNewMarkWidget(showEmergencyDialog) {
    this.showEmergencyDialog = showEmergencyDialog;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Center(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                  padding: EdgeInsets.all(12),
                  height: 65,
                  color: Colors.blueAccent,
                  child: Column(
                    children: <Widget>[
                      Text(
                        '¿Dónde es tu emergencia?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Text('Centra la ubicación moviendo el mapa',
                          style: TextStyle(color: Colors.white)),
                    ],
                  )),
            )),
          ),
          Flexible(
            flex: 1,
            child: Center(
                child: Icon(
              Icons.place,
              color: Colors.red,
              size: 40,
            )),
          ),
          Flexible(
            flex: 1,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RaisedButton(
                  color: Colors.red,
                  child: Text(
                    'Crear Emergencia',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: showEmergencyDialog,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
