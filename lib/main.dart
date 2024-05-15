import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter_web/flutter_web.dart';

WebEngage webengage = new WebEngage();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebEngage Flutter WebSDK POC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController cuidController = TextEditingController();
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController snameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController eventNameController = TextEditingController();

  // Lists to manage multiple custom attributes
  List<TextEditingController> customAttrKeys = [TextEditingController()];
  List<TextEditingController> customAttrValues = [TextEditingController()];

  // Lists to manage multiple event attributes
  List<TextEditingController> eventAttrKeys = [TextEditingController()];
  List<TextEditingController> eventAttrValues = [TextEditingController()];

  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    loadFromLocalStorage();
  }

  Future<void> loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cuid = prefs.getString('cuid') ?? '';
    if (cuid.isNotEmpty) {
      setState(() {
        cuidController.text = cuid;
        fnameController.text = prefs.getString('fname') ?? '';
        snameController.text = prefs.getString('sname') ?? '';
        phoneController.text = prefs.getString('phone') ?? '';
        isLoggedIn = true;
      });
      setWebEngageCUID(cuid);
    }
  }

  Future<void> storeInLocalStorage(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  void trackAttribute() {
    for (int i = 0; i < customAttrKeys.length; i++) {
      if (customAttrKeys[i].text.isNotEmpty) {
        setWebEngageAttributes(
            customAttrKeys[i].text, detectType(customAttrValues[i].text));
      }
    }
    setState(() {
      isLoggedIn = true;
    });
  }

  void onFormSubmit() {
    final cuid = cuidController.text;
    final fname = fnameController.text;
    final sname = snameController.text;
    final phone = phoneController.text;

    if (validate(cuid)) {
      setWebEngageCUID(cuid);
      storeInLocalStorage('cuid', cuid);
      if (fname.isNotEmpty) {
        setWebEngageAttributes('we_first_name', fname);
        storeInLocalStorage('fname', fname);
      }
      if (sname.isNotEmpty) {
        setWebEngageAttributes('we_second_name', sname);
        storeInLocalStorage('sname', sname);
      }
      if (phone.isNotEmpty) {
        setWebEngageAttributes('we_phone', phone);
        storeInLocalStorage('phone', phone);
      }
      for (int i = 0; i < customAttrKeys.length; i++) {
        if (customAttrKeys[i].text.isNotEmpty) {
          setWebEngageAttributes(
              customAttrKeys[i].text, detectType(customAttrValues[i].text));
        }
      }

      setState(() {
        isLoggedIn = true;
      });
    }
  }

  void onLogout() {
    clearLocalStorage();
    setWebEngageLogout();
    setState(() {
      isLoggedIn = false;
      cuidController.clear();
      fnameController.clear();
      snameController.clear();
      phoneController.clear();
      customAttrKeys = [TextEditingController()];
      customAttrValues = [TextEditingController()];
    });
  }

  Future<void> clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('cuid');
    prefs.remove('fname');
    prefs.remove('sname');
    prefs.remove('phone');
  }

  bool validate(String value) {
    return value.isNotEmpty;
  }

  void setWebEngageAttributes(String key, dynamic value) {
    webengage.user.setAttribute(key, value);
  }

  void setWebEngageCUID(String cuid) {
    webengage.user.login(cuid);
  }

  void setWebEngageLogout() {
    webengage.user.logout();
  }

  void onEventClick() {
    final eventName = eventNameController.text;
    Map<String, dynamic> eventDataVal = {};

    for (int i = 0; i < eventAttrKeys.length; i++) {
      if (eventAttrKeys[i].text.isNotEmpty) {
        eventDataVal[eventAttrKeys[i].text] =
            detectType(eventAttrValues[i].text);
      }
    }

    if (validate(eventName)) {
      webengage.track(eventName, eventDataVal);
    }
  }

  dynamic detectType(String input) {
    if (input.isEmpty) {
      return input;
    }

    if (input.toLowerCase() == 'true' || input.toLowerCase() == 'false') {
      return input.toLowerCase() == 'true';
    }

    // Check for number
    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(input)) {
      return num.tryParse(input) ?? input;
    }

    try {
      DateTime parsedDate = DateTime.parse(input);
      return parsedDate;
    } catch (e) {}

    try {
      var parsedArray = json.decode(input);
      if (parsedArray is List) {
        return parsedArray;
      }
    } catch (e) {}

    try {
      var parsedMap = json.decode(input);
      if (parsedMap is Map) {
        return parsedMap;
      }
    } catch (e) {}

    return input;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('WebEngage Flutter WebSDK POC'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Home'),
              Tab(text: 'Event'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: cuidController,
                    decoration: InputDecoration(labelText: 'Username'),
                    enabled: !isLoggedIn,
                  ),
                  TextField(
                    controller: fnameController,
                    decoration: InputDecoration(labelText: 'First Name'),
                  ),
                  TextField(
                    controller: snameController,
                    decoration: InputDecoration(labelText: 'Second Name'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: customAttrKeys.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: customAttrKeys[index],
                                decoration: InputDecoration(
                                    labelText: 'Custom/System Attribute Name'),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: customAttrValues[index],
                                decoration: InputDecoration(
                                    labelText: 'Attribute Value'),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  customAttrKeys.removeAt(index);
                                  customAttrValues.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        customAttrKeys.add(TextEditingController());
                        customAttrValues.add(TextEditingController());
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: isLoggedIn ? null : onFormSubmit,
                        child: Text('Login'),
                      ),
                      ElevatedButton(
                        onPressed: isLoggedIn ? onLogout : null,
                        child: Text('Logout'),
                      ),
                      ElevatedButton(
                        onPressed: isLoggedIn ? trackAttribute : null,
                        child: Text('Track Attribute'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: eventNameController,
                    decoration: InputDecoration(labelText: 'Event Name'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: eventAttrKeys.length,
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: eventAttrKeys[index],
                                decoration: InputDecoration(
                                    labelText: 'Event Attribute Name'),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: eventAttrValues[index],
                                decoration: InputDecoration(
                                    labelText: 'Event Attribute Value'),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  eventAttrKeys.removeAt(index);
                                  eventAttrValues.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        eventAttrKeys.add(TextEditingController());
                        eventAttrValues.add(TextEditingController());
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onEventClick,
                    child: Text('Track'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
