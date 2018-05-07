import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Simple To-Do',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Simple To-Do'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var items = new List<TodoItem>();

  final _fontSize = 20.0;
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _possiblyShowHintSnackBar(context);
    var scaffold = new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.title),
        leading: new Icon(Icons.list),
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
          duration: const Duration(milliseconds: 15000),
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

  Widget _getNewTodoItemWidget() {
    return new ListTile(
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
    );
  }

  Widget _getTodoItemWidget(index, item, context) {
    return new Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Dismissible(
          resizeDuration: const Duration(milliseconds: 10),
          movementDuration: const Duration(milliseconds: 10),
          background: new Container(color: Colors.blueAccent),
          onDismissed: (direction) {
            setState(() {
              items.removeAt(index);
            });
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(
                  new SnackBar(
                    content: new Text('Task deleted'),
                    duration: const Duration(milliseconds: 1000),
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
