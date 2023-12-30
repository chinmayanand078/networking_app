import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlbumManager {
  Future<List<Album>> fetchAlbums() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<Album> albums =
          data.map((json) => Album.fromJson(json)).toList();
      return albums;
    } else {
      throw Exception('Failed to load albums');
    }
  }

  Future<Album> createAlbum(int userId, int id, String title) async {
    final response = await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/albums'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'userId': userId,
        'id': id,
        'title': title,
      }),
    );

    if (response.statusCode == 201) {
      return Album.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create album.');
    }
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  const Album({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    switch (json.keys.length) {
      case 3:
        return Album(
          userId: json['userId'],
          id: json['id'],
          title: json['title'],
        );
      default:
        throw const FormatException('Failed to load album.');
    }
  }
}

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Album>> futureAlbum;

  @override
  void initState() {
    super.initState();
    final albumManager = AlbumManager();
    futureAlbum = albumManager.fetchAlbums();
  }

  void refreshAlbumList() {
    setState(() {
      final albumManager = AlbumManager();
      futureAlbum = albumManager.fetchAlbums();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album Data',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(secondary: Colors.orange), // Change accent color to orange
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text('Album Data'),
        ),
        body: Center(
          child: FutureBuilder<List<Album>>(
            future: futureAlbum,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      Album album = snapshot.data![index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.album),
                          title: Text(album.title),
                          subtitle: Text("ID: ${album.id}"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                refreshAlbumList();
                              });
                            },
                          ),
                        ),
                      );
                    });
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }

              return const CircularProgressIndicator();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            _showAlbumCreationDialog(context, refreshAlbumList);
          },
          tooltip: "Add Album",
        ),
      ),
    );
  }

  Future<void> _showAlbumCreationDialog(
      BuildContext context, VoidCallback refreshCallback) async {
    final TextEditingController userIdController = TextEditingController();
    final TextEditingController idController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Album"),
          content: Container(
            height: 200,
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTextFieldRow("User ID :", userIdController),
                const SizedBox(height: 15),
                _buildTextFieldRow("ID :", idController),
                const SizedBox(height: 15),
                _buildTextFieldRow("Title :", titleController),
              ],
            ),
          ),
          actions: [
            _buildDialogButton(
              "Submit",
              () async {
                try {
                  final albumManager = AlbumManager();
                  await albumManager.createAlbum(
                    int.parse(userIdController.text),
                    int.parse(idController.text),
                    titleController.text,
                  );

                  Navigator.pop(context);
                  refreshCallback();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating album: $e'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            _buildDialogButton("Close", () => Navigator.pop(context)),
          ],
        );
      },
    );
  }

  Widget _buildTextFieldRow(String labelText, TextEditingController controller) {
    return Row(
      children: [
        Text(labelText),
        SizedBox(
          width: 200,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter value",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
