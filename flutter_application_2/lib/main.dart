import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


late String? apikey;
void main() {

  runApp(const MyApp());

}


class MyApp extends StatelessWidget {
 const MyApp({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("login page built");
    }
    return MaterialApp(

      home: FutureBuilder<bool>(
        future: loggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While data is being fetched
            return const CircularProgressIndicator();
          } else if (snapshot.hasError || snapshot.data == false) {
            // If an error occurs during fetching or not logged in
            return const MyHomePage();
          } else {
            // Logged in
            return const Controls();
          }
        },
      ),
      routes: <String, WidgetBuilder>{
        '/Home': (context) => const MyHomePage(),
        '/Controls': (context) => const Controls(),
      },
    );
  }

  Future<bool> loggedIn() async {
    const storage = FlutterSecureStorage();
    String? isLoggedIn = await storage.read(key: "loggedIn");
    return isLoggedIn == "true";
  }
}


class MyHomePage extends StatefulWidget {
  //const MyHomePage({super.key});
const MyHomePage({Key? key}) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".



  @override
  State<MyHomePage> createState() => Home();
}



class Home extends State<MyHomePage> {

final storage = const FlutterSecureStorage();
TextEditingController clientIDController = TextEditingController();
TextEditingController clientSecreteController = TextEditingController();
TextEditingController deviceUIDController = TextEditingController();
TextEditingController projectUIDController = TextEditingController();
TextEditingController nameController = TextEditingController();

Color clientIDBorderColor = Colors.purple;
Color clientSecreteBorderColor = Colors.purple;
Color deviceUIDBorderColor= Colors.purple;
Color projectUIDBorderColor = Colors.purple;
Color nameBorderColor = Colors.purple;

   @override
   void dispose() {
     // Dispose the controllers when the widget is disposed
     
     clientIDController.dispose(); 
clientSecreteController.dispose();
deviceUIDController.dispose();
projectUIDController.dispose();
     super.dispose();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
        body: SingleChildScrollView(
    child: Column(
      children:[
         Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            obscureText: true,
            controller: clientIDController,
            decoration:  InputDecoration(
                  enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: clientIDBorderColor),
    ),
              focusedBorder: OutlineInputBorder(
                 borderSide: BorderSide(
                  color: clientIDBorderColor,
                  //color: Colors.black
                )
              ),
              labelText: 'ClientID',
              hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            ),
          ),
        ),
         Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            obscureText: true,
            controller: clientSecreteController,
            decoration:  InputDecoration(
              enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: clientSecreteBorderColor),
    ),
              focusedBorder: OutlineInputBorder(
                 borderSide: BorderSide(
                  color: clientSecreteBorderColor,
                  //color: Colors.black
                )
              ),
              // border: OutlineInputBorder(
                
              // ),
              labelText: 'Client Secrete', // Change this label to something different
              hintText: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
            ),
          ),
        ),

                 Padding(
                  
          padding: const EdgeInsets.all(10),
          child: TextField(
            obscureText: true,
            controller: deviceUIDController,
            decoration:  InputDecoration(
                            enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: deviceUIDBorderColor),
    ),
              focusedBorder: OutlineInputBorder(
                 borderSide: BorderSide(
                  color: deviceUIDBorderColor,
                  //color: Colors.black
                )
              ),
              labelText: 'Device UID', // Change this label to something different
              hintText: 'dev:xxxxxxxxxxxx',
            ),
          ),
        ),

                         Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            obscureText: true,
            controller: projectUIDController,
            decoration:  InputDecoration(
                           enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: projectUIDBorderColor),
    ),
              focusedBorder: OutlineInputBorder(
                 borderSide: BorderSide(
                  color: projectUIDBorderColor,
                  //color: Colors.black
                )
              ),
              labelText: 'Project UID', // Change this label to something different
              hintText: 'app:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
            ),
          ),
        ),

                                 Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: nameController,
            decoration:  InputDecoration(
                           enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: projectUIDBorderColor),
    ),
              focusedBorder: OutlineInputBorder(
                 borderSide: BorderSide(
                  color: projectUIDBorderColor,
                  //color: Colors.black
                )
              ),
              labelText: 'Name', // Change this label to something different
              hintText: 'Jane',
            ),
          ),
        ),
    
        Container(
          height: 50,
          width: 250,
          decoration: BoxDecoration(
              color: Colors.blue, borderRadius: BorderRadius.circular(20)),
          child: TextButton(
            onPressed: () {
validateInputAndLogin(clientIDController.text,
          clientSecreteController.text,
          deviceUIDController.text,
          projectUIDController.text,
          context
          );
             
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
          ),
        ),

        ]
    )
        )
    );
  }

void validateInputAndLogin(String clientID,String clientSecrete, String deviceUID, String projectUID, dynamic myContext) async{
  //input validation

setState(() {
  clientIDBorderColor= clientIDController.text.length < 36 ? Colors.red : Colors.purple;
  clientSecreteBorderColor= clientSecreteController.text.length < 64 ? Colors.red : Colors.purple;
  deviceUIDBorderColor= deviceUIDController.text.length < 16 ? Colors.red : Colors.purple;
  projectUIDBorderColor= projectUIDController.text.length < 40 ? Colors.red : Colors.purple;
  nameBorderColor= nameController.text.length < 3 ? Colors.red : Colors.purple;
});

  if (clientIDBorderColor != Colors.red &&
      clientSecreteBorderColor != Colors.red &&
      deviceUIDBorderColor != Colors.red &&
      projectUIDBorderColor != Colors.red &&
      nameBorderColor != Colors.red) {
    if (kDebugMode) {
      print('logged in');
    }
    await storage.write(key: "clientID", value: clientIDController.text);
    await storage.write(key: "clientSecrete", value: clientSecreteController.text);
    await storage.write(key: "deviceUID", value: deviceUIDController.text);
    await storage.write(key: "projectUID", value: projectUIDController.text);
    await storage.write(key: "loggedIn", value: "true"); // so next time no need to log in again
    await storage.write(key: "name", value: nameController.text); // so next time no need to log in again
    await getToken(); // wait for token to arrive before moving to next page
    if(apikey!=null){
    Navigator.pushNamed(myContext, '/Controls');
    }
  }

}
  

}

class Controls extends StatefulWidget {
 const Controls({Key? key}) : super(key: key);


    @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {

 late Timer _timer;

  @override
  void initState()  {
    super.initState();
        doorState("locked", true);
        log(true); //create note
    // this is just to create the note and it only works once
    // if the note exist the code above essentially has no effect.
    
    // Start a periodic timer
    _timer = Timer.periodic(const Duration(minutes: 25), (Timer timer) async {
      if (kDebugMode) {
        print("using timer");
      }
      await getToken();
    });
  }


@override
void dispose(){
    // Dispose of the timer when the State object is disposed
    _timer.cancel();
    super.dispose();
}
  @override
  Widget build(BuildContext context) {
    //     getToken();
    // print("request from build"); // delete later
    return Scaffold(
        appBar: AppBar(
        title: const Text("Controls"),
    centerTitle: true,
            actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Perform logout actions
             logoutAndNavigateToLogin(context);
             //print("logout");
            },
          ),
        ],
    ),
      body: Center(
      child: Container(
        height: 50,
        width: 250,
        decoration: BoxDecoration(
            color: Colors.blue, borderRadius: BorderRadius.circular(20)),
        child:TextButton(
          onPressed: () async {
            await doorState("unlocked",false);
            await log(false); // dont create note but log data
          
       

          },
          child: const Text(
            'Unlock',
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
        ),
      ),
      )
    );
  }
 
void logoutAndNavigateToLogin(dynamic myContext) async{
 const storage =  FlutterSecureStorage(); 
 await storage.write(key: "loggedIn", value: "false");
//Navigator.pushNamed(myContext,'/Home' );
Navigator.pop(myContext);
}
  
  Future<void> doorState(String doorstate, bool createNote) async {
    const storage = FlutterSecureStorage();
    String? deviceUID = await storage.read(key: "deviceUID");
String? projectUID= await storage.read(key: "projectUID");
  String file= "ds.dbs";
  String note= "doorState"; // the note is in the file ds.dbs
  final Uri url = Uri.parse('https://api.notefile.net/v1/projects/$projectUID/devices/$deviceUID/notes/$file/$note');
  final Map<String, String> headers = {
    'Authorization': 'Bearer $apikey',
    'Content-Type': 'application/json',
  };

  final Map<String, dynamic> requestBody = {
    'body': {'doorState': doorstate},
  };
late final http.Response response;
  try {
    if(createNote){
    response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    }
    else{
      response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    }
    if (response.statusCode == 200) {
      // Successful request, handle the response as needed
      if (kDebugMode) {
        print('HTTP request successful. Response: ${response.body}');
      }
    } else {
      // Handle unsuccessful request
      if (kDebugMode) {
        print('HTTP request failed with status code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Error response: ${response.body}');
      }
    }
  } catch (error) {
    // Handle any exceptions that may occur during the HTTP request
    if (kDebugMode) {
      print('Error during HTTP request: $error');
    }
  }


}

Future<void> log(bool createNote) async {
    const storage = FlutterSecureStorage();
    String? deviceUID = await storage.read(key: "deviceUID");
String? projectUID= await storage.read(key: "projectUID");
String? name= await storage.read(key: "name");

  final Uri url = Uri.parse('https://api.notefile.net/v1/projects/$projectUID/devices/$deviceUID/notes/door_log.dbs/doorLog');

  final Map<String, String> headers = {
    'Authorization': 'Bearer $apikey',
    'Content-Type': 'application/json',
  };

  final Map<String, dynamic> requestBody = {
    'body': {'$name': 'unlocked door from app'},
  };

late final http.Response response;
  try {
    if(createNote){
    response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    }
    else{
      response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );
    }
    if (response.statusCode == 200) {
      // Successful request, handle the response as needed
      if (kDebugMode) {
        print('HTTP request successful. Response: ${response.body}');
      }
    } else {
      // Handle unsuccessful request
      if (kDebugMode) {
        print('HTTP request failed with status code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Error response: ${response.body}');
      }
    }
  } catch (error) {
    // Handle any exceptions that may occur during the HTTP request
    if (kDebugMode) {
      print('Error during HTTP request: $error');
    }
  }
}
}







Future<void> getToken() async {
  // Create storage
const storage =  FlutterSecureStorage();
String? clientID = await storage.read(key: "clientID");
String? clientSecrete = await storage.read(key: "clientSecrete");

    if (kDebugMode) {
      print("making requests");
    }
    final url = Uri.parse('https://notehub.io/oauth2/token');

    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final Map<String, String?> body = {
      'grant_type': 'client_credentials',
      'client_id': clientID,
      'client_secret': clientSecrete,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );
final Map<String, dynamic> parsedJson = jsonDecode(response.body);

  // Get the access_token
  final String? accessToken = parsedJson['access_token'];

  // Print or use the access_token as needed
  apikey= accessToken;
  if (kDebugMode) {
    print('Access Token: $apikey');
  }
  
  }


// when you are done with this project add some extras