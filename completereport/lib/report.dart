import 'dart:typed_data';
import 'package:completereport/dataModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class ReportIncidents extends StatefulWidget {
  const ReportIncidents({Key? key}) : super(key: key);

  @override
  _ReportIncidentsState createState() => _ReportIncidentsState();
}

class _ReportIncidentsState extends State<ReportIncidents> {
  DataModel? _dataMOdel;    
  Uint8List? imageBytes;
  File? imageFile;
  late CloudApi api;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/credentials.json').then((json) {
      api = CloudApi(json);
    });
  }

  String img = "no image";
  String location = 'Null, Press Button';
  var address = 'No address';
  String sent = 'Report not sent !!!';
  final List<String> crime = [
    "Theft",
    "Vandalism",
    "Murder",
    "Bulling",
    "GBV & F",
    "Injury" 

  ];

  String selectedCrime = "Theft";
  //access the location

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future GetAddressFromLatLong(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    // print(placemarks);
    Placemark place = placemarks[0];
    address =
        '${place.street},${place.subLocality},${place.locality},${place.postalCode}, ${place.country}';
    setState(() {});
    address = address;
    return address;
  }

  //Description of incident
  TextEditingController _controller = TextEditingController();
  //Report button

  void _saveImage() async {
//upload to google cloud
    final response = await api.save(_imageName!, imageBytes!);
    print(response);
    img = response.toString();
    Fluttertoast.showToast(
        msg: ' image saved',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[700],
      appBar: AppBar(
        title: Text("Reporting Incidents"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          child: Text(
            'Report',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            DataModel? data =
                await submitData(selectedCrime, location, img, _controller);
            setState(() {
              _dataMOdel = data!;
            });
          }),
      body: Padding(
        padding: EdgeInsets.all(30),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "INCIDENT TYPE:",
              style: TextStyle(
                letterSpacing: 2,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            DropdownButton<String>(
              isExpanded: true,
              iconSize: 36,
              iconEnabledColor: Colors.red,
              value: selectedCrime,
              onChanged: (value) {
                setState(() {
                  selectedCrime = value!;
                });
              },
              items: crime.map<DropdownMenuItem<String>>((value) {
                return DropdownMenuItem(
                  child: Text(value),
                  value: value,
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            //Text Field
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Describe Incident",
                labelText: "Description",
                labelStyle: TextStyle(fontSize: 18, color: Colors.black),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  Position position = await _getGeoLocationPosition();
                  location =
                      'Lat: ${position.latitude} , Long: ${position.longitude}';
                  GetAddressFromLatLong(position);
                  setState(() {});
                },
                child: Text('Get Location')),
            Text('${address}'),
            SizedBox(height: 10),
            if (imageFile != null) //from here

              Container(
                width: 300,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  image: DecorationImage(image: FileImage(imageFile!)),
                ),
              )
            else
              Container(
                width: 300,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  border: Border.all(width: 8, color: Colors.black54),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Image should appear here',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                  onPressed: () => getImage(source: ImageSource.camera),
                  child: Text('capture img'),
                )),
                SizedBox(width: 5),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () => getImage(source: ImageSource.gallery),
                  child: Text('Select img'),
                )),
                SizedBox(width: 5),
                ElevatedButton(
                    onPressed: () => _saveImage(), child: Text('save img')),
              ],
            ), //until here
          ]),
        ),
      ),
    );
  }

  void getImage({required ImageSource source}) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file?.path != null) {
      setState(() {
        imageFile = File(file!.path);
        imageBytes = imageFile!.readAsBytesSync();
        _imageName = imageFile!.path.split('/').last;
      });
    }
  }

  Future<DataModel?> submitData(String selectedCrime, String location,
      String img, TextEditingController controller) async {
    HttpOverrides.global = new MyHttpOverrides();
    var response =
        await http.post(Uri.http('10.0.2.2:5001', 'reportincident'), body: {
      "dateTime": DateTime.now().toString(),
      "incidentType": selectedCrime,
      "incident_desc": _controller.text,
      "location": address,
      "image": img,
    });
    var data = response.body;
    print(data);
    Fluttertoast.showToast(
        msg: 'Report sent',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM);
    if (response.statusCode == 200) {
      String responseString = response.body;
      dataModeFromJson(responseString);
    }
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
