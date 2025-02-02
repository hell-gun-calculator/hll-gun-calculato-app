import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import '/utils/index.dart';
import '/constants/app.dart';
import '/widgets/map_card.dart';
import '/data/index.dart';
import '/provider/map_provider.dart';

class MapPackagePage extends StatefulWidget {
  const MapPackagePage({super.key});

  @override
  State<MapPackagePage> createState() => _MapPackagePageState();
}

class _MapPackagePageState extends State<MapPackagePage> {
  late MapCompilation selectMapCompilation;

  I18nUtil i18nUtil = I18nUtil();

  bool updataLoad = false;

  /// 更新配置
  void _updataConfigDetail(MapCompilation i, modalSetState) async {
    modalSetState(() {
      updataLoad = true;
    });

    List requestList = [];
    for (var i in i.updataFunction) {
      Response result = await Http.request(
        i.path,
        method: Http.GET,
        httpDioType: HttpDioType.none,
      );
      requestList.add(jsonDecode(result.data));
    }

    modalSetState(() {
      MapCompilation newMapCompilation = MapCompilation.fromJson(requestList.first);
      newMapCompilation.type = MapCompilationType.Custom;
      App.provider.ofMap(context).updataCustomConfig(i.id, newMapCompilation);
      updataLoad = false;
    });
  }

  /// 查看配置详情
  void _openConfigDetail(MapCompilation i) {
    showModalBottomSheet<void>(
      context: context,
      clipBehavior: Clip.hardEdge,
      useRootNavigator: true,
      useSafeArea: true,
      scrollControlDisabledMaxHeightRatio: 1,
      builder: (context) {
        return StatefulBuilder(builder: (context, modalSetState) {
          return Scaffold(
            appBar: AppBar(
              leading: const CloseButton(),
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      App.provider.ofMap(context).deleteMapCompilation(i);
                    });
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            body: ListView(
              children: [
                ListTile(
                  title: Text(FlutterI18n.translate(context, "map.modalSheet.name")),
                  trailing: Text(i.name),
                ),
                ListTile(
                  title: Text(FlutterI18n.translate(context, "map.modalSheet.version")),
                  trailing: Text(i.version),
                ),
                ListTile(
                  title: Text(FlutterI18n.translate(context, "map.modalSheet.website")),
                  trailing: Text(i.website),
                ),
                ListTile(
                  title: Text(FlutterI18n.translate(context, "map.modalSheet.author")),
                  trailing: Text(i.author),
                ),
                if (i.type == MapCompilationType.Custom && i.updataFunction.isNotEmpty)
                  ListTile(
                    title: Text(FlutterI18n.translate(context, "map.modalSheet.updataFunctionTitle")),
                    subtitle: Text(FlutterI18n.translate(context, "map.modalSheet.updataFunctionTitleDescription")),
                    trailing: updataLoad ? const CircularProgressIndicator() : const Icon(Icons.chevron_right),
                    onTap: () => _updataConfigDetail(i, modalSetState),
                  ),
                const Divider(),
                ListTile(
                  title: Text(FlutterI18n.translate(context, "map.modalSheet.mapListTitle")),
                ),
                ...i.data.asMap().entries.map((e) {
                  return MapCardWidget(i: e.value);
                }).toList()
              ],
            ),
          );
        });
      },
    );
  }

  /// 删除配置
  void _deleteMapConfig() {
    App.provider.ofMap(context).deleteCustomMapCompilation();
  }

  @override
  void initState() {
    selectMapCompilation = App.provider.ofMap(context).currentMapCompilation;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapData, widget) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (mapData.currentMapCompilation.name != selectMapCompilation.name)
                IconButton(
                  onPressed: () {
                    App.provider.ofMap(context).currentMapCompilation = selectMapCompilation;
                  },
                  icon: const Icon(Icons.done),
                ),

              PopupMenuButton(
                icon: const Icon(Icons.more_horiz),
                itemBuilder: (itemBuilder) => <PopupMenuEntry>[
                  PopupMenuItem(
                    child: Wrap(
                      spacing: 5,
                      children: [
                        const Icon(Icons.delete),
                        Text(FlutterI18n.translate(context, "map.deleteConfiguration")),
                      ],
                    ),
                    onTap: () => _deleteMapConfig(),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            children: mapData.list.map((i) {
              return RadioListTile(
                value: i18nUtil.as(context, i.name),
                groupValue: selectMapCompilation.name,
                title: Text(i.name),
                subtitle: Text(i.author),
                onChanged: (String? value) {
                  setState(() {
                    selectMapCompilation = i;
                  });
                },
                secondary: Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (i.name == mapData.currentMapCompilationName)
                      ActionChip(
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        label: Text(FlutterI18n.translate(context, "calculatingFunction.currentUse")),
                      ),
                    IconButton(
                      onPressed: () => _openConfigDetail(i),
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
