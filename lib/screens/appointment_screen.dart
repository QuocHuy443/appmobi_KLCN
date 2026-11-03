import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/appointment_booking_form.dart';
import '../widgets/request_error.dart';
import 'auth_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key, this.refreshVersion=0, this.initialTab=0});
  final int refreshVersion;
  final int initialTab;
  @override
  State<AppointmentScreen> createState()=>_AppointmentScreenState();
}
class _AppointmentScreenState extends State<AppointmentScreen> {
  final _api=PatientApiService();
  String? _token,_error;
  List<Map<String,dynamic>> _appointments=[];
  bool _loading=false,_acting=false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token=context.watch<AuthViewModel>().currentUser?.token;
    if(_token!=token) { _token=token; _appointments=[]; _error=null; if(token!=null) _load(token); }
  }
  @override
  void didUpdateWidget(covariant AppointmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.refreshVersion!=widget.refreshVersion && _token!=null) _load(_token!);
  }
  Future<void> _load(String token) async {
    setState((){_loading=true;_error=null;});
    try { final data=await _api.getAppointments(token); if(!mounted || _token!=token)return;
      setState((){_appointments=data;_loading=false;});
    } catch(e){if(mounted && _token==token)setState((){_error='$e';_loading=false;});}
  }
  Future<void> _cancel(Map<String,dynamic> appointment) async {
    if(_acting || _token==null)return;
    final reason=TextEditingController();
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Hủy lịch hẹn?'),content:TextField(controller:reason,maxLength:500,decoration:const InputDecoration(labelText:'Lý do hủy (tùy chọn)')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Giữ lịch')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Hủy lịch'))]));
    final text=reason.text.trim();reason.dispose();
    if(confirmed!=true || !mounted || _token==null)return;
    final token=_token!;
    setState(()=>_acting=true);
    try { await _api.cancelAppointment(token:token,appointmentId:appointment['id'] as int,reason:text); if(!mounted || _token!=token)return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Đã hủy lịch hẹn.'))); await _load(token);
    } catch(e){if(mounted)setState(()=>_error='$e');} finally{if(mounted)setState(()=>_acting=false);}
  }
  Future<void> _reschedule(Map<String,dynamic> appointment) async {
    final changed=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>Scaffold(appBar:AppBar(title:const Text('Đổi lịch hẹn')),body:AppointmentBookingForm(appointment:appointment,onSaved:()=>Navigator.pop(context,true)))));
    if(changed==true && mounted && _token!=null)_load(_token!);
  }
  Widget _card(Map<String,dynamic> a) {
    final status=(a['trang_thai']??'').toString();
    final pending=['Chờ xác nhận','Chờ xét duyệt','Chờ duyệt','Chờ tiếp nhận','waiting'].contains(status);
    final confirmed=['Đã duyệt','Đã xác nhận','Đã tiếp nhận','Đang chờ khám'].contains(status);
    final rawTime = (a['gio_hen'] ?? '').toString();
    final time= rawTime.length < 5 ? null : DateTime.tryParse('${a['ngay_hen'].toString().split(' ').first} ${rawTime.substring(0,5)}');
    final future=time!=null && time.isAfter(DateTime.now());
    return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('${a['ma_lich_hen']??a['ma_hen']??''} • $status',style:const TextStyle(fontWeight:FontWeight.bold,color:AppColors.medical600)),
      const SizedBox(height:8),Text('${a['ten_khoa']??a['khoa']??a['ten_chuyen_khoa']??''}'),
      Text('Bác sĩ: ${a['bac_si']??a['ten_bac_si']??'Phòng khám phân công'}'),
      Text('Ngày: ${patientDate(a['ngay_hen'])} • ${a['gio_hen']??''}'),
      Text('Phòng: ${a['ten_phong']??a['phong']??'Tiếp đón phân bổ'}'),
      if(a['ly_do_kham']!=null)Text('Lý do: ${a['ly_do_kham']}'),
      if(a['ly_do_huy']!=null)Text('Lý do hủy: ${a['ly_do_huy']}'),
      if(confirmed)const Text('Lịch đã duyệt: không thể đổi lịch.',style:TextStyle(color:AppColors.slate500,fontSize:12)),
      if(future && (pending||confirmed))Wrap(spacing:8,children:[
        if(pending)TextButton.icon(onPressed:_acting?null:()=>_reschedule(a),icon:const Icon(Icons.edit_calendar),label:const Text('Đổi lịch')),
        TextButton.icon(onPressed:_acting?null:()=>_cancel(a),icon:const Icon(Icons.cancel_outlined),label:const Text('Hủy lịch')),
      ]),
    ])));
  }
  @override
  Widget build(BuildContext context) => DefaultTabController(length:2,initialIndex:widget.initialTab,child:Scaffold(backgroundColor:AppColors.slate50,
    appBar:AppBar(title:const Text('Đặt lịch khám bệnh'),bottom:const TabBar(tabs:[Tab(text:'Đặt lịch mới'),Tab(text:'Lịch hẹn của tôi')])),
    body:_token==null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Vui lòng đăng nhập để đặt và quản lý lịch hẹn.'),FilledButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AuthScreen())),child:const Text('Đăng nhập'))])):
      TabBarView(children:[AppointmentBookingForm(onSaved:()=>_load(_token!)),
        RefreshIndicator(onRefresh:()=>_load(_token!),child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(16),children:[
          if(_loading)const LinearProgressIndicator(),if(_error!=null)RequestError(message:_error!,onRetry:()=>_load(_token!)),
          if(!_loading && _error==null && _appointments.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('Bạn chưa có lịch hẹn nào.')),
          ..._appointments.map(_card),
        ])),
      ]),
  ));
}
