import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';
import 'auth_screen.dart';

class TestResultsScreen extends StatefulWidget {
  const TestResultsScreen({super.key});
  @override
  State<TestResultsScreen> createState()=>_TestResultsScreenState();
}
class _TestResultsScreenState extends State<TestResultsScreen> {
  final _api=PatientApiService();
  String? _token,_error;
  bool _loading=false,_imageLoading=false;
  List<Map<String,dynamic>> _items=[];
  @override
  void didChangeDependencies(){super.didChangeDependencies();final token=context.watch<AuthViewModel>().currentUser?.token;if(token!=_token){_token=token;_items=[];_error=null;if(token!=null)_load(token);}}
  Future<void> _load(String token)async{
    setState((){_loading=true;_error=null;});
    try{final items=await _api.getLabResults(token);if(!mounted||_token!=token)return;setState((){_items=items;_loading=false;});}
    catch(e){if(mounted&&_token==token)setState((){_error='$e';_loading=false;});}
  }
  Future<void> _image(Map<String,dynamic> item)async{
    if(_imageLoading||_token==null)return;
    final token=_token!;setState(()=>_imageLoading=true);
    try{final bytes=await _api.getLabImage(token,item['id'] as int);if(!mounted||_token!=token)return;
      await showDialog<void>(context:context,builder:(ctx)=>Dialog(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Padding(padding:const EdgeInsets.all(12),child:Text('${item['ten_dich_vu']}')),
        Flexible(child:InteractiveViewer(minScale:0.5,maxScale:5,child:Image.memory(bytes,errorBuilder:(_,__,___)=>const Padding(padding:EdgeInsets.all(24),child:Text('Không đọc được ảnh kết quả.'))))),
        TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Đóng')),
      ])));
    }catch(e){if(mounted&&_token==token)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>_imageLoading=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(backgroundColor:AppColors.slate50,
    appBar:AppBar(title:const Text('Kết quả xét nghiệm & CĐHA'),actions:[if(_token!=null)IconButton(onPressed:_loading?null:()=>_load(_token!),icon:const Icon(Icons.refresh))]),
    body:_token==null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Đăng nhập để xem kết quả xét nghiệm.'),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AuthScreen())),child:const Text('Đăng nhập'))])):
      RefreshIndicator(onRefresh:()=>_load(_token!),child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(20),children:[
        if(_loading)const LinearProgressIndicator(),if(_error!=null)RequestError(message:_error!,onRetry:()=>_load(_token!)),
        if(!_loading&&_error==null&&_items.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('Chưa có kết quả đã được bác sĩ duyệt.')),
        ..._items.map((item){final cls=item['cls'] is Map?item['cls'] as Map:item;final measurements=cls['chi_so'];return Card(child:ExpansionTile(
          title:Text('${item['ten_dich_vu']??item['ten']??''}',style:const TextStyle(fontWeight:FontWeight.bold)),
          subtitle:Text('${item['loai_dich_vu']??item['loai']??''}\n${patientDate(item['thoi_gian_kham'])} • ${item['trang_thai']??''}'),
          childrenPadding:const EdgeInsets.all(16),expandedCrossAxisAlignment:CrossAxisAlignment.start,
          children:[Text('Phiếu khám: ${item['ma_phieu']??''}'),Text('Bác sĩ chỉ định: ${item['bac_si_chi_dinh']??''}'),
            if(item['chan_doan']!=null)Text('Chẩn đoán: ${item['chan_doan']}'),
            const Divider(),SelectableText('${item['ket_qua']??'Chưa có nội dung kết quả'}'),
            if(cls['don_vi']!=null)Text('Đơn vị: ${cls['don_vi']}'),
            if(cls['khoang_tham_chieu']!=null)Text('Khoảng tham chiếu: ${cls['khoang_tham_chieu']}'),
            if(cls['ket_luan']!=null)Text('Kết luận: ${cls['ket_luan']}'),
            if(measurements is List)...measurements.whereType<Map>().map((m)=>Padding(padding:const EdgeInsets.only(top:8),child:Text('${m['ten']??m['ten_chi_so']??''}: ${m['gia_tri']??m['ket_qua']??''} ${m['don_vi']??''} • Tham chiếu: ${m['khoang_tham_chieu']??''}'))),
            Text('Thực hiện: ${item['nguoi_thuc_hien']??item['bac_si_thuc_hien']??''}'),
            if(item['file_endpoint']!=null)TextButton.icon(onPressed:_imageLoading?null:()=>_image(item),icon:const Icon(Icons.image),label:Text(_imageLoading?'Đang tải ảnh...':'Xem ảnh kết quả')),
          ],
        ));}),
      ])),
  );
}
