import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    _user = _auth.currentUser;
    if (_user == null) {
      try {
        UserCredential userCredential = await _auth.signInAnonymously();
        _user = userCredential.user;
      } catch (e) {
        print('Error signing in anonymously: $e');
      }
    }
  }

  void _sendMessage(String text) async {
    try {
     // Position position = await Geolocator.getCurrentPosition(
      //    desiredAccuracy: LocationAccuracy.high);
      //Position position = 333;
      await _firestore.collection('messages').add({
        'text': text,
        'senderName': _user?.displayName ?? 'Anonymous',
        'senderEmail': _user?.email ?? '',
        'timestamp': 55,
        //'location': GeoPoint(position.latitude, position.longitude),
        'location': 22,
      });
      _textController.clear();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Firebase Chat'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs;
                List<MessageBubble> messageBubbles = [];
                for (var message in messages) {
                  final messageText = message['text'];
                  final senderName = message['senderName'];
                  final senderEmail = message['senderEmail'];
                  final location = message['location'];
                  final messageBubble = MessageBubble(
                    senderName: senderName,
                    senderEmail: senderEmail,
                    text: messageText,
                    isMe: _user?.email == senderEmail,
                    location: location,
                  );
                  messageBubbles.add(messageBubble);
                }
                return ListView(
                  reverse: true,
                  padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                  children: messageBubbles,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      _sendMessage(_textController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({required this.senderName, required this.senderEmail, required this.text, required this.isMe, required this.location});

  final String senderName;
  final String senderEmail;
  final String text;
  final bool isMe;
  //final GeoPoint location;
  final int location;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            senderName,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 2.0),
          Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10.0),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15.0,
                      color: isMe ? Colors.white : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    'Location: ${location}',
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
