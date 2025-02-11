import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gopeed/api/model/resolve_result.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

import '../../../../api/api.dart';
import '../../../../api/model/create_task.dart';
import '../../../../api/model/options.dart';
import '../../../../api/model/request.dart';
import '../../../../util/util.dart';
import '../../../routes/app_pages.dart';
import '../../../views/views/directory_selector.dart';
import '../../../views/views/file_list_view.dart';
import '../../app/controllers/app_controller.dart';
import '../controllers/create_controller.dart';

class CreateView extends GetView<CreateController> {
  final _resolveFormKey = GlobalKey<FormState>();

  final _urlController = TextEditingController();
  final _confirmController = RoundedLoadingButtonController();

  CreateView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.rootDelegate.offNamed(Routes.DOWNLOADING)),
        // actions: [],
        title: Text('create'.tr),
      ),
      body: DropTarget(
        onDragDone: (details) {
          _urlController.text = details.files[0].path;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Form(
            key: _resolveFormKey,
            autovalidateMode: AutovalidateMode.always,
            child: Column(
              children: [
                TextFormField(
                    autofocus: true,
                    controller: _urlController,
                    minLines: 1,
                    maxLines: 30,
                    decoration: InputDecoration(
                        hintText: _hitText(),
                        hintStyle: const TextStyle(fontSize: 12),
                        labelText: 'downloadLink'.tr,
                        icon: const Icon(Icons.link)),
                    validator: (v) {
                      return v!.trim().isNotEmpty
                          ? null
                          : 'downloadLinkValid'.tr;
                    }),
                Center(
                  child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints.tightFor(
                          width: 150,
                          height: 40,
                        ),
                        child: RoundedLoadingButton(
                          color: Get.theme.colorScheme.secondary,
                          onPressed: () async {
                            try {
                              _confirmController.start();
                              if (_resolveFormKey.currentState!.validate()) {
                                final rr = await resolve(Request(
                                  url: _urlController.text,
                                ));
                                await _showResolveDialog(rr);
                              }
                            } catch (e) {
                              Get.snackbar('error'.tr, e.toString());
                            } finally {
                              _confirmController.reset();
                            }
                          },
                          controller: _confirmController,
                          child: Text('confirm'.tr),
                        ),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _hitText() {
    return 'downloadLinkHit'.trParams({
      'append': Util.isDesktop() ? 'downloadLinkHitDesktop'.tr : '',
    });
  }

  Future<void> _showResolveDialog(ResolveResult rr) async {
    final files = rr.res.files;
    final appController = Get.find<AppController>();

    final createFormKey = GlobalKey<FormState>();
    final pathController = TextEditingController(
        text: appController.downloaderConfig.value.downloadDir);
    final downloadController = RoundedLoadingButtonController();
    return showDialog<void>(
        context: Get.context!,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              content: Builder(
                builder: (context) {
                  // Get available height and width of the build area of this widget. Make a choice depending on the size.
                  var height = MediaQuery.of(context).size.height;
                  var width = MediaQuery.of(context).size.width;

                  return SizedBox(
                    height: height * 0.5,
                    width: width,
                    child: Form(
                        key: createFormKey,
                        autovalidateMode: AutovalidateMode.always,
                        child: Column(
                          children: [
                            Expanded(child: FileListView(files: files)),
                            DirectorySelector(
                              controller: pathController,
                            ),
                          ],
                        )),
                  );
                },
              ),
              actions: [
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                    width: Get.theme.buttonTheme.minWidth,
                    height: Get.theme.buttonTheme.height,
                  ),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(shape: const StadiumBorder())
                            .copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                    Get.theme.colorScheme.background)),
                    onPressed: () {
                      Get.back();
                    },
                    child: Text('cancel'.tr),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                    width: Get.theme.buttonTheme.minWidth,
                    height: Get.theme.buttonTheme.height,
                  ),
                  child: RoundedLoadingButton(
                      color: Get.theme.colorScheme.secondary,
                      onPressed: () async {
                        try {
                          downloadController.start();
                          if (controller.selectedIndexes.isEmpty) {
                            Get.snackbar('tip'.tr, 'noFileSelected'.tr);
                            return;
                          }
                          if (createFormKey.currentState!.validate()) {
                            // if (Util.isAndroid()) {
                            //   if (!await Permission.storage.request().isGranted) {
                            //     Get.snackbar('error'.tr,
                            //         'noStoragePermission'.tr);
                            //     return;
                            //   }
                            // }
                            await createTask(CreateTask(
                                rid: rr.id,
                                opts: Options(
                                    name: '',
                                    path: pathController.text,
                                    selectFiles: controller.selectedIndexes
                                        .cast<int>())));
                            Get.back();
                            Get.rootDelegate.offNamed(Routes.DOWNLOADING);
                          }
                        } catch (e) {
                          Get.snackbar('error'.tr, e.toString());
                          rethrow;
                        } finally {
                          downloadController.reset();
                        }
                      },
                      controller: downloadController,
                      child: Text(
                        'download'.tr,
                        // style: controller.selectedIndexes.isEmpty
                        //     ? Get.textTheme.disabled
                        //     : Get.textTheme.titleSmall
                      )),
                ),
              ],
            ));
  }
}
