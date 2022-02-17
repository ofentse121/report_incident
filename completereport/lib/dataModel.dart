import 'dart:convert';

import 'dart:io';

DataModel dataModeFromJson(String str) => DataModel.fromJson(json.decode(str));

class DataModel {
  DataModel(
      {required this.dateTime,
      required this.incidentType,
      required this.incident_desc,
      required this.location,
      required this.user_id,
      required this.image});

  String dateTime;
  String incidentType;
  String incident_desc;
  String location;
  int user_id;
  String image;

  factory DataModel.fromJson(Map<String, dynamic> json) => DataModel(
        dateTime: json["dateTime"],
        incidentType: json["incidentType"],
        incident_desc: json["incident_desc"],
        location: json["location"],
        user_id: json["user_id"],
        image: json["image"],
      );
  Map<String, dynamic> toJson() => {
        "dateTime": dateTime,
        "incidentType": incidentType,
        "incident_desc": incident_desc,
        "location": location,
        "user_id": user_id,
        "image": image
      };
}
