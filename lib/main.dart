import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(
      ),
      home: WillPopScope(
        onWillPop: () async {
          print("tried to close");
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
          ),
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MySearchBar()
          )
        )
      )
    );
  }
}

class MySearchBar extends StatefulWidget{
  @override
  State<MySearchBar> createState() => _MySearchBarState();
}

class _MySearchBarState extends State<MySearchBar> {
  final runFieldController = TextEditingController();
  final scratchFieldController = TextEditingController();

  final runFieldFocus = FocusNode();
  final scratchFieldFocus = FocusNode();
  
  List<Application> apps = [];

  void getAppsList() async {
    apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: false
    );
    
    setState((){
        apps.sort((a,b) => a.appName.compareTo(b.appName));
    });
  }

  void resetRunField(){
    runFieldController.clear();
    setState((){
        apps.sort((a,b) => a.appName.compareTo(b.appName));
    });
  }
  
  void filterCandidates(String input){
    if(apps.length == 0) { return; }

    var j = 0;
    var temp = apps[0];

    if(input.length > 0 && input[0] == '!'){
      input = input.substring(1);
    }
    
    for(int i = 0; i < apps.length; i++){
      if(apps[i].appName.toLowerCase().startsWith(input)){
        temp = apps[i];
        apps[i] = apps[j];
        apps[j] = temp;
        j = j + 1;
      }
    }

    setState((){});
  }

  void runAppUsingPackageName(String packageName){
    if(apps.length == 0) { return; }
    
    if(runFieldController.text.length > 0 && runFieldController.text[0] == '!'){
      DeviceApps.openAppSettings(packageName);
      resetRunField();
      return;
    }

    DeviceApps.openApp(packageName);
    resetRunField();
  }
  
  void runClosestCandidate(String input){
    if(apps.length == 0) { return; }

    if(input.length > 0 && input[0] == '!'){
      DeviceApps.openAppSettings(apps.first.packageName);
    }else{
      DeviceApps.openApp(apps.first.packageName);
    }

    resetRunField();
  }

  @override
  void initState() {
    super.initState();
    getAppsList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(height: 10),

        OutlinedButton(
          onPressed: () => scratchFieldFocus.requestFocus(),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(child: Text("edit"))
          )
        ),
        
        Expanded(child: TextField(
            focusNode: scratchFieldFocus,
            controller: scratchFieldController,
            maxLines: 99999,
            onTap: () {
              scratchFieldFocus.unfocus();
              runFieldFocus.requestFocus();
            },
        )),

        SizedBox(height: 10),
        
        SizedBox(
          width: (apps.length == 0) ? 48 : MediaQuery.of(context).size.width,
          height: 48,
          child: (apps.length == 0) ? CircularProgressIndicator() : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: apps.length,
            itemBuilder: (BuildContext context, int index) {
              
              return Container(
                margin: EdgeInsets.all(2.5),
                padding: EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  border: Border.all(color: (index == 0) ? Colors.red : Colors.grey ),
                  borderRadius: BorderRadius.circular(5)
                ),
                
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  direction: Axis.vertical,
                  children: <Widget>[

                    IconButton(
                      onPressed: () => runAppUsingPackageName(apps[index].packageName),
                      icon: Image.memory(
                        (apps[index] as ApplicationWithIcon).icon,
                        width: 50.0,
                        height: 50.0
                      )
                    ),
                    
                    TextButton(
                      child: Text('${apps[index].appName}'),
                      onPressed: () => runAppUsingPackageName(apps[index].packageName),
                    )
                  ]
                )
              );
              
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
          )
        ),

        SizedBox(height: 10),
        
        TextField(
          autofocus: true,
          controller: runFieldController,
          focusNode: runFieldFocus,
          
          decoration: InputDecoration(
            labelText: 'run app',
            border: OutlineInputBorder()
          ),
          
          onChanged: filterCandidates,
          onSubmitted: runClosestCandidate
        ),
        
      ]
    );
  }
}
