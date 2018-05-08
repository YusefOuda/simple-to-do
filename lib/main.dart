import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Simple To-Do',
      theme: new ThemeData(
        primarySwatch: Colors.indigo,
        accentColor: Colors.pink,
        backgroundColor: Colors.grey[100],
        cardColor: Colors.white,
      ),
      home: new TodoListHome(title: 'Simple To-Do'),
    );
  }
}

class TodoListHome extends StatefulWidget {
  TodoListHome({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _TodoListHomeState createState() => new _TodoListHomeState();
}

class _TodoListHomeState extends State<TodoListHome> {
  var items = new List<TodoItem>();

  double _fontSize = 16.0;
  final _myController = new TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _loadItems();
    _loadSettings();
    super.initState();
  }

  _navigateToSettings() async {
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new SettingsScreen()),
    );
    var tmp = result; // just need to access result to block
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    _possiblyShowHintSnackBar(context);
    var scaffold = new Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(
              Icons.settings,
            ),
            onPressed: () {
              _navigateToSettings();
            },
          ),
        ],
      ),
      body: new ListView.builder(
        itemCount: items.length,
        itemBuilder: (c, index) {
          final item = items[index];
          if (item.text != null) {
            return _getTodoItemWidget(index, item, c);
          } else {
            return _getNewTodoItemWidget();
          }
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {
          _addTodoItem();
        },
        tooltip: 'Add Task',
        child: new Icon(Icons.add),
        backgroundColor: Theme.of(context).accentColor,
      ),
    );
    return scaffold;
  }

  void _possiblyShowHintSnackBar(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenSnackbar = prefs.getBool("has_seen_snackbar") ?? false;
    if (!hasSeenSnackbar) {
      _scaffoldKey.currentState.removeCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(
          content: new Text('Hint: Swipe tasks to delete them!'),
          duration: const Duration(milliseconds: 35000),
          action: new SnackBarAction(
            label: 'Got it!',
            onPressed: () {
              _acknowledgeHintSnackBar();
            },
          ),
        ),
      );
    }
  }

  _acknowledgeHintSnackBar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("has_seen_snackbar", true);
  }

  void _addTodoItem() {
    setState(() {
      if (_myController.text != null && _myController.text.isNotEmpty) {
        items.add(new TodoItem(text: _myController.text));
        _myController.clear();
      }
      items.removeWhere((i) => i.text == null);
      items.add(new TodoItem());
      _updateItems();
    });
  }

  _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List itemsList;
    try {
      itemsList = json.decode(prefs.getString("items"));
    } catch (Exception) {
      print('couldnt decode json');
      setState(() {
        items.add(new TodoItem());
      });
      return;
    }
    setState(() {
      if (itemsList != null && itemsList.length > 0) {
        items.clear();
      }
      itemsList.forEach((i) {
        var item = TodoItem.fromJson(i);
        items.add(item);
      });
    });
  }

  _updateItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("items", json.encode(items));
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var fontSize;
    fontSize = prefs.getDouble("font_size");
    if (fontSize != null) {
      setState(() {
        _fontSize = fontSize;
      });
    }
  }

  Widget _getNewTodoItemWidget() {
    return new Card(
      child: new ListTile(
        title: new TextField(
          decoration: new InputDecoration(
            hintText: 'Enter task...',
          ),
          controller: _myController,
          autofocus: true,
          onSubmitted: (text) {
            _addTodoItem();
          },
          style: new TextStyle(
            color: Colors.black,
            fontSize: _fontSize,
          ),
        ),
      ),
    );
  }

  Widget _getTodoItemWidget(index, item, context) {
    return new InkWell(
      child: new Card(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Dismissible(
              resizeDuration: const Duration(milliseconds: 10),
              movementDuration: const Duration(milliseconds: 10),
              onDismissed: (direction) {
                var removedItem;
                setState(() {
                  removedItem = items.removeAt(index);
                });
                Scaffold.of(context).removeCurrentSnackBar();
                Scaffold.of(context).showSnackBar(
                      new SnackBar(
                        content: new Text('Task deleted'),
                        duration: const Duration(milliseconds: 4000),
                        action: new SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            if (removedItem != null) {
                              setState(() {
                                items.insert(index, removedItem);
                              });
                            }
                          },
                        ),
                      ),
                    );
                _updateItems();
              },
              key: new ObjectKey(item),
              child: new CheckboxListTile(
                secondary: new Text(
                  '${index+1}.',
                  style: new TextStyle(
                    fontSize: _fontSize,
                  ),
                ),
                title: item.done
                    ? new Text(
                        '${item.text}',
                        style: new TextStyle(
                          fontSize: _fontSize,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      )
                    : new Text(
                        '${item.text}',
                        style: new TextStyle(
                          fontSize: _fontSize,
                        ),
                      ),
                value: item.done,
                onChanged: (bool value) {
                  setState(() {
                    item.done = !item.done;
                    _updateItems();
                  });
                },
              ),
            ),
            new Divider(
              height: 2.0,
            ),
          ],
        ),
      ),
    );
  }
}

class TodoItem {
  TodoItem({this.text});

  String text;
  bool done = false;

  TodoItem.fromJson(Map<String, dynamic> json)
      : text = json['text'],
        done = json['done'];

  Map<String, dynamic> toJson() => {
        'text': text,
        'done': done,
      };
}
