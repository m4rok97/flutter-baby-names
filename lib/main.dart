import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

final dummySnapshot = [
  {"name": "Filip", "votes": 15},
  {"name": "Abraham", "votes": 14},
  {"name": "Richard", "votes": 11},
  {"name": "Ike", "votes": 10},
  {"name": "Justin", "votes": 1},
];

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Something is wrong');
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              title: 'Baby Names',
              home: MyHomePage(),
            );
          }

          return Text('Loading');
        });
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Baby Name Votes')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // TODO: get actual snapshot from Cloud Firestore
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('Names').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Text('..Loading');
        }
        return _buildList(context, snapshot.data.docs);
      },
    );
  }

  Widget _buildList(
      BuildContext context, List<QueryDocumentSnapshot> snapshot) {
    return ListView.builder(
        itemExtent: 80,
        itemCount: snapshot.length,
        itemBuilder: (context, index) {
          return _buildListItem(context, snapshot[index]);
        });

    // return ListView(
    //   padding: const EdgeInsets.only(top: 20.0),
    //   children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    // );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    print('Llega al item');
    return Padding(
      key: ValueKey(document['name']),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(document['name']),
          trailing: Text(document['votes'].toString()),
          onTap: () {
            // document.reference.update({'votes': document['votes'] + 1});
            FirebaseFirestore.instance.runTransaction((transaction) async {
              DocumentSnapshot freshSnap =
                  await transaction.get(document.reference);
              await transaction.update(
                  freshSnap.reference, {'votes': freshSnap['votes'] + 1});
            });
          },
        ),
      ),
    );
  }
}

class Record {
  final String name;
  final int votes;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$votes>";
}
