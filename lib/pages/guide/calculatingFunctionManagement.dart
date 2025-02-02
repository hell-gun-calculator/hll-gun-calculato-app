import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '/constants/api.dart';
import '/provider/calc_provider.dart';
import '/constants/app.dart';
import '/data/index.dart';
import '/utils/index.dart';

class GuideCalculatingFunctionManagement extends StatefulWidget {
  const GuideCalculatingFunctionManagement({super.key});

  @override
  State<GuideCalculatingFunctionManagement> createState() => _GuideCalculatingFunctionManagementState();
}

class _GuideCalculatingFunctionManagementState extends State<GuideCalculatingFunctionManagement> with AutomaticKeepAliveClientMixin {
  Storage storage = Storage();

  bool load = false;

  late GuideRecommendedCalcFunction guideRecommendedCalcFunction = GuideRecommendedCalcFunction();

  @override
  void initState() {
    _getRecommendedList();
    super.initState();
  }

  /// 获取推荐列表
  void _getRecommendedList() async {
    GuideRecommendedCalcFunction;

    if (!mounted) return;
    setState(() {
      load = true;
    });

    Map<String, dynamic> result = await Http.fetchJsonpData(
      "config/calcFunction/recommendeds.json",
      httpDioValue: "app_web_site",
    );

    if (result.toString().isNotEmpty) {
      guideRecommendedCalcFunction = GuideRecommendedCalcFunction.fromJson(result);
    }

    setState(() {
      load = false;
    });
  }

  /// 下载配置
  Future<CalculatingFunction> _downloadConfig(GuideRecommendedBaseItem guideRecommendedBaseItem) async {
    List requestList = [];

    setState(() {
      guideRecommendedBaseItem.load = true;
    });

    for (var i in guideRecommendedBaseItem.updataFunction) {
      Map<String, dynamic> result = await Http.fetchJsonpData(i.path, httpDioType: HttpDioType.none);
      if (result.toString().isNotEmpty) {
        requestList.add(result);
      }
    }

    // 下载失败或无
    if (requestList.isEmpty) return CalculatingFunction.empty();

    CalculatingFunction newCalculatingFunction = CalculatingFunction.fromJson(requestList.first);
    newCalculatingFunction.type = CalculatingFunctionType.Custom;
    App.provider.ofCalc(context).addCustomConfig(title: newCalculatingFunction.name, data: jsonEncode(newCalculatingFunction));

    setState(() {
      guideRecommendedBaseItem.load = false;
    });

    return newCalculatingFunction;
  }

  /// 下载并使用
  void _downloadAndUse(GuideRecommendedBaseItem guideRecommendedBaseItem) async {
    CalculatingFunction newCalculatingFunction = await _downloadConfig(guideRecommendedBaseItem);
    App.provider.ofCalc(context).currentCalculatingFunctionName = newCalculatingFunction.name;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Consumer<CalcProvider>(builder: (context, calcData, widget) {
      return ListView(
        children: [
          const ListTile(
            title: Text(
              "计算函数",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            subtitle: Text("它是计算器的核心，负责对输入值比对各项参数最后求结果，同时你可以随时改用其他‘计算函数’，在内部提供阵营公式、变量、角度;如果允许你可以在应用内更新‘计算函数’."),
          ),
          ListTile(
            title: Text(calcData.currentCalculatingFunctionName),
            subtitle: const Text("当前选择"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              App.url.opEnPage(context, "/calculatingFunctionConfig");
            },
          ),
          const Divider(),
          ListTile(
            leading: RawChip(
              label: const Text("推荐"),
              color: MaterialStatePropertyAll(Theme.of(context).colorScheme.primary.withOpacity(.2)),
            ),
            title: const Text("来自第三方"),
            subtitle: const Text("我们陈列出一些社区提供’计算函数‘选择"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              App.url.onPeUrl("${Config.apis["app_web_site"]!.url}/docs/calc/calcRecommendedList.html");
            },
          ),
          if (load)
            Center(
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 50),
                child: const CircularProgressIndicator(),
              ),
            ),
          ...guideRecommendedCalcFunction.child.map((e) {
            return ListTile(
              title: Text(e.name),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (e.load)
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else if (!e.load && calcData.calcList.where((i) => i.name == e.name).isEmpty)
                    IconButton(
                      onPressed: () => _downloadConfig(e),
                      icon: const Icon(Icons.downloading),
                    )
                  else if (!e.load && calcData.calcList.where((i) => i.name == e.name).isNotEmpty)
                    const IconButton(
                      onPressed: null,
                      icon: Icon(Icons.done),
                    ),
                  if (!e.load && calcData.calcList.where((i) => i.name == e.name).isEmpty)
                    TextButton.icon(
                      onPressed: () => _downloadAndUse(e),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("添加并作为默认"),
                    )
                ],
              ),
            );
          })
        ],
      );
    });
  }
}
