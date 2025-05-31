import 'package:flutter/material.dart';
import '../service/phone_service.dart';

class EditPhonePage extends StatefulWidget {
  @override
  _EditPhonePageState createState() => _EditPhonePageState();
}

class _EditPhonePageState extends State<EditPhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _specificationController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int? _phoneId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _phoneId == null) {
      _phoneId = args['id'];
      _fetchPhoneDetail();
    }
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price';
    }
    try {
      final price = int.parse(value);
      if (price <= 0) {
        return 'Price must be greater than 0';
      }
    } catch (e) {
      return 'Please enter a valid number';
    }
    return null;
  }

  void _fetchPhoneDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final phone = await PhoneService().fetchPhoneDetail(_phoneId!);
      _nameController.text = phone.name;
      _brandController.text = phone.brand;
      _priceController.text = phone.price.toString();
      _specificationController.text = phone.specification;
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _phoneId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await PhoneService().updatePhone(
        id: _phoneId!,
        name: _nameController.text,
        brand: _brandController.text,
        price: _priceController.text,
        specification: _specificationController.text,
      );

      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = 'Failed to update phone';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Phone')),
      body:
          _isLoading && _phoneId != null && _nameController.text.isEmpty
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Please enter a name'
                                    : null,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.branding_watermark),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Please enter a brand'
                                    : null,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validatePrice,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _specificationController,
                        decoration: InputDecoration(
                          labelText: 'Specification',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.settings),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Please enter specifications'
                                    : null,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                      ),
                      if (_error != null) ...[
                        SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Update Phone',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
