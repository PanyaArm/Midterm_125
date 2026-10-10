import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_repository.dart';

void main() {
  runApp(const RestaurantQueueApp());
}

class RestaurantQueueApp extends StatelessWidget {
  const RestaurantQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Queue Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<QueueModel>> _queueList;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _queueList = DatabaseRepository.instance.get();
    });
  }

  void _showDeleteDialog(QueueModel queue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบคิวของ "${queue.customerName}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseRepository.instance.delete(queue.id!);
              Navigator.pop(context);
              _refreshData();
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('ระบบจัดการคิวร้านอาหาร'),
      ),
      body: FutureBuilder<List<QueueModel>>(
        future: _queueList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีคิวในระบบ'));
          }

          final queues = snapshot.data!;
          return ListView.builder(
            itemCount: queues.length,
            itemBuilder: (context, index) {
              final queue = queues[index];
              // แปลงรูปแบบวันที่ด้วย intl
              DateTime parsedDate = DateTime.parse(queue.createdAt);
              String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              queue.customerName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('จำนวนคน: ${queue.pax} ท่าน | โซน: ${queue.zone}'),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showDeleteDialog(queue),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFormScreen()),
          );
          if (result == true) {
            _refreshData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddFormScreen extends StatefulWidget {
  const AddFormScreen({super.key});

  @override
  State<AddFormScreen> createState() => _AddFormScreenState();
}

class _AddFormScreenState extends State<AddFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _paxController = TextEditingController();
  String? _selectedZone;

  final List<String> _zones = ['ห้องแอร์', 'พัดลม', 'กลับบ้าน'];

  @override
  void dispose() {
    _nameController.dispose();
    _paxController.dispose();
    super.dispose();
  }

  void _saveQueue() async {
    if (_formKey.currentState!.validate()) {
      final newQueue = QueueModel(
        customerName: _nameController.text,
        pax: int.parse(_paxController.text),
        zone: _selectedZone!,
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseRepository.instance.insert(newQueue);

      // ใช้ Navigator.pushReplacement ตามโจทย์กำหนดสลับหน้า หรือกลับหน้าหลัก
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('เพิ่มคิวใหม่')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ชื่อลูกค้า'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อลูกค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'จำนวนคน (รับเฉพาะตัวเลข)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนคน';
                  }
                  if (int.tryParse(value) == null) {
                    return 'กรุณากรอกเฉพาะตัวเลขเท่านั้น';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedZone,
                decoration: const InputDecoration(labelText: 'โซนที่ต้องการ'),
                items: _zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone,
                    child: Text(zone),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedZone = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาเลือกโซนที่ต้องการ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveQueue,
                child: const Text('บันทึกคิว'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}