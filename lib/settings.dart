import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double fontSize;

  @override
  void initState() {
    _loadSettings();
    super.initState();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var size = prefs.getDouble("font_size");
    if (size != null) {
      setState(() {
        fontSize = size;
      });
    } else {
      setState(() {
        fontSize = 18.0;
      });
    }
  }

  void _updateSettings(value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("font_size", fontSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          left: 10.0,
          top: 20.0,
          right: 10.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Text(
                  'Font size',
                  style: TextStyle(
                    fontSize: fontSize,
                  ),
                ),
                Expanded(
                  child: Slider(
                    divisions: 10,
                    min: 16.0,
                    max: 26.0,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          fontSize = value;
                          _updateSettings(value);
                        });
                      }
                    },
                    value: (fontSize ?? 16.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
