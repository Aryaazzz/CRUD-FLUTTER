import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService; // Tambahkan hide FirebaseService di sini
import 'firebase_options.dart';
import 'firebase_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// 1. MODEL DATA
class UserData {
  String? id;
  String nama;
  int umur;
  String email;

  UserData({
    this.id,
    required this.nama,
    required this.umur,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'umur': umur,
      'email': email,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json, String docId) {
    return UserData(
      id: docId,
      nama: json['nama'] ?? '',
      umur: json['umur'] ?? 0,
      email: json['email'] ?? '',
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firestore CRUD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const UserListPage(),
    );
  }
}

// 2. HALAMAN UTAMA CRUD
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // DEKLARASI INI YANG SEBELUMNYA KURANG:
  final FirebaseService firebaseService = FirebaseService();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _umurController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _tampilkanForm({UserData? user}) {
    if (user != null) {
      _namaController.text = user.nama;
      _umurController.text = user.umur.toString();
      _emailController.text = user.email;
    } else {
      _namaController.clear();
      _umurController.clear();
      _emailController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user == null ? 'Tambah Data User' : 'Edit Data User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _umurController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Umur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final nama = _namaController.text.trim();
                final umur = int.tryParse(_umurController.text.trim()) ?? 0;
                final email = _emailController.text.trim();

                if (nama.isEmpty || email.isEmpty) return;

                final dataBaru = UserData(nama: nama, umur: umur, email: email);

                if (user == null) {
                  await firebaseService.tambah(dataBaru);
                } else {
                  await firebaseService.update(user.id!, dataBaru);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(user == null ? 'Simpan' : 'Perbarui'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data User (Firestore CRUD)'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<UserData>>(
        stream: firebaseService.ambilData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data di Firestore.'));
          }

          final daftarUser = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: daftarUser.length,
            itemBuilder: (context, index) {
              final user = daftarUser[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?'),
                  ),
                  title: Text(
                    user.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${user.email} • ${user.umur} tahun'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _tampilkanForm(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => firebaseService.hapus(user.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilkanForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}