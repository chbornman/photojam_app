import 'package:flutter/material.dart';
import 'package:photojam_app/features/photos/controllers/photos_controller.dart';
import 'package:photojam_app/features/photos/widgets/submission_list.dart';
import 'package:provider/provider.dart';

class PhotosContent extends StatelessWidget {
  const PhotosContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hi'),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final controller = context.watch<PhotosController>();

  //   return Scaffold(
  //     backgroundColor: Theme.of(context).colorScheme.surface,
  //     body: RefreshIndicator(
  //       onRefresh: controller.fetchSubmissions,
  //       child: Builder(
  //         builder: (context) {
  //           if (controller.isLoading) {
  //             return const Center(child: CircularProgressIndicator());
  //           }

  //           if (controller.error != null) {
  //             return Center(
  //               child: Text(
  //                 controller.error!,
  //                 style: TextStyle(
  //                   fontSize: 18.0,
  //                   color: Theme.of(context).colorScheme.error,
  //                 ),
  //               ),
  //             );
  //           }

  //           if (!controller.hasSubmissions) {
  //             return Center(
  //               child: Text(
  //                 "No submitted photos yet!",
  //                 style: TextStyle(
  //                   fontSize: 18.0,
  //                   color: Theme.of(context).colorScheme.onSurface,
  //                 ),
  //               ),
  //             );
  //           }

  //           return SubmissionList(submissions: controller.submissions);
  //         },
  //       ),
  //     ),
  //   );
  // }
}