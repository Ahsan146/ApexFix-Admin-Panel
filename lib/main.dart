import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

const navy = Color.fromARGB(255, 21, 19, 50);
const yellow = Color(0xFFFFC928);
const bg = Color(0xFFF6F7FB);

const navyGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color.fromARGB(255, 29, 26, 74),
    Color.fromARGB(255, 21, 19, 50),
  ],
);
const line=Color(0xFFE7E9EF), muted=Color(0xFF737A8A), purple=Color(0xFF6658D3);
const green=Color(0xFF2E9D6F), red=Color(0xFFD95C5C), blue=Color(0xFF4285F4);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}
class App extends StatelessWidget {
  const App({super.key});
  @override Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'ApexFix Admin',
    theme:ThemeData(useMaterial3:true, scaffoldBackgroundColor:bg,
      colorScheme:ColorScheme.fromSeed(seedColor:purple),
      textTheme:GoogleFonts.robotoTextTheme().apply(bodyColor:navy,displayColor:navy),
      cardTheme:CardThemeData(color:Colors.white,elevation:0,margin:EdgeInsets.zero,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:const BorderSide(color:line)))),
    home:const AuthGate());
}
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext c) => StreamBuilder<User?>(
    stream:FirebaseAuth.instance.authStateChanges(),
    builder:(c,s) {
      if(s.connectionState==ConnectionState.waiting) return const Scaffold(body:Center(child:CircularProgressIndicator()));
      return s.data==null ? const Login() : const AdminGate();
    });
}
class AdminGate extends StatefulWidget { const AdminGate({super.key}); @override State<AdminGate> createState()=>_AdminGateState(); }
class _AdminGateState extends State<AdminGate> {
  bool? allowed;
  @override void initState(){super.initState();verify();}
  Future<void> verify() async {
    try {
      final token=await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);
      final ok=token.claims?['admin']==true;
      if(!ok) await FirebaseAuth.instance.signOut();
      if(mounted) setState(()=>allowed=ok);
    } catch(_) { await FirebaseAuth.instance.signOut(); if(mounted)setState(()=>allowed=false); }
  }
  @override Widget build(BuildContext c)=>allowed==null?const Scaffold(body:Center(child:CircularProgressIndicator())):allowed!?const Shell():const Login(error:'This account is not an ApexFix administrator.');
}
class Login extends StatefulWidget {
  final String? error; const Login({super.key,this.error});
  @override State<Login> createState()=>_LoginState();
}
class _LoginState extends State<Login> {
  final email=TextEditingController(), pass=TextEditingController();
  String? error; bool busy=false;
  @override void initState(){super.initState();error=widget.error;}
  Future<void> signIn() async {
    if(email.text.trim().isEmpty||pass.text.isEmpty){setState(()=>error='Enter your email and password.');return;}
    setState(()=>busy=true);
    try { await FirebaseAuth.instance.signInWithEmailAndPassword(email:email.text.trim(),password:pass.text); }
    on FirebaseAuthException catch(e){setState((){error=e.message??'Sign in failed.';busy=false;});}
  }
  @override Widget build(BuildContext c)=>Scaffold(
    body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Padding(
      padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Logo(),const SizedBox(height:48),
        const Text('Welcome back',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900)),
        const SizedBox(height:7),const Text('Sign in to manage ApexFix operations.',style:TextStyle(color:muted)),
        const SizedBox(height:26),
        TextField(controller:email,decoration:const InputDecoration(labelText:'Admin email',prefixIcon:Icon(Icons.mail_outline))),
        const SizedBox(height:14),
        TextField(controller:pass,obscureText:true,onSubmitted:(_)=>signIn(),decoration:const InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock_outline))),
        if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:const TextStyle(color:red,fontSize:13))),
        const SizedBox(height:22),
        SizedBox(width:double.infinity,height:52,child:FilledButton(
          onPressed:busy?null:signIn,style:FilledButton.styleFrom(backgroundColor:navy),
          child:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Sign in'))),
        const SizedBox(height:15),const Text('Admin access requires the Firebase custom claim admin=true.',style:TextStyle(color:muted,fontSize:12))
      ])))));
}
class Logo extends StatelessWidget {
  final bool dark; const Logo({super.key,this.dark=false});
  @override Widget build(BuildContext c)=>RichText(text:TextSpan(style:GoogleFonts.roboto(fontSize:27,fontWeight:FontWeight.w900),
    children:[TextSpan(text:'Apex',style:TextStyle(color:dark?Colors.white:navy)),const TextSpan(text:'Fix',style:TextStyle(color:yellow))]));
}

enum Section { dashboard,customers,technicians,bookings,services,reports,settings }
class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState()=>_ShellState(); }
class _ShellState extends State<Shell> {
  Section section=Section.dashboard;
  String get title=>switch(section){Section.dashboard=>'Dashboard',Section.customers=>'Customers',Section.technicians=>'Technicians',Section.bookings=>'Bookings',Section.services=>'Services',Section.reports=>'Reports',Section.settings=>'Settings'};
  Widget page()=>switch(section){
    Section.dashboard=>const Dashboard(),
    Section.customers=>const Records('customers',['Name','Email','Phone','Role']),
    Section.technicians=>const Records('technicians',['Technician','Email','Specialties','Rating']),
    Section.bookings=>const Bookings(),
    Section.services=>const Records('services',['Service','Category','Base price','Duration']),
    Section.reports=>const Reports(),
    Section.settings=>const Settings()};
  @override Widget build(BuildContext c){
    final desktop=MediaQuery.sizeOf(c).width>=950;
    final side=Sidebar(section,(x){setState(()=>section=x);if(!desktop)Navigator.pop(c);});
    return Scaffold(drawer:desktop?null:Drawer(child:side),body:Row(children:[
      if(desktop)side,Expanded(child:Column(children:[
        Container(height:70,padding:const EdgeInsets.symmetric(horizontal:25),decoration:const BoxDecoration(color:Colors.white,border:Border(bottom:BorderSide(color:line))),
          child:Row(children:[
            if(!desktop)Builder(builder:(x)=>IconButton(onPressed:()=>Scaffold.of(x).openDrawer(),icon:const Icon(Icons.menu))),
            Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const Spacer(),
            CircleAvatar(backgroundColor:navy,child:Text((FirebaseAuth.instance.currentUser?.email??'A')[0].toUpperCase(),style:const TextStyle(color:yellow,fontWeight:FontWeight.w800)))
          ])),
        Expanded(child:page())
      ]))
    ]));
  }
}
class Sidebar extends StatelessWidget {
  final Section selected; final ValueChanged<Section> onTap;
  const Sidebar(this.selected,this.onTap,{super.key});
  Widget item(Section s,IconData icon,String label)=>ListTile(
    dense:true,selected:selected==s,selectedTileColor:yellow.withValues(alpha:.16),
    leading:Icon(icon,color:selected==s? yellow:Colors.white54),
    title:Text(label,style:TextStyle(color:selected==s? yellow:Colors.white70,fontWeight:selected==s?FontWeight.w800:FontWeight.w500)),
    onTap:()=>onTap(s));
  @override Widget build(BuildContext c)=>Container(width:240,color:navy,child:Column(children:[
    const SizedBox(height:28),const Padding(padding:EdgeInsets.symmetric(horizontal:25),child:Logo(dark:true)),const SizedBox(height:15),
    Expanded(child:ListView(padding:const EdgeInsets.all(12),children:[
      item(Section.dashboard,Icons.space_dashboard_outlined,'Dashboard'),
      item(Section.customers,Icons.people_outline,'Customers'),
      item(Section.technicians,Icons.engineering_outlined,'Technicians'),
      item(Section.bookings,Icons.calendar_month_outlined,'Bookings'),
      item(Section.services,Icons.handyman_outlined,'Services'),
      item(Section.reports,Icons.bar_chart_rounded,'Reports'),
      item(Section.settings,Icons.settings_outlined,'Settings')
    ])),
    const Padding(padding:EdgeInsets.all(18),child:Text('ADMIN WORKSPACE',style:TextStyle(color:yellow,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.3)))
  ]));
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  Future<List<QuerySnapshot<Map<String,dynamic>>>> load()=>Future.wait(
    ['bookings','customers','technicians','services','categories'].map((x)=>FirebaseFirestore.instance.collection(x).get()));
  @override Widget build(BuildContext c)=>FutureBuilder<List<QuerySnapshot<Map<String,dynamic>>>>(
    future:load(),builder:(c,s){
      if(s.connectionState==ConnectionState.waiting)return const Loading();
      if(s.hasError)return ErrorBox(s.error.toString());
      final bookings=s.data![0].docs,customers=s.data![1].docs,techs=s.data![2].docs,services=s.data![3].docs,cats=s.data![4].docs;
      final revenue=bookings.fold<double>(0,(a,d)=>a+numVal(d.data()['serviceCharge']?['total']));
      final done=bookings.where((d)=>d.data()['status']=='completed').length;
      final active=bookings.where((d)=>['accepted','onTheWay','arrived','inProgress','workInProgress'].contains(d.data()['status'])).length;
      return ListView(padding:const EdgeInsets.all(28),children:[
        const Intro('Good to see you.','Here is what is happening across ApexFix today.'),
        const SizedBox(height:20),
        Wrap(spacing:16,runSpacing:16,children:[
          Metric('Bookings',bookings.length.toString(),active.toString()+' active',Icons.calendar_month_outlined,purple),
          Metric('Customers',customers.length.toString(),'Registered',Icons.people_outline,blue),
          Metric('Technicians',techs.length.toString(),'Directory',Icons.engineering_outlined,green),
          Metric('Revenue','PKR '+compact(revenue),done.toString()+' completed',Icons.payments_outlined,yellow)]),
        const SizedBox(height:18),
        Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Recent bookings',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          ...bookings.take(6).map((d){final x=d.data();return ListTile(contentPadding:EdgeInsets.zero,
            leading:const CircleAvatar(backgroundColor:Color(0x116658D3),child:Icon(Icons.build_outlined,color:purple)),
            title:Text(x['bookingNumber']??d.id,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),
            subtitle:Text(x['serviceName']??'Service',style:const TextStyle(color:muted,fontSize:11)),
            trailing:Pill(x['status']?.toString()??'pending'));})
        ]))),
        const SizedBox(height:18),
        Row(children:[Expanded(child:Mini(Icons.category_outlined,'Categories',cats.length.toString())),const SizedBox(width:16),Expanded(child:Mini(Icons.handyman_outlined,'Services',services.length.toString()))])
      ]);
    });
}
class Intro extends StatelessWidget { final String a,b; const Intro(this.a,this.b,{super.key}); @override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(b,style:const TextStyle(color:muted))]); }
class Metric extends StatelessWidget {
  final String label,value,foot; final IconData icon; final Color color;
  const Metric(this.label,this.value,this.foot,this.icon,this.color,{super.key});
  @override Widget build(BuildContext c)=>SizedBox(width:240,height:125,child:Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Icon(icon,color:color),const Spacer(),Text(value,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:muted,fontSize:11)),Text(foot,style:const TextStyle(color:muted,fontSize:10))
  ]))));
}
class Mini extends StatelessWidget { final IconData icon; final String label,value; const Mini(this.icon,this.label,this.value,{super.key}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[Icon(icon,color:purple),const SizedBox(width:12),Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w800))),Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900))]))); }

class Records extends StatelessWidget {
  final String collection; final List<String> columns;
  const Records(this.collection,this.columns,{super.key});
  List<dynamic> row(Map<String,dynamic>x,String id){
    if(collection=='customers')return[x['fullName']??id,x['email']??'—',x['phoneNumber']??'—',x['role']??'customer'];
    if(collection=='technicians')return[x['fullName']??id,x['email']??'—',(x['specialties'] as List?)?.join(', ')??'—',numVal(x['rating']).toStringAsFixed(1)+' / 5'];
    return[x['title']??id,x['categoryId']??'—','PKR '+money(numVal(x['basePrice'])),(x['durationMinutes']??'—').toString()+' min'];
  }
  @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Intro(pretty(collection),'Live Firestore records.'),const SizedBox(height:18),
    Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection(collection).snapshots(),builder:(c,s){
      if(s.connectionState==ConnectionState.waiting)return const Loading();if(s.hasError)return ErrorBox(s.error.toString());
      final docs=s.data!.docs;if(docs.isEmpty)return const Empty('No records found.');
      return Card(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
        columns:columns.map((x)=>DataColumn(label:Text(x,style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w800)))).toList(),
        rows:docs.map((d)=>DataRow(cells:row(d.data(),d.id).map((v)=>DataCell(Text(v.toString(),style:const TextStyle(fontSize:12)))).toList())).toList())));
    }))
  ]));
}
class Bookings extends StatefulWidget { const Bookings({super.key}); @override State<Bookings>createState()=>_BookingsState(); }
class _BookingsState extends State<Bookings>{
  String filter='all';
  Future<void>complete(String id)async=>FirebaseFirestore.instance.collection('bookings').doc(id).update({'status':'completed','updatedAt':DateTime.now().toIso8601String(),'estimatedArrivalMinutes':0});
  @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Intro('Bookings','Monitor jobs and update operational status.'),const SizedBox(height:14),
    Wrap(spacing:7,children:['all','searchingTechnician','accepted','onTheWay','completed'].map((x)=>ChoiceChip(label:Text(pretty(x)),selected:filter==x,onSelected:(_)=>setState(()=>filter=x))).toList()),
    const SizedBox(height:14),
    Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('bookings').snapshots(),builder:(c,s){
      if(s.connectionState==ConnectionState.waiting)return const Loading();if(s.hasError)return ErrorBox(s.error.toString());
      var docs=s.data!.docs;if(filter!='all')docs=docs.where((d)=>d.data()['status']==filter).toList();
      if(docs.isEmpty)return const Empty('No bookings match this filter.');
      return Card(child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
        columns:const['Booking','Customer','Service','Status','Amount','Action'].map((x)=>DataColumn(label:Text(x,style:const TextStyle(color:muted,fontSize:11)))).toList(),
        rows:docs.map((d){final x=d.data(),status=x['status']?.toString()??'pending';return DataRow(cells:[
          DataCell(Text(x['bookingNumber']??d.id)),DataCell(Text(x['customerId']??'—')),DataCell(Text(x['serviceName']??'—')),DataCell(Pill(status)),
          DataCell(Text('PKR '+money(numVal(x['serviceCharge']?['total'])))),
          DataCell(status=='completed'?const Text('Done',style:TextStyle(color:muted)):TextButton(onPressed:()=>complete(d.id),child:const Text('Complete')))
        ]);}).toList())));
    }))
  ]));
}
class Reports extends StatelessWidget { const Reports({super.key}); @override Widget build(BuildContext c)=>FutureBuilder<QuerySnapshot<Map<String,dynamic>>>(
  future:FirebaseFirestore.instance.collection('bookings').get(),builder:(c,s){
    if(s.connectionState==ConnectionState.waiting)return const Loading();if(s.hasError)return ErrorBox(s.error.toString());
    final docs=s.data!.docs,revenue=docs.fold<double>(0,(a,d)=>a+numVal(d.data()['serviceCharge']?['total'])),done=docs.where((d)=>d.data()['status']=='completed').length;
    final rate=docs.isEmpty?0:((done/docs.length)*100).round();
    return ListView(padding:const EdgeInsets.all(28),children:[const Intro('Reports','Operational summaries from live booking data.'),const SizedBox(height:20),
      Wrap(spacing:16,runSpacing:16,children:[
        Metric('Gross value','PKR '+compact(revenue),'All bookings',Icons.payments_outlined,yellow),
        Metric('Completion rate',rate.toString()+'%',done.toString()+' completed',Icons.task_alt_rounded,green),
        Metric('Average booking','PKR '+compact(docs.isEmpty?0:revenue/docs.length),docs.length.toString()+' bookings',Icons.analytics_outlined,purple)
      ])]);
  });
}
class Settings extends StatelessWidget { const Settings({super.key}); @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(28),children:[
  const Intro('Settings','Admin account and security.'),const SizedBox(height:20),
  Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('Administrator account',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),
    const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:navy,child:Icon(Icons.person_outline,color:yellow)),title:Text('Firebase administrator'),subtitle:Text('Admin claim verified at sign-in')),
    OutlinedButton.icon(onPressed:()=>FirebaseAuth.instance.signOut(),icon:const Icon(Icons.logout),label:const Text('Sign out'))
  ]))),
  const SizedBox(height:16),
  const Card(child:Padding(padding:EdgeInsets.all(24),child:Text('Security is enforced by admin=true custom claims and Firestore Security Rules. Never add a service-account private key to this web app.',style:TextStyle(color:muted,height:1.5))))
]);}
class Pill extends StatelessWidget { final String status; const Pill(this.status,{super.key}); @override Widget build(BuildContext c){final color=statusColor(status);return Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:color.withValues(alpha:.1),borderRadius:BorderRadius.circular(99)),child:Text(pretty(status),style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w800)));}}
class Loading extends StatelessWidget { const Loading({super.key}); @override Widget build(BuildContext c)=>const Center(child:CircularProgressIndicator()); }
class Empty extends StatelessWidget { final String text; const Empty(this.text,{super.key}); @override Widget build(BuildContext c)=>Center(child:Text(text,style:const TextStyle(color:muted))); }
class ErrorBox extends StatelessWidget { final String text; const ErrorBox(this.text,{super.key}); @override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Text(text,textAlign:TextAlign.center,style:const TextStyle(color:muted)))); }

double numVal(dynamic x)=>x is num?x.toDouble():double.tryParse(x.toString())??0;
String money(double x)=>x.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'),(m)=>m[1]!+',');
String compact(double x)=>x>=1000000?(x/1000000).toStringAsFixed(1)+'M':x>=1000?(x/1000).toStringAsFixed(x>=10000?0:1)+'K':x.round().toString();
String pretty(String x)=>x.replaceAllMapped(RegExp(r'([A-Z])'),(m)=>' '+m[1]!).replaceFirst(x.isEmpty?'':x[0],x.isEmpty?'':x[0].toUpperCase()).trim();
Color statusColor(String x){if(x=='completed')return green;if(['cancelled','rejected','disputed'].contains(x))return red;if(x=='searchingTechnician')return const Color(0xFFB87900);if(['accepted','onTheWay','arrived','inProgress','workInProgress'].contains(x))return blue;return muted;}
