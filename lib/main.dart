import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'SearchPage.dart';

import 'API.dart' as API;
import 'Models/AirResponse.dart';

//主函数
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    debugPaintSizeEnabled = true;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      
      //设置主页面
      home: MainPage(),

      routes: <String, WidgetBuilder>{
        '/searchPage': (BuildContext context) => SearchPage(),
      },
    );
  }
}

//主页面 无状态widget
class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AQIView();
  }
}

//主页面 有状态widget
class AQIView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return AQIViewState();
  }
}

//主页面 有状态widget的state
class AQIViewState extends State<AQIView> {
// 缓存标识
  final String mAirResponse = "AirResponse";

  var aqi = 0;
  var place = "";

// 初始化
  @override
  void initState() {
    super.initState();

    getData();
  }

// 缓存数据到本地
  saveToLocal(AirResponse airResponse) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //model转json字符串
    String jsonStr = json.encode(airResponse);

    //字符串缓存在本地
    prefs.setString(mAirResponse, jsonStr);
  }

//获取本地缓存数据
  Future<AirResponse> getFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final jsonStr = prefs.getString(mAirResponse);
    if (jsonStr == null) {
      return null;
    } 
    //json转
    return AirResponse.fromJson(json.decode(jsonStr));

  }

  getData() {

    //先取缓存  // 异步执行--Future
    // Future 对象返回值表明当前时刻的计算结果可能还不可用，Future 实例会在计算结束后再返回结果
    Future localResponse = getFromLocal();

    // 通过 then() 方法注册一个回调函数在成功执行完成时调用，并获得返回值
    localResponse.then((airResponse) {

      if (airResponse != null) {

        //调用 setState() 来更新 UI，这会触发 widget 子树的重建，并更新相关数据
        setState(() {
          aqi = airResponse.data.aqi;
          place = airResponse.data.city.name;
        });
      }
    });

    //异步请求数据  
    Future response = API.getAirReprot();

    response.then((response) {
      final responseJson = json.decode(response.body);
      final airResponse = new AirResponse.fromJson(responseJson);

      //数据保存到本地
      saveToLocal(airResponse);

      //刷新界面  
      setState(() {
        aqi = airResponse.data.aqi;
        place = airResponse.data.city.name;
      });
    }).catchError((error) {
      print(error);
    }).whenComplete(() {});
  }

  Color _getColor(int aqi) {
    Color color = Color.fromARGB(255, 43, 153, 102);
    if (aqi > 300) {
      color = Color.fromARGB(255, 126, 2, 35);
    }else if (aqi > 201) {
      color = Color.fromARGB(255, 102, 0, 153);
    }else if (aqi > 150) {
      color = Color.fromARGB(255, 203, 5, 50);
    }else if (aqi > 100) {
      color = Color.fromARGB(255, 248, 153, 52);
    }else if (aqi > 50) {
      color = Color.fromARGB(255, 251, 222, 50);
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {

    // TODO: implement build
    return Scaffold(
        backgroundColor: _getColor(aqi),

        appBar: new AppBar(
          leading: new IconButton(
            icon: new Icon(Icons.menu),
            tooltip: 'Navigaton menu',
            onPressed: null,
          ),

        //导航栏标题
        title: new Text('Startup name generator'),

        //导航栏右按钮
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.list), 
            onPressed: null
          )
        ],

      ),

        body: Stack(
          alignment: const Alignment(0.0, 0.8),

          children: <Widget>[
            Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  place,
                  style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),

                Text(
                  aqi.toString(),
                  style: TextStyle(
                      fontSize: 100.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            )),

            IconButton(
              icon: Icon(Icons.location_on),
              onPressed: () {
                Future future = Navigator.of(context).pushNamed("/searchPage");
                future.then((value) {
                  API.setCityUid(value);
                  getData();
                });
              },
              iconSize: 50.0,
              color: Color.fromARGB(125, 255, 255, 255),
            )
          ],
        ));
  }
}
