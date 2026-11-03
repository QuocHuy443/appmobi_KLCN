import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobi/services/auth_service.dart';
import 'package:appmobi/services/patient_api_service.dart';
import 'package:appmobi/services/session_events.dart';
import 'package:appmobi/screens/main_navigation_screen.dart';
import 'package:appmobi/screens/personal_profile_screen.dart';
import 'auth_repository_contract_test.dart' show DeferredRepository, ContractAdapter;

class OnboardingApi extends PatientApiService {
  int completions=0;
  bool failSave=true;
  final patient=<String,dynamic>{'id':101,'ho_ten':'Nguyễn Văn An','sdt':'0912345678',
    'ngay_sinh':'1990-01-02','gioi_tinh':'Nam','nhom_mau':'Chưa rõ','profile_complete':false};
  @override
  Future<Map<String,dynamic>> getProfileBundle(String token) async => {'patient':Map<String,dynamic>.from(patient),'catalogs':{'nhom_mau':['Chưa rõ','A+']}};
  @override
  Future<Map<String,dynamic>> getProfile(String token) async => Map.from(patient);
  @override
  Future<void> completeProfile(String token,Map<String,dynamic> data) async {
    completions++;
    if(failSave)throw Exception('Mạng không ổn định');
    patient.addAll(data);patient['profile_complete']=true;
  }
}

Future<AuthViewModel> authenticated({bool complete=true}) async {
  final repository=DeferredRepository();
  final auth=AuthViewModel(authRepository:repository);
  final pending=auth.login('test','secret');
  repository.result.complete(User(id:'101',accountId:'11',name:'Nguyễn Văn An',email:'',phone:'0912345678',patientCode:'BN101',role:'BENHNHAN',token:'signed-test-token',profileComplete:complete));
  await pending;
  return auth;
}

void main(){
  test('401 from patient API immediately clears same session; stale errors do not clear new login',()async{
    final auth=await authenticated();
    addTearDown(auth.dispose);
    final adapter=ContractAdapter()..status=401..respond=(_)=>{'success':false,'error_code':'TOKEN_EXPIRED','message':'Expired'};
    final api=PatientApiService(dio:Dio(BaseOptions(baseUrl:'http://localhost'))..httpClientAdapter=adapter);
    await expectLater(api.getAppointments('signed-test-token'),throwsException);
    expect(auth.currentUser,isNull);
    expect(auth.errorMessage,contains('đăng nhập lại'));
    await auth.login('test','secret');
    SessionEvents.reject('old-token');
    expect(auth.currentUser,isNotNull);
    SessionEvents.reject('signed-test-token',profileRequired:true);
    expect(auth.currentUser!.profileComplete,isFalse);
  });

  testWidgets('incomplete profile blocks tabs; failed save keeps entered fields', (tester)async{
    final auth=await authenticated(complete:false);
    addTearDown(auth.dispose);
    final api=OnboardingApi();
    await tester.pumpWidget(ChangeNotifierProvider.value(value:auth,child:MaterialApp(home:MainNavigationScreen(apiService:api))));
    await tester.pumpAndSettle();
    expect(find.byType(CompleteProfileScreen),findsOneWidget);
    expect(find.byType(BottomNavigationBar),findsNothing);
    final name=find.widgetWithText(TextFormField,'Họ và tên');
    final nameController=tester.widget<TextFormField>(name).controller!;
    await tester.enterText(name,'Trần Thị Bình');
    final submit=find.widgetWithText(FilledButton,'Hoàn thiện hồ sơ');
    await tester.scrollUntilVisible(submit,400,scrollable:find.byType(Scrollable).first);await tester.tap(submit);await tester.pumpAndSettle();
    expect(api.completions,1);
    expect(find.textContaining('Mạng không ổn định'),findsOneWidget);
    expect(nameController.text,'Trần Thị Bình');
    api.failSave=false;
    await tester.scrollUntilVisible(submit,200,scrollable:find.byType(Scrollable).first);await tester.tap(submit);await tester.pump();await tester.pump(const Duration(milliseconds:100));
    expect(auth.currentUser!.profileComplete,isTrue);
    expect(auth.currentUser!.name,'Trần Thị Bình');
    expect(find.byType(BottomNavigationBar),findsOneWidget);
    await tester.pumpWidget(const SizedBox());await tester.pump();
  });
}
