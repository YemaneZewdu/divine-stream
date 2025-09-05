import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      onViewModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) {
        return Scaffold(
            appBar: AppBar(
              title: Text("Divine Audio Streaming"),
              actions: [
                IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () => viewModel.refreshAllPlaylists()
                ),
              ],
            ),
            body:
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No playlists yet.\nTap + to import from Google Drive.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: viewModel.importFromGoogleDriveFolder,
              child: Icon(Icons.add),
            ));
      },
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    viewModel.initialize();
    super.onViewModelReady(viewModel);
  }
}
