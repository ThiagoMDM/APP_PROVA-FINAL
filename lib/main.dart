import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove o banner de depuração
      debugShowCheckedModeBanner: false,
      title: 'Prova final APP',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  CollectionReference _productss =
      FirebaseFirestore.instance.collection('produtos');

  // Esta função é acionada quando o botão flutuante ou um dos botões de edição é pressionado
  // Adicionar um produto se nenhum documentSnapshot for passado
  // Se documentSnapshot! = Null então atualize um produto existente
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['nome'];
      _priceController.text = documentSnapshot['preco'].toString();
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Nome'),
                  
                ),
                TextField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Preco',
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                ElevatedButton(
                  
                  child: Text(action == 'create' ? 'Adicionar' : 'Atualizar'),
                  onPressed: () async {
                    final String? name = _nameController.text;
                    final double? price =
                        double.tryParse(_priceController.text);
                    if (name != null && price != null) {
                      if (action == 'create') {
                        // Persistir um novo produto para Firestore
                        await _productss.add({"nome": name, "preco": price});
                      }
                        // Atualiza o produto
                      if (action == 'update') {
                        
                        await _productss
                            .doc(documentSnapshot!.id)
                            .update({"nome": name, "preco": price});
                      }

                      // Limpa os campos de texto
                      _nameController.text = '';
                      _priceController.text = '';

                      // Esconde a folha inferior
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }
  // Excluindo um produto por id
  Future<void> _deleteProduct(String productId) async {
    await _productss.doc(productId).delete();

    // Mostrar um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto deletado com Sucesso!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('Lista de Compras'),
      ),
      
// Usando o StreamBuilder para exibir todos os produtos do Firestore em tempo real
      body: StreamBuilder(
        stream: _productss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Card(
                  margin: EdgeInsets.all(20),
                  child: ListTile(
                    title: Text(documentSnapshot['nome']),
                    subtitle: Text(documentSnapshot['preco'].toString()),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Pressione este botão para editar um único produto
                          IconButton(
                              icon: Icon(Icons.edit),
                              
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          // Este botão de ícone é usado para excluir um único produto
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteProduct(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Adiciona novo produto
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}