import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primaryColor: Colors.white),
      home: Home(),
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Icon check = Icon(Icons.check);
  Icon err = Icon(Icons.error);

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  TextEditingController _toDoController = TextEditingController();

  void _addToDo() {
    if (_toDoController.text.isEmpty) {
      final SnackBar snackErro = SnackBar(
        content: Text("Preencha o campo da tarefa"),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0XFF3c1053),
      );
      _scaffoldKey.currentState.showSnackBar(snackErro);
    } else {
      setState(() {
        Map<String, dynamic> newToDo = Map();
        newToDo["title"] = _toDoController.text;
        _toDoController.text = "";
        newToDo["ok"] = false;

        _toDoList.add(newToDo);
        _saveData();
      });
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: null,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0XFF3c1053),
                Color(0xFFad5389),
              ],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 1.0),
              stops: [0.1, 1.0],
            ),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(
                  (Icons.account_circle),
                  size: 200,
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _toDoController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Entre com uma tarefa",
                          labelStyle:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(7.0)),
                            gradient: LinearGradient(
                              colors: [
                                Color(0XFF3c1053),
                                Color(0xFFad5389),
                              ],
                              begin: FractionalOffset(1.0, 1.0),
                              end: FractionalOffset(0.0, 0.0),
                              stops: [0.1, 1.0],
                            )),
                        child: MaterialButton(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7.0))),
                          highlightColor: Colors.transparent,
                          elevation: 60,
                          onPressed: _addToDo,
                          child: Text(
                            "Adicionar",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 50),
                child: Stack(
                  children: <Widget>[
                    Container(
                        height: 400,
                        width: 350,
                        child: Card(
                            color: Colors.white,
                            elevation: 11,
                            child: RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.builder(
                                itemCount: _toDoList.length,
                                itemBuilder: buildItem,
                              ),
                            )))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(_toDoList[index]["title"].toString()),
      background: Container(
          color: Colors.red,
          child: Align(
              alignment: Alignment(-0.9, 0.0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ))),
      child: CheckboxListTile(
        onChanged: (checked) {
          setState(() {
            _toDoList[index]["ok"] = checked;
            _saveData();
          });
        },
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          backgroundColor: Color(0XFF3c1053),
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error,
            color: Color(0xFFad5389),
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();

            final snackDismiss = SnackBar(
              content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0XFF3c1053),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    setState(() {
                      _toDoList.insert(_lastRemovedPos, _lastRemoved);
                      _saveData();
                    });
                  }),
            );
            _scaffoldKey.currentState.removeCurrentSnackBar();
            _scaffoldKey.currentState.showSnackBar(snackDismiss);
          });
        }
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
