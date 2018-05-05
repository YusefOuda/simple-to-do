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

  void _addTodoItem() {
    setState(() {
      items.removeWhere((i) => i.text == null);
      items.add(new TodoItem());
    });
  }

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List itemsList;
    try {
      itemsList = json.decode(prefs.getString("items"));
    } catch (Exception) {
      print('couldnt decode json');
      return;
    }
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return new Dismissible(
            resizeDuration: const Duration(milliseconds: 10),
            movementDuration: const Duration(milliseconds: 10),
            background: new Container(color: Colors.blueAccent),
            onDismissed: (direction) {
              items.removeAt(index);
              Scaffold.of(context).showSnackBar(
                    new SnackBar(
                      content: new Text('Item dismissed'),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
              _updateItems();
            },
            key: new ObjectKey(item),
            child: item.text != null
                ? new CheckboxListTile(
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
                  )
                : new ListTile(
                    title: new TextField(
                      autofocus: true,
                      onSubmitted: (text) {
                        setState(() {
                          item.text = text;
                          _updateItems();
                        });
                      },
                      style: new TextStyle(
                        color: Colors.black,
                        fontSize: _fontSize,
                      ),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addTodoItem,
        tooltip: 'Add Item',
        child: new Icon(Icons.add),
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
