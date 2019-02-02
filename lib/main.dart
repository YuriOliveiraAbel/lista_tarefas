import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

void main(){

  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoCotroller = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //Metodo executado quando carrega o app
  @override
  void initState(){
    super.initState();    
    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data); 
      });
    });
  }

  void _addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoCotroller.text;
      _toDoCotroller.text = '';
      newToDo["ok"] = false;
      _toDoList.add(newToDo); 
      _saveData();
    });
  }
  //Atualização da tela 
  Future<Null> _refresh() async{ //Future indica função com uma ação no futuro
    await Future.delayed(Duration(seconds: 1)); //Definido o tempo de 1 segundo

    setState(() {
      //Ordenando a lista
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();    
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                  controller: _toDoCotroller,  
                  decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh, 
              child: ListView.builder(//ListViwe é um widget para mostrar listas na tela e builder constroi conforme a lista é preenchida
              padding: EdgeInsets.only(top: 10),
              itemCount: _toDoList.length,
              itemBuilder: builItem
            ),
            )
          )
        ],
      ),
    );
  }

  Widget builItem(context, index){
    //index é o elemento da lista que está sendo desenhada
    //Dismissible é a animação para exclusão de listas
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),//quando realiza a esclusão necessita diferenciar cada item da lista, para isso está usando a data em milisegundos para diferenciar
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),//posiciona o item conforme coordenadas
          child: Icon(Icons.delete, color: Colors.white,)
        ),
      ),
      direction: DismissDirection.startToEnd,//Indicar qual posição deve arrastar o item para excluilo
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? 
            Icons.check : Icons.error
          ),
        ),
        onChanged: (c){
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData(); 
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData(); 

          //Snackbar para desfazer a exclusão da lista
          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved['title']} removida!"),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });               
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  /*
  Esse metodos e a configuração onde será armazenada as tarefas em arquivos json.
  1. getApplicationDocumentsDirectory pega o diretorio onde será armazenado os documentos do app.
  2. getApplicationDocumentsDirectory não é executado instantaneamento por isso é necessario o uso do await.
  3. directory.path pega o caminho no qual está o arquivo e realiza a abertura dele atraves do File.
  4. sempre que for necessario pegar o arquivo basta chamar o _getFile.
*/
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');    
  }

  // Função para salvar dados no arquivo.
  Future<File> _saveData() async{
    String data = json.encode(_toDoList); 
    final file = await _getFile(); 
    return file.writeAsString(data);
  }

  // Função de leitura do arquivo.
  Future<String> _readData() async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }
}

