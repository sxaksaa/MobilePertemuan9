import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import yang dibutuhkan
import 'firebase_options.dart'; 

// --- 1. Inisialisasi Firebase dan runApp ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
  runApp(const Belajar1());
}

// ===============================================
// 2. AUTHENTICATION GATE (PENGATUR HALAMAN AWAL)
// ===============================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan perubahan status otentikasi
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan loading saat menunggu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Jika user sudah login (user tidak null)
        if (snapshot.hasData) {
          return const Belajar2(); // Halaman Form Utama (Home)
        }

        // Jika user belum login (user null)
        return const LoginPage(); // Halaman Login
      },
    );
  }
}

// --- 3. Kelas Utama (App Routing) ---
class Belajar1 extends StatelessWidget {
  const Belajar1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Firebase Form",
      // initialRoute sekarang menggunakan AuthGate sebagai home
      home: const AuthGate(), 
      routes: {
        // Kita tidak lagi menggunakan '/' sebagai halaman awal, 
        // tapi kita daftarkan Belajar2 sebagai '/home' (opsional, tapi berguna)
        '/home': (context) => const Belajar2(), 
        '/hal2': (context) => const HalamanDua(),
        '/hal3': (context) => const HalamanTiga(),
        '/hal4': (context) => const HalamanEmpat(),
        '/hal5': (context) => const HalamanLima(),
      },
    );
  }
}

// ===============================================
// 4. LOGIN PAGE (KODE DARI ANDA)
// ===============================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      // AuthGate akan otomatis mengarahkan ke Belajar2
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-email' => 'Format email tidak valid.',
          'user-not-found' => 'Akun tidak ditemukan.',
          'wrong-password' => 'Password salah.',
          'user-disabled' => 'Akun dinonaktifkan.',
          _ => 'Login gagal: ${e.code}',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      // Setelah register sukses, otomatis logged-in.
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'Email sudah digunakan.',
          'weak-password' => 'Password terlalu lemah (min. 6 karakter).',
          'invalid-email' => 'Format email tidak valid.',
          _ => 'Registrasi gagal: ${e.code}',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Mahasiswa UB'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'image/logoub3.png',
                    height: 100,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min. 6 karakter' : null,
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: _loading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.login),
                          label: const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _register,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: const BorderSide(color: Colors.deepPurple),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Register', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================
// 5. HALAMAN UTAMA (Formulir dengan Log Out Button)
// ===============================================

class Belajar2 extends StatefulWidget {
  const Belajar2({super.key});

  @override
  State<Belajar2> createState() => _Belajar2State();
}

class _Belajar2State extends State<Belajar2> {
  // --- Variabel State Formulir ---
  int currentStep = 0;
  final TextEditingController isi = TextEditingController(); 
  String? selectedJurusan;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  double sliderValue = 50.0;
  Map<String, bool> hobiMap = {
    'Olahraga': false,
    'Membaca': false,
    'Menulis': false,
    'Traveling': false,
  };
  String jenjang = "D3";
  bool isSwitched = false;
  
  // Ambil user saat ini
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // --- Integrasi Firebase Realtime Database ---
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child("pendaftaran_mahasiswa");

  // --- FUNGSI KIRIM DATA KE FIREBASE ---
  void _kirimDataPendaftaran() {
    if (isi.text.isEmpty || selectedJurusan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nama dan Jurusan wajib diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dataPendaftaran = {
      "user_id": currentUser?.uid ?? 'anon', // Tambahkan User ID
      "nama": isi.text,
      "jurusan": selectedJurusan,
      "tanggal_daftar": selectedDate?.toIso8601String() ?? "Tidak dipilih",
      "waktu_daftar": selectedTime?.format(context) ?? "Tidak dipilih",
      "nilai_tes": sliderValue.toInt(), 
      "hobi": hobiMap.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(), 
      "jenjang": jenjang,
      "kehadiran": isSwitched ? "Hadir" : "Tidak Hadir",
      "waktu_kirim": ServerValue.timestamp, 
    };

    dbRef.push().set(dataPendaftaran).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Data pendaftaran berhasil dikirim ke Firebase!"),
          backgroundColor: Colors.green,
        ),
      );
      _clearForm(); 
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Gagal mengirim data: $error"),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // --- FUNGSI LOGOUT ---
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthGate akan otomatis mengarahkan kembali ke LoginPage
  }


  // --- FUNGSI RESET FORM ---
  void _clearForm() {
    setState(() {
      isi.clear();
      selectedJurusan = null;
      selectedDate = null;
      selectedTime = null;
      sliderValue = 50.0;
      hobiMap = hobiMap.map((key, value) => MapEntry(key, false));
      jenjang = "D3";
      isSwitched = false;
      currentStep = 0; 
    });
  }

  // --- FUNGSI Date and Time Picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
        context: context, initialTime: selectedTime ?? TimeOfDay.now());
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        title: Row(
          children: [
            Image.asset(
              'image/logoub2.png', 
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              "UNIVERSITAS BRAWIJAYA",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol Log Out
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.deepPurple),
            label: const Text("Log Out", style: TextStyle(color: Colors.deepPurple)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      body: Stack(
        children: [
          // LAYER 1: Background Image (Diberi Opacity)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15, // Nilai Opacity (15%)
              child: Image.asset(
                'image/logoub3.png', 
                fit: BoxFit.cover,
              ),
            ),
          ),

          // LAYER 2: Konten Formulir
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0), 
                  child: Text(
                    "Mahasiswa UB | UID: ${currentUser?.uid ?? 'Loading...'}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent, 
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        surface: Colors.transparent, 
                      ),
                    ),
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: currentStep,
                      onStepContinue: () {
                        if (currentStep < 5) {
                          setState(() => currentStep += 1);
                        } else {
                          _kirimDataPendaftaran();
                        }
                      },
                      onStepCancel: () {
                        if (currentStep > 0) {
                          setState(() => currentStep -= 1);
                        }
                      },
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: <Widget>[
                              if (currentStep < 5) 
                                ElevatedButton(
                                  onPressed: details.onStepContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple, 
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Continue'),
                                ),
                              const SizedBox(width: 8),
                              if (currentStep > 0) 
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepPurple, 
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              if (currentStep == 5) 
                                ElevatedButton(
                                  onPressed: _kirimDataPendaftaran,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green, 
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Submit Data'),
                                ),
                            ],
                          ),
                        );
                      },
                      steps: [
                        // STEP 1: Nama
                        Step(
                          title: const Text('1. Nama', style: TextStyle(color: Colors.black)),
                          content: TextField(
                            controller: isi,
                            decoration: const InputDecoration(
                              labelText: 'Masukkan Nama',
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          isActive: currentStep >= 0,
                          state: currentStep > 0 ? StepState.complete : StepState.editing,
                        ),
                        // STEP 2: Jurusan
                        Step(
                          title: const Text('2. Jurusan', style: TextStyle(color: Colors.black)),
                          content: DropdownButtonFormField<String>(
                            value: selectedJurusan,
                            hint: const Text("Pilih Jurusan"),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: ['Teknologi Informasi', 'Ekonomi', 'Bahasa Inggris', 'Matematika']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedJurusan = newValue;
                              });
                            },
                            style: const TextStyle(color: Colors.black),
                            dropdownColor: Colors.white,
                          ),
                          isActive: currentStep >= 1,
                          state: currentStep > 1 ? StepState.complete : StepState.editing,
                        ),
                        // STEP 3: Tanggal & Waktu
                        Step(
                          title: const Text('3. Tanggal & Waktu', style: TextStyle(color: Colors.black)),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _selectDate(context),
                                icon: const Icon(Icons.calendar_today, color: Colors.white),
                                label: Text(
                                  selectedDate == null
                                      ? 'Pilih Tanggal'
                                      : 'Tanggal: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () => _selectTime(context),
                                icon: const Icon(Icons.access_time, color: Colors.white),
                                label: Text(
                                  selectedTime == null
                                      ? 'Pilih Waktu'
                                      : 'Waktu: ${selectedTime!.format(context)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                              ),
                            ],
                          ),
                          isActive: currentStep >= 2,
                          state: currentStep > 2 ? StepState.complete : StepState.editing,
                        ),
                        // STEP 4: Nilai
                        Step(
                          title: Text('4. Nilai ( ${sliderValue.toInt()} )', style: const TextStyle(color: Colors.black)),
                          content: Slider(
                            value: sliderValue,
                            min: 0,
                            max: 100,
                            divisions: 100,
                            label: sliderValue.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                sliderValue = value;
                              });
                            },
                            activeColor: Colors.deepPurple,
                            inactiveColor: Colors.deepPurple.withOpacity(0.3),
                          ),
                          isActive: currentStep >= 3,
                          state: currentStep > 3 ? StepState.complete : StepState.editing,
                        ),
                        // STEP 5: Hobi
                        Step(
                          title: const Text('5. Hobi', style: TextStyle(color: Colors.black)),
                          content: Column(
                            children: hobiMap.keys.map((String key) {
                              return CheckboxListTile(
                                title: Text(key, style: const TextStyle(color: Colors.black)),
                                value: hobiMap[key],
                                onChanged: (bool? value) {
                                  setState(() {
                                    hobiMap[key] = value!;
                                  });
                                },
                                activeColor: Colors.deepPurple,
                                checkColor: Colors.white,
                              );
                            }).toList(),
                          ),
                          isActive: currentStep >= 4,
                          state: currentStep > 4 ? StepState.complete : StepState.editing,
                        ),
                        // STEP 6: Jenjang
                        Step(
                          title: const Text('6. Jenjang', style: TextStyle(color: Colors.black)),
                          content: Column(
                            children: ['D3', 'S1', 'S2'].map((String value) {
                              return RadioListTile<String>(
                                title: Text(value, style: const TextStyle(color: Colors.black)),
                                value: value,
                                groupValue: jenjang,
                                onChanged: (String? val) {
                                  setState(() {
                                    jenjang = val!;
                                  });
                                },
                                activeColor: Colors.deepPurple,
                              );
                            }).toList(),
                          ),
                          isActive: currentStep >= 5,
                          state: currentStep > 5 ? StepState.complete : StepState.editing,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSwitched ? "Hadir: Ya" : "Hadir: Tidak",
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                Switch(
                  value: isSwitched,
                  onChanged: (value) {
                    setState(() {
                      isSwitched = value;
                    });
                  },
                  activeTrackColor: Colors.deepPurple.withOpacity(0.5),
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column( 
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _kirimDataPendaftaran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "KIRIM DATA",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/hal2", arguments: isi.text);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                  child: const Text(
                    "Ke Halaman 2",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 6. HALAMAN NAVIGASI LAINNYA (TIDAK BERUBAH)
// ===============================================

class HalamanDua extends StatelessWidget {
  const HalamanDua({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as String? ?? 'Data tidak tersedia';

    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Dua")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Selamat datang, $args!"),
            const Text("Ini adalah Halaman Kedua"),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/hal3', arguments: "Pesan dari Halaman 2");
              },
              child: const Text("Ke Halaman 3"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Kembali ke Halaman 1"),
            ),
          ],
        ),
      ),
    );
  }
}

class HalamanTiga extends StatelessWidget {
  const HalamanTiga({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as String? ?? 'Data tidak tersedia';

    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Tiga")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pesan diterima: $args"),
            const Text("Ini adalah Halaman Ketiga"),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/hal4', arguments: "Pesan dari Halaman 3");
              },
              child: const Text("Ke Halaman 4"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Kembali ke Halaman 2"),
            ),
          ],
        ),
      ),
    );
  }
}

class HalamanEmpat extends StatelessWidget {
  const HalamanEmpat({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as String? ?? 'Data tidak tersedia';

    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Empat")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pesan diterima: $args"),
            const Text("Ini adalah Halaman Keempat"),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/hal5', arguments: "Pesan dari Halaman 4");
              },
              child: const Text("Ke Halaman 5"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Kembali ke Halaman 3"),
            ),
          ],
        ),
      ),
    );
  }
}

class HalamanLima extends StatelessWidget {
  const HalamanLima({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as String? ?? 'Data tidak tersedia';

    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Lima")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pesan diterima: $args"),
            const Text("Ini adalah Halaman Kelima dan terakhir"),
            const Text("Gunakan tombol back di AppBar untuk kembali ke Halaman 4"),
          ],
        ),
      ),
    );
  }
}

//tes