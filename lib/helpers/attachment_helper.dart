import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/attachment.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:vcard_parser/vcard_parser.dart';

class AttachmentHelper {
  static String createAppleLocation(double longitude, double latitude,
      {iosVersion = "13.4.1"}) {
    List<String> lines = [
      "BEGIN:VCARD",
      "VERSION:3.0",
      "PRODID:-//Apple Inc.//iPhone OS $iosVersion//EN",
      "N:;Current Location;;;",
      "FN:Current Location",
      "item1.URL;type=pref:http://maps.apple.com/?ll=$longitude\\,$latitude&q=$longitude\\,$latitude",
      "item1.X-ABLabel:map url",
      "END:VCARD"
      ""
    ];

    return lines.join("\n");
  }

  static Map<String, double> parseAppleLocation(String appleLocation) {
    List<String> lines = appleLocation.split("\n");
    String url = lines[5];
    String query = url.split("&q=")[1];

    if (query.contains("\\")) {
      return {
        "longitude": double.tryParse((query.split("\\,")[0])),
        "latitude": double.tryParse(query.split("\\,")[1])
      };
    } else {
      return {
        "longitude": double.tryParse((query.split(",")[0])),
        "latitude": double.tryParse(query.split(",")[1])
      };
    }
  }

  static Contact parseAppleContact(String appleContact) {
    Map<String, dynamic> _contact = VcardParser(appleContact).parse();
    debugPrint(_contact.toString());

    Contact contact = Contact();
    if (_contact.containsKey("N")) {
      String firstName = (_contact["N"] + " ").split(";")[1];
      String lastName = _contact["N"].split(";")[0];
      contact.displayName = firstName + " " + lastName;
    } else if (_contact.containsKey("FN")) {
      contact.displayName = _contact["FN"];
    }
    List<Item> emails = <Item>[];
    List<Item> phones = <Item>[];
    _contact.keys.forEach((String key) {
      if (key.contains("EMAIL")) {
        String label = key.split("type=")[2].replaceAll(";", "");
        emails.add(
          Item(
            value: (_contact[key] as Map<String, dynamic>)["value"],
            label: label,
          ),
        );
      } else if (key.contains("TEL")) {
        phones.add(
          Item(
            label: "HOME",
            value: (_contact[key] as Map<String, dynamic>)["value"],
          ),
        );
      }
    });
    contact.emails = emails;
    contact.phones = phones;

    return contact;
  }

  static String getPreviewPath(Attachment attachment) {
    String fileName = attachment.transferName;
    String appDocPath = SettingsManager().appDocDir.path;
    String pathName = "$appDocPath/attachments/${attachment.guid}/$fileName";

    // If the file is an image, compress it for the preview
    if ((attachment.mimeType ?? "").startsWith("image/")) {
      String fn = fileName.split(".").sublist(0, fileName.length - 1).join("") + "prev";
      String ext = fileName.split(".").last;
      pathName = "$appDocPath/attachments/${attachment.guid}/$fn.$ext";
    }

    return pathName;
  }

  static bool canCompress(Attachment attachment) {
    String mime = attachment.mimeType ?? "";
    List<String> blacklist = ["image/gif"];
    return mime.startsWith("image/") && !blacklist.contains(mime);
  }
}
