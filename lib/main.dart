import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(WasindiApp());
}

class WasindiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Familia ya Wasindi',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return HomePage();
          return LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Familia ya Wasindi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Misiba | Ndoa | Harambee', style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('Ingia na Google'),
              onPressed: signInWithGoogle,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _textController = TextEditingController();
  String _selectedType = 'Misiba';

  void _postMatangazo() {
    if (_textController.text.isEmpty) return;
    FirebaseFirestore.instance.collection('matangazo').add({
      'aina': _selectedType,
      'ujumbe': _textController.text,
      'mtumiaji': FirebaseAuth.instance.currentUser!.displayName,
      'email': FirebaseAuth.instance.currentUser!.email,
      'muda': FieldValue.serverTimestamp(),
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Familia ya Wasindi'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: ['Misiba', 'Ndoa', 'Harambee', 'Mengineyo']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'Andika tangazo hapa...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _postMatangazo,
                  child: Text('Tuma Tangazo'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45)),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
            .collection('matangazo')
            .orderBy('muda', descending: true)
            .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(data['aina'][0])),
                        title: Text('${data['aina']}: ${data['ujumbe']}'),
                        subtitle: Text('Na: ${data['mtumiaji']}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
